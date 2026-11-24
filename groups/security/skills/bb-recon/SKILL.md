---
name: bb-recon
description: Cloud-first reconnaissance for authorized bug bounty targets. Discovers attack surface through passive OSINT, cloud asset enumeration, DNS fingerprinting, GitHub secret scanning, and active probing. Use when asked to "recon this target", "find attack surface", "enumerate subdomains", "find cloud assets", "check for S3 buckets", "look for exposed storage", or "start reconnaissance on". Prioritizes AWS, GCP, and Azure infrastructure findings before general web vulnerabilities.
---

# Bug Bounty Reconnaissance

Systematically discover the attack surface of an authorized bug bounty target, cloud infrastructure first.

## Prerequisite

Confirm authorization context is established (via the `bug-bounty` skill or explicit user statement). Never begin active probing without a confirmed in-scope target.

## Phase 1: Passive Recon (No Target Requests)

Complete all passive steps before sending any requests to the target.

### 1.1 Subdomain Discovery

```bash
TARGET="example.com"

# Certificate transparency logs (no requests to target)
curl -s "https://crt.sh/?q=%.$TARGET&output=json" | \
  jq -r '.[].name_value' | sed 's/\*\.//g' | sort -u > subdomains-ct.txt

# Multi-source passive enumeration
subfinder -d $TARGET -silent > subdomains-sf.txt

# Merge and deduplicate
cat subdomains-ct.txt subdomains-sf.txt | sort -u > subdomains.txt
echo "Total subdomains: $(wc -l < subdomains.txt)"
```

### 1.2 GitHub OSINT

Search the target org's public repos for secrets and infrastructure hints. Use the GitHub MCP tool (`search_code`) or the CLI:

| Search query | What it reveals |
|---|---|
| `org:TARGET "AWS_ACCESS_KEY"` | Leaked AWS credentials |
| `org:TARGET "s3.amazonaws.com"` | S3 bucket references |
| `org:TARGET ".tfstate"` | Terraform state file references |
| `org:TARGET "terraform.tfvars"` | Terraform variable files |
| `org:TARGET "BEGIN RSA PRIVATE KEY"` | Leaked private keys |
| `org:TARGET "amazonaws.com" filename:.env` | Env files with AWS config |

Run verified secret scanning on cloned repos:
```bash
trufflehog github --org=targetorg --only-verified
```

### 1.3 Cloud Provider Identification

Determine which cloud provider(s) the target uses before active testing:

```bash
# Check CNAME chains — reveals cloud services in use
while read sub; do
  cname=$(dig CNAME +short $sub 2>/dev/null)
  [ -n "$cname" ] && echo "$sub -> $cname"
done < subdomains.txt | tee cname-chains.txt
```

Cloud provider CNAME fingerprints:

| CNAME pattern | Provider | Service |
|---|---|---|
| `*.amazonaws.com` | AWS | General |
| `*.cloudfront.net` | AWS | CDN |
| `*.elb.amazonaws.com` | AWS | Load Balancer |
| `*.s3-website*.amazonaws.com` | AWS | S3 Static Site |
| `*.azurewebsites.net` | Azure | App Service |
| `*.azurefd.net` | Azure | Front Door |
| `*.cloudapp.azure.com` | Azure | VM |
| `*.appspot.com` | GCP | App Engine |
| `*.run.app` | GCP | Cloud Run |
| `*.cloudfunctions.net` | GCP | Cloud Functions |

Also check HTTP response headers of live hosts — AWS adds `X-Amz-*` headers, GCP adds `X-GUploader-*`, Azure adds `x-ms-request-id`.

### 1.4 Cloud Storage Enumeration

Enumerate cloud storage buckets using common naming patterns. This is the highest-ROI passive activity for cloud-focused researchers:

```bash
TARGET_NAME="targetcompany"  # Core brand name without TLD

# cloud_enum checks AWS S3, GCS, and Azure Blobs simultaneously
cloud_enum -k $TARGET_NAME \
           -k "${TARGET_NAME}-dev" \
           -k "${TARGET_NAME}-staging" \
           -k "${TARGET_NAME}-prod" \
           -k "${TARGET_NAME}-backup" \
           -k "${TARGET_NAME}-assets" \
           -k "${TARGET_NAME}-data" \
           -k "${TARGET_NAME}-logs"
```

