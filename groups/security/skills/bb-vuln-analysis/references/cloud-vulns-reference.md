# Cloud Vulnerability Reference — Exploitation Chains and Escalation Paths

## SSRF → IMDSv1 Full Exploitation Chain

```
SSRF on api.example.com
  → http://169.254.169.254/latest/meta-data/iam/security-credentials/
  → Returns role name: "ec2-prod-role"
  → http://169.254.169.254/latest/meta-data/iam/security-credentials/ec2-prod-role
  → Returns: AccessKeyId, SecretAccessKey, Token
  → aws sts get-caller-identity --profile obtained
  → Enumerate permissions with enumerate-iam
  → If iam:CreateAccessKey → create persistent admin credentials
  → Full account compromise
```

**IMDSv2 bypass attempts (if IMDSv1 blocked):**
- Try adding `X-Forwarded-For: 169.254.169.254` — some proxies honour it
- CRLF injection to inject `X-aws-ec2-metadata-token-ttl-seconds: 21600` header
- DNS rebinding (confirm with program before attempting — often out of scope)

**Report note:** Always confirm IMDSv1 vs IMDSv2 in the report. If IMDSv1 is enabled, this is a misconfiguration on the target's part and strengthens the severity justification.

## Terraform State File (.tfstate) — What to Look For

When a `.tfstate` file is accessible, search for these patterns:

```bash
# Secrets embedded in resource attributes
cat terraform.tfstate | jq '.. | strings | select(test("password|secret|key|token|credential"; "i"))'

# Database connection strings
cat terraform.tfstate | grep -iE "(db_password|database_url|connection_string)"

# AWS access keys
cat terraform.tfstate | grep -iE "AKIA[A-Z0-9]{16}"

# Private keys
cat terraform.tfstate | grep "BEGIN RSA PRIVATE KEY"
```

In reports, show 2-3 sanitized example lines to demonstrate sensitivity without exposing actual credentials.

## IAM Privilege Escalation Paths

Common paths from limited IAM permissions to full account access:

| Starting permission | Escalation path |
|---|---|
| `iam:CreateAccessKey` | Create new access key for any existing user including admins |
| `iam:AttachRolePolicy` | Attach AdministratorAccess policy to your own role |
| `iam:PassRole` + `ec2:RunInstances` | Launch EC2 with high-privilege role attached |
| `iam:PassRole` + `lambda:CreateFunction` | Create Lambda with high-privilege role, invoke it |
| `sts:AssumeRole` | Chain to higher-privilege roles in the account |
| `secretsmanager:GetSecretValue` | Read database passwords, API keys, other credentials |
| `ssm:GetParameter` with `/aws/` path | Read SSM SecureString parameters including RDS passwords |

Tool for automated privilege escalation path finding:
```bash
# Pacu (AWS exploitation framework — authorized testing only)
pacu
> import_keys PROFILE
> run iam__privesc_scan
```

## Subdomain Takeover — Service-Specific Claiming

| Service | How to confirm unclaimed | How to claim PoC |
|---|---|---|
| AWS S3 | `NoSuchBucket` in response | Create S3 bucket with exact name, enable static hosting |
| Azure App Service | `404 Not Found` from azurewebsites.net | Create App Service with the subdomain name |
| GitHub Pages | `There isn't a GitHub Pages site here` | Create GitHub Pages repo matching the CNAME |
| Heroku | `No such app` | Create Heroku app with matching name |
| Fastly | `Fastly error: unknown domain` | Create Fastly service with the domain |

Always upload a harmless `index.html` containing only your HackerOne handle as PoC. Screenshot the result. Delete the resource after the program confirms the report.

## Cloud Storage — Cross-Provider Enumeration

**AWS S3 bucket URL formats:**
```
https://BUCKET.s3.amazonaws.com
https://BUCKET.s3.REGION.amazonaws.com
https://s3.amazonaws.com/BUCKET
https://BUCKET.s3-website-REGION.amazonaws.com  (static hosting)
```

**GCS bucket URL formats:**
```
https://storage.googleapis.com/BUCKET
https://BUCKET.storage.googleapis.com
```

**Azure Blob Storage URL formats:**
```
https://ACCOUNT.blob.core.windows.net/CONTAINER
https://ACCOUNT.blob.core.windows.net/$web  (static site)
```

## DNS Misconfiguration Escalation

**Missing DMARC → email spoofing:**
If `_dmarc.example.com` is missing or set to `p=none`, emails can be spoofed from `@example.com`.
Impact: phishing attacks that appear to come from the target organization.

**Zone transfer success:**
Reveals all hostnames and IPs in the zone. Look for:
- Internal hostnames (`internal.`, `vpn.`, `mgmt.`)
- Staging environments not linked from the main site
- Infrastructure hints (`db.`, `redis.`, `kafka.`)

**Wildcard DNS misconfiguration:**
If `*.example.com` resolves to a real server, any subdomain that isn't specifically defined will hit that server. Combined with virtual host confusion, this can expose internal services or enable subdomain takeover at scale.
