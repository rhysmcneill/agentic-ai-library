---
name: bb-report-writer
description: Writes high-quality bug bounty vulnerability reports for HackerOne, Bugcrowd, and Intigriti. Structures findings with clear impact justification, precise reproduction steps, CVSS scoring, and remediation guidance. Use when asked to "write a bug report", "draft a vulnerability report", "write up this finding", "create a HackerOne report", "format this as a bug bounty report", "help me submit this finding", or "review my report before submission".
---

# Bug Bounty Report Writer

Draft a clear, complete vulnerability report that maximises acceptance rate and fair severity rating.

## Step 1: Gather Finding Details

Ask the user to provide:

1. **Platform** — HackerOne, Bugcrowd, Intigriti
2. **Program name** — for tone and context
3. **Vulnerability class** — e.g., SSRF, public S3 bucket, subdomain takeover, IDOR
4. **Affected asset** — exact URL, bucket name, or subdomain
5. **What was found** — what data or access is exposed
6. **Reproduction steps** — exact steps to trigger the issue
7. **Evidence** — screenshots, HTTP requests/responses, CLI output
8. **Remediation idea** — the fix, if known

If reproduction steps are unclear or incomplete, ask the user to walk through them before drafting. A report that triagers cannot reproduce will be closed.

## Step 2: Determine Severity (CVSS 3.1)

Assign a CVSS 3.1 score based on the actual observed impact. Use these baselines:

| Finding | Baseline CVSS | Label |
|---|---|---|
| SSRF → IMDSv1 credentials | 9.8 | Critical |
| Public S3 + write access | 9.1 | Critical |
| Public S3 + `.tfstate` / credentials | 9.1 | Critical |
| IAM role with `iam:CreateAccessKey` | 9.8 | Critical |
| Exposed Kubernetes dashboard (no auth) | 9.8 | Critical |
| Subdomain takeover | 8.1 | High |
| Exposed Elasticsearch (no auth) | 8.6 | High |
| Public S3 + directory listing | 7.5 | High |
| SSRF (internal access, no IMDS) | 7.2 | High |
| Zone transfer | 7.5 | High |
| Missing DMARC (email spoofing) | 6.5 | Medium |
| Open redirect | 4.3 | Medium |

Adjust the score up if sensitive data (PII, credentials) is confirmed. Adjust down if access requires an unlikely precondition.

## Step 3: Draft the Report

Use this structure for all platforms:

---

### Title

Format: `[VulnType] on [Asset] — [One-line impact statement]`

Examples:
- `SSRF on api.example.com allows retrieval of AWS IAM credentials via IMDSv1`
- `Public S3 bucket exposes Terraform state files containing production database credentials`
- `Subdomain takeover on legacy.example.com via unclaimed S3 static website bucket`

---

### Severity

`[Critical / High / Medium / Low] — CVSS 3.1: [score]`

---

### Summary

2–4 sentences. Lead with impact, not technical description. Answer "what can an attacker do?" before explaining how.

Example:
> The S3 bucket `example-prod-backups` is publicly accessible and returns a directory listing without authentication. The bucket contains Terraform state files that include plaintext database passwords, AWS secret access keys, and private TLS certificates. An unauthenticated attacker can download these files and gain administrative access to the production AWS account and database.

---

### Vulnerability Details

Technical description of the root cause — the misconfiguration or flaw, not just the symptom. Include relevant context (e.g., IMDSv1 vs v2, bucket ACL vs bucket policy, CNAME target).

---

### Steps to Reproduce

Number every step. Be exact — the triage team must reproduce without asking follow-up questions.

```
1. Navigate to https://example-prod-backups.s3.amazonaws.com
2. Observe the XML directory listing response containing 47 files
3. Run: aws s3 ls s3://example-prod-backups --no-sign-request
4. Run: aws s3 cp s3://example-prod-backups/terraform.tfstate /tmp/ --no-sign-request
5. Run: cat /tmp/terraform.tfstate | grep -i password
6. Observe plaintext database credentials on line 847
```

---

### Impact

Structure the impact section in three layers:

1. **Immediate** — what the attacker has right now
2. **Escalation** — what they can do next with that access
3. **Blast radius** — which systems, users, or data are affected

Example:
> 1. **Immediate:** Plaintext credentials for the production PostgreSQL database containing ~500,000 customer records including names, email addresses, and hashed passwords.
> 2. **Escalation:** The AWS secret key in the state file has `iam:CreateAccessKey` permissions, enabling creation of persistent administrative credentials that survive a password reset.
> 3. **Blast radius:** Full access to the production AWS account and all connected services, including the ability to exfiltrate data, modify infrastructure, or destroy resources.

---

### Evidence

Attach or inline:
- Screenshot of the public resource or listing
- Sanitized HTTP request/response (remove your own session tokens)
- CLI output (truncate large outputs to the critical lines)
- For subdomain takeover: screenshot showing the domain resolves to content you control

**Never include real credentials in the report.** Replace with `[REDACTED]` or `[AWS_SECRET_KEY_REDACTED]`.

---

### Remediation

Specific, actionable fix. One paragraph per finding.

Common templates:

**S3 misconfiguration:**
> Enable S3 Block Public Access at both the bucket and AWS account level. Review the bucket ACL and policy to remove any `AllUsers` or `AuthenticatedUsers` grants. Audit all S3 buckets using AWS Trusted Advisor or the S3 console's Public Access report. Rotate all credentials found in the exposed Terraform state files immediately.

**SSRF → IMDS:**
> Enforce IMDSv2 on all EC2 instances by setting `HttpTokens: required` in the instance metadata service configuration. This prevents SSRF-based credential theft as the required PUT pre-flight cannot be proxied through standard SSRF vectors. Additionally, validate all user-supplied URLs against an allowlist of permitted external domains.

**Subdomain takeover:**
> Remove the dangling CNAME record `legacy.example.com` from DNS immediately. Audit all CNAME records in the zone and verify each target resource exists and is under company control. Establish a process to remove DNS records when deprovisioning cloud resources.

---

## Step 4: Pre-Submission Checklist

Review the draft against this checklist before submitting:

- [ ] Title includes vulnerability type, asset, and impact
- [ ] Severity is justified by observed impact, not theoretical maximum
- [ ] Every reproduction step is numbered and precise enough to follow without guidance
- [ ] Impact section answers "so what?" with concrete consequences in three layers
- [ ] No real credentials or PII in the report — all redacted
- [ ] Evidence attached (screenshots, HTTP snippets, CLI output)
- [ ] Remediation is specific — not "fix the misconfiguration"
- [ ] Tone is neutral and professional

## Step 5: Submission Tips

- **One finding per report.** Do not bundle vulnerabilities unless they form a single attack chain with a single fix.
- **Submit conservatively on severity.** Triagers raise severity more readily than they reduce it when challenged.
- **Read disclosed reports** for the same program before submitting — match their format and severity calibration.
- **Message the program first** if scope is ambiguous. A written confirmation protects you if the finding is later disputed.
- **Follow up after 14 days** if no triage response, using platform messaging — not report comments.
- **Do not publicly disclose** until the program grants permission or the standard disclosure window passes (typically 90 days).
