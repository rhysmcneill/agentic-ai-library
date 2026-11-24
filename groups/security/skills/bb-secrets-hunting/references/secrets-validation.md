# Secrets Validation Reference

## AWS Credential Formats

| Format | Type | Notes |
|---|---|---|
| `AKIA[A-Z0-9]{16}` | Long-term access key | Permanent until deleted |
| `ASIA[A-Z0-9]{16}` | Temporary (STS) key | Requires session token, expires |
| `AROA[A-Z0-9]{16}` | Role ID prefix | Not a credential — identifies a role |

Validate AWS keys with the minimum-permission call:
```bash
aws sts get-caller-identity \
  --access-key-id AKIA... \
  --secret-access-key SECRET...
```

If valid, immediately check permissions:
```bash
# Quick high-value permission checks
aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query Arn --output text | cut -d/ -f2)
aws s3 ls  # Check S3 access
aws secretsmanager list-secrets  # Check secrets access
```

## Common API Key Formats and Validation

| Service | Key format | Validation endpoint |
|---|---|---|
| Stripe | `sk_live_[a-zA-Z0-9]{24}` | `GET https://api.stripe.com/v1/account` |
| Twilio | `SK[a-z0-9]{32}` | `GET https://api.twilio.com/2010-04-01/Accounts` |
| SendGrid | `SG.[a-zA-Z0-9._-]{22}.[a-zA-Z0-9._-]{43}` | `GET https://api.sendgrid.com/v3/user/profile` |
| GitHub | `ghp_[a-zA-Z0-9]{36}` | `GET https://api.github.com/user` |
| Slack | `xoxb-[0-9]+-[a-zA-Z0-9]+` | `GET https://slack.com/api/auth.test` |
| Shopify | `shpat_[a-fA-F0-9]{32}` | `GET https://SHOP.myshopify.com/admin/api/2023-01/shop.json` |
| HubSpot | `pat-[a-z]{2}-[a-f0-9-]{36}` | `GET https://api.hubapi.com/crm/v3/objects/contacts` |

Always use `Authorization: Bearer TOKEN` or `Authorization: Token TOKEN` headers. Check the service docs for exact header format.

## Private Key Identification

```
-----BEGIN RSA PRIVATE KEY-----     # RSA (PKCS#1) — TLS, SSH
-----BEGIN EC PRIVATE KEY-----      # ECDSA — TLS, JWT signing
-----BEGIN OPENSSH PRIVATE KEY-----  # SSH private key (modern format)
-----BEGIN PRIVATE KEY-----         # PKCS#8 generic
-----BEGIN PGP PRIVATE KEY BLOCK--- # PGP/GPG key
```

For SSH keys: attempt `ssh -T git@github.com -i /tmp/key` to check if the key is registered on GitHub. For TLS keys: match against the target's TLS certificate CN.

## Database Connection String Formats

```
# PostgreSQL
postgresql://user:password@host:5432/dbname
postgres://user:password@host/dbname

# MySQL
mysql://user:password@host:3306/dbname

# MongoDB
mongodb://user:password@host:27017/dbname
mongodb+srv://user:password@cluster.mongodb.net/dbname

# Redis (with auth)
redis://:password@host:6379

# Elasticsearch
https://user:password@es-host:9200
```

Never attempt to connect to production databases — confirming the connection string format and host resolution is sufficient to demonstrate validity.

## trufflehog Output Interpretation

```json
{
  "SourceMetadata": {
    "Data": {
      "Github": {
        "repository": "https://github.com/targetorg/repo",
        "commit": "abc123",
        "file": "config/production.yaml",
        "line": 47
      }
    }
  },
  "SourceName": "trufflehog",
  "DetectorName": "AWS",
  "Verified": true,          ← Credential is ACTIVE — report immediately
  "Raw": "AKIAIOSFODNN7EXAMPLE"
}
```

`"Verified": true` means trufflehog confirmed the credential is active via a live API call. Always report verified findings — these are confirmed Critical/High.

`"Verified": false` means the pattern matched but liveness wasn't confirmed. Manually validate before reporting.

## Report Format for Secrets Findings

Include in the report:
1. **Source:** `https://github.com/targetorg/repo/blob/abc123/config/production.yaml#L47`
2. **Credential type:** AWS IAM Access Key
3. **Key prefix only:** `AKIA...XXXX` (last 4 chars, rest redacted)
4. **Validation result:** "Confirmed active via `aws sts get-caller-identity` — returned account ID `123456789012`, IAM user `deploy-prod`"
5. **Permissions found:** List key permissions without exercising destructive ones
6. **Recommended action:** Revoke the key immediately, rotate all secrets in the affected repository, audit CloudTrail for unauthorized use since the commit date
