---
name: bb-program-research
description: Evaluates a bug bounty program before committing time to it. Analyses competition level, disclosed reports for calibration and gaps, tech stack, and scope quality. Use when asked to "research this program", "is this program worth targeting", "evaluate this bug bounty", "find gaps in this program", "what has already been found on this program", or "help me choose a program". Run before every new target session.
---

# Bug Bounty Program Research

Evaluate a bug bounty program before spending time on it. Identify gaps, calibrate severity expectations, and plan where to focus.

## Step 1: Gather Program Details

Ask the user for:
1. **Platform** — HackerOne, Bugcrowd, Intigriti
2. **Program name or URL** — direct link to the program page

Fetch the program page and extract:
- In-scope asset list (domains, IP ranges, mobile apps)
- Out-of-scope asset list and excluded vulnerability classes
- Average bounty amounts per severity tier
- Response time statistics (time to triage, time to bounty)
- Program age and total reports resolved
- Whether the program is managed or self-triaged

## Step 2: Assess Program Quality

Score the program on these dimensions before proceeding:

| Dimension | Green (worth pursuing) | Red (avoid or deprioritize) |
|---|---|---|
| Scope width | Wildcard domains (`*.example.com`) | Only 1-2 specific URLs |
| Bounty amounts | Critical ≥ $1,000 | Critical < $500 or reputation-only |
| Response SLA | Triage < 5 days avg | Triage > 14 days avg |
| Resolution rate | > 60% of reports resolved | < 30% resolved |
| Program age | 1–4 years | < 6 months (immature) or > 6 years (exhausted) |
| Triage type | Managed (professional triage team) | Self-triaged (slower, more inconsistent) |

If 3 or more dimensions are red, flag this to the user and recommend considering an alternative program.

## Step 3: Read Disclosed Reports

This is the highest-value research activity. Read 15–25 disclosed reports for the program to understand:

**Severity calibration:**
- What does the program classify as Critical vs High vs Medium?
- Are they consistent with CVSS, or do they downgrade?
- What types of findings do they duplicate-close?

**Gaps and opportunities:**
- Which attack surfaces appear in disclosures? (web, mobile, API, cloud)
- Which surfaces are *absent* from disclosures? — these are your opportunities
- Are cloud infrastructure findings (S3, IAM, SSRF) present? If not, this is likely untested
- What's the most recent disclosure date? Recent reports suggest active testing; old reports suggest the program may be stale

**Patterns to record:**

| Surface | # Reports | Last seen | Status |
|---|---|---|---|
| XSS | 12 | 3 months ago | Well-hunted |
| IDOR | 8 | 1 month ago | Active |
| S3 misconfiguration | 1 | 2 years ago | Opportunity |
| SSRF | 0 | Never | Opportunity |
| Subdomain takeover | 2 | 6 months ago | Monitored |

Use the GitHub MCP `search_issues` tool or WebFetch to pull disclosed reports if available via the platform's public API.

## Step 4: Map the Tech Stack

Identify what technologies the target uses before writing a line of recon. This determines which vulnerability classes are most likely:

**Sources to check:**

```bash
TARGET="example.com"

# Job postings reveal the internal stack
# Search: site:linkedin.com/jobs "example" "AWS" OR "Kubernetes" OR "GCP"
# Search: site:greenhouse.io "example" engineer

# GitHub org — look for infrastructure repos, CI configs, Dockerfiles
# github.com/exampleorg — check all public repos

# Wappalyzer / BuiltWith (passive, no requests)
# Search: builtwith.com/example.com

# HTTP headers from main domain (single request)
curl -sI https://example.com | grep -iE "(server|x-powered-by|x-amz|via|cf-ray)"
```

Tech stack → vulnerability class mapping:

| Technology found | Prioritize |
|---|---|
| AWS (S3, EC2, Lambda) | S3 misconfigs, SSRF→IMDS, IAM issues |
| Kubernetes / EKS | Exposed dashboards, RBAC misconfigs, metadata SSRF |
| Cloudflare | WAF bypass techniques, origin IP discovery |
| GraphQL | Introspection, batching attacks, IDOR via GQL |
| OAuth / SSO | Token leakage, redirect_uri bypass, state fixation |
| Node.js / Express | Prototype pollution, path traversal |
| PHP | File inclusion, deserialization |
| Jenkins / GitHub Actions | Secrets in logs, pipeline injection |

## Step 5: Identify the Lowest-Competition Attack Surface

Combine the disclosed report gaps (Step 3) with the tech stack (Step 4) to find the intersection of "likely vulnerable" and "not yet hunted":

```
Likely vulnerable (from tech stack):  AWS S3, EKS, GitHub Actions
Well-hunted (from disclosures):        XSS, IDOR
Not yet hunted (gap):                  S3 misconfigs, GitHub Actions secrets, SSRF

→ Recommended focus: cloud infrastructure, specifically S3 enumeration and
  SSRF testing on server-side features, then GitHub Actions CI/CD secrets
```

## Step 6: Output a Program Assessment

Produce a structured summary before starting recon:

```
=== Program Assessment: Example Corp (HackerOne) ===

Quality score:    4/5 — worth pursuing
Scope:            *.example.com, *.api.example.com (wide)
Critical bounty:  $5,000
Avg triage time:  3 days (managed)
Program age:      3 years

Tech stack:       AWS (S3, EC2, CloudFront), Node.js, GraphQL API
Cloud provider:   AWS (confirmed from job postings + CF headers)

Disclosed reports reviewed: 22
Well-hunted surfaces:        XSS (11 reports), IDOR (6 reports)
Opportunity surfaces:        Cloud infra (1 old report), GraphQL (0 reports)

Recommended focus order:
  1. Cloud infrastructure — S3 enumeration, SSRF→IMDS (under-tested)
  2. GraphQL API — introspection, BOLA (zero disclosures)
  3. Auth flows — OAuth redirect_uri, JWT issues

Proceed to: bb-recon (cloud-first)
=================================================
```

Pass this assessment to `bb-recon` and `bug-bounty` to anchor the session scope.