If a bucket is publicly accessible, search immediately for high-value files:
```bash
aws s3 ls s3://BUCKET --recursive --no-sign-request | \
  grep -iE "\.(tfstate|env|json|yaml|sql|dump|bak|key|pem|tar\.gz|zip)$"
```

Severity of storage findings:

| Finding | Severity |
|---|---|
| Public bucket + write access | Critical |
| Public bucket + `.tfstate` or secrets | Critical |
| Public bucket + PII or customer data | Critical |
| Public bucket + directory listing | High |
| Public bucket + only intended public assets | Informational |

### 1.5 Shodan / Censys for Exposed Services

```bash
# Shodan CLI (requires API key)
shodan search 'org:"Target Company" http.title:"Kubernetes Dashboard"'
shodan search 'org:"Target Company" product:"Elasticsearch"'
shodan search 'org:"Target Company" http.title:"Grafana"'
shodan search 'org:"Target Company" http.title:"Jenkins"'
shodan search 'org:"Target Company" port:8888'  # Jupyter Notebook
```

Unauthenticated management interfaces and their severity:

| Service | Port | Severity if Unauthenticated |
|---|---|---|
| Kubernetes Dashboard | 8001, 8443 | Critical |
| Docker API | 2375 | Critical |
| etcd | 2379 | Critical |
| Elasticsearch | 9200 | High |
| Kibana | 5601 | High |
| Jenkins | 8080 | High |
| Jupyter Notebook | 8888 | High |
| Grafana | 3000 | Medium-High |
| Prometheus | 9090 | Medium |

## Phase 2: Active Probing (In-Scope Assets Only)

### 2.1 HTTP Fingerprinting and Screenshot

```bash
# Resolve, probe, detect tech stack, and capture CNAME
cat subdomains.txt | \
  httpx -silent -status-code -title -tech-detect -cname \
  -o live-hosts.txt

# Screenshot everything for manual triage
cat live-hosts.txt | awk '{print $1}' | aquatone -out ./screenshots
```

### 2.2 Subdomain Takeover Detection

A dangling CNAME pointing to a deprovisioned cloud resource is claimable:

```bash
nuclei -l subdomains.txt -t takeovers/ -silent -o takeover-findings.txt
```

Common takeover-vulnerable services: S3 static websites, Azure App Service, Heroku, GitHub Pages, Fastly, Zendesk. Confirm manually before reporting.

### 2.3 Endpoint Discovery

```bash
# Historical URL discovery (no active scanning)
gau $TARGET | sort -u > historical-urls.txt

# Extract API endpoints from JavaScript files
cat historical-urls.txt | grep "\.js$" | \
  xargs -I{} curl -s {} | \
  grep -oP '(\/api\/[^"'\'']+|\/v[0-9]+\/[^"'\'']+)' | \
  sort -u > api-endpoints.txt

# Fuzzing (rate-limited — respect program rules)
ffuf -u https://$TARGET/FUZZ \
  -w ~/tools/SecLists/Discovery/Web-Content/api-endpoints.txt \
  -mc 200,201,204,301,302,401,403 \
  -rate 30 \
  -o ffuf-results.json
```

## Phase 3: Recon Summary

After completing reconnaissance, produce a structured summary to guide the next phase:

```
=== Recon Summary: example.com ===
Cloud provider:   AWS (confirmed via CNAME chains)
Subdomains found: 47  |  Live HTTP hosts: 23

CNAME highlights:
  assets.example.com  → example-assets.s3-website-us-east-1.amazonaws.com
  legacy.example.com  → unclaimed-bucket.s3.amazonaws.com  ← TAKEOVER CANDIDATE

Storage buckets:
  example-assets (S3)      — PUBLIC, listing enabled  ← INVESTIGATE
  example-dev-data (S3)    — 403 Forbidden
  exampleco-backup (S3)    — 404 (bucket may be claimable)

GitHub OSINT:
  2 repos reference s3://example-data
  No verified secrets found by trufflehog

High-priority targets for analysis:
  1. example-assets S3 (public listing confirmed)
  2. legacy.example.com (potential subdomain takeover)
  3. admin.example.com (403 — test for auth bypass)
  4. api.example.com has ?url= param — test for SSRF
===================================
```

Pass this summary to `bb-vuln-analysis` to begin investigating each priority target.

Read `references/cloud-recon-tools.md` for tool installation, wordlists, and API key setup.
