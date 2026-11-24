---
name: bb-secrets-hunting
description: Hunts for leaked credentials and secrets across public sources for authorized bug bounty targets. Covers GitHub commits and forks, npm and PyPI packages, Docker Hub images, CI/CD artifact leaks, and public paste sites. Validates found credentials before reporting. Use when asked to "hunt for secrets", "find leaked credentials", "scan for API keys", "check for exposed secrets", "look for leaked keys on GitHub", or "find credentials for this target".
---

# Bug Bounty Secrets Hunting

Systematically search public sources for leaked credentials and secrets belonging to an authorized bug bounty target.

## Prerequisite

Confirm the target organization is within an authorized bug bounty program scope. Secrets hunting is passive OSINT — no requests to the target's systems are required until credential validation.

## Step 1: GitHub Deep Scan

GitHub is the highest-yield source. Go beyond the org's current repos.

### 1.1 Current Repo Scan

```bash
ORG="targetorg"

# Verified secrets only (reduces noise significantly)
trufflehog github --org=$ORG --only-verified

# Also scan with gitleaks for pattern-based detection
gh api /orgs/$ORG/repos --paginate | \
  jq -r '.[].clone_url' | \
  xargs -I{} bash -c 'git clone --depth=1 {} /tmp/repo && gitleaks detect --source=/tmp/repo -q && rm -rf /tmp/repo'
```

### 1.2 Git History and Deleted Commits

Secrets are often added then deleted — the commit history still contains them:

```bash
# Clone a specific repo and scan full history
git clone https://github.com/$ORG/target-repo /tmp/target-repo
cd /tmp/target-repo
trufflehog git file:///tmp/target-repo --since-commit HEAD~500

# Also check all branches
git branch -r | xargs -I{} git log {} --all --full-history -- "*.env" "*.tfvars" "config.*"
```

### 1.3 GitHub Code Search

Use the GitHub MCP `search_code` tool or the search UI:

| Query | Finds |
|---|---|
| `org:TARGET "AWS_ACCESS_KEY_ID"` | AWS credentials |
| `org:TARGET "AKIA" OR "ASIA"` | AWS key prefixes |
| `org:TARGET "BEGIN RSA PRIVATE KEY"` | Private keys |
| `org:TARGET "s3.amazonaws.com" password` | S3 URLs with passwords |
| `org:TARGET filename:.env` | Environment files |
| `org:TARGET filename:terraform.tfvars` | Terraform variable files |
| `org:TARGET "database_url" password` | DB connection strings |
| `org:TARGET "api_key" OR "apikey" OR "api-key"` | Generic API keys |
| `org:TARGET "secret_key" OR "secretkey"` | Secret keys |
| `org:TARGET "-----BEGIN"` | Any PEM-format key |

### 1.4 Forks and Gists

```bash
# Search gists by the org's known employee emails or usernames
# Manual: github.com/search?q=targetcompany&type=gists

# Check forks of the org's repos — contributors sometimes commit secrets
gh api /repos/$ORG/TARGET-REPO/forks --paginate | \
  jq -r '.[].full_name' | head -20
# Then scan interesting forks with trufflehog
```

## Step 2: npm and PyPI Package Scanning

Published packages sometimes contain hardcoded credentials or ship `.env` files accidentally:

```bash
# Find packages published by the org
# npm: npmjs.com/~targetorg or search by email domain
npm search targetcompany --searchlimit=20

# Download and scan a package
npm pack targetcompany-sdk
tar -xzf *.tgz
trufflehog filesystem ./package/ --only-verified

# PyPI
pip download targetcompany-sdk --no-deps -d /tmp/pypi-pkg
cd /tmp/pypi-pkg && unzip *.whl -d extracted
trufflehog filesystem ./extracted/ --only-verified
```

## Step 3: Docker Hub Image Analysis

Docker images can contain baked-in credentials, config files, and environment variables:

```bash
# Find images published by the org
# hub.docker.com/u/targetorg

# Pull and inspect layers
docker pull targetorg/app:latest
docker history targetorg/app:latest --no-trunc | grep -iE "(ENV|ARG|password|key|secret)"

# Extract filesystem for deep scan
docker save targetorg/app:latest | tar -xO | \
  tar -xf - --wildcards "*.env" "*.json" "*.yaml" "*.yml" 2>/dev/null

# Use dive for layer-by-layer analysis
dive targetorg/app:latest
```

Look for:
- `ENV` instructions with credentials in the Dockerfile layer history
- Config files baked into the image (`/app/config.yaml`, `/etc/app.conf`)
- `.git` directories accidentally included in the image

## Step 4: CI/CD Artifact Leaks

### 4.1 GitHub Actions Logs

Public repositories expose workflow run logs. Search for accidental secret printing:

```bash
# List recent workflow runs
gh api /repos/$ORG/TARGET-REPO/actions/runs --paginate | \
  jq -r '.workflow_runs[] | "\(.id) \(.name)"' | head -20

# Download and search a specific run log
gh api /repos/$ORG/TARGET-REPO/actions/runs/RUN_ID/logs > run.zip
unzip run.zip -d logs/
grep -riE "(AKIA|password|secret|token|key)" logs/
```

### 4.2 GitHub Actions — Misconfigured Secret Exposure

Check for workflows that echo or print secrets:

```bash
# Search workflow files for dangerous patterns
gh api /repos/$ORG/TARGET-REPO/contents/.github/workflows | \
  jq -r '.[].download_url' | xargs -I{} curl -s {} | \
  grep -iE "(echo \$\{|print.*secret|run:.*\$\{\{.*secrets)"
```

### 4.3 CircleCI / Travis Artifacts

If the target uses other CI platforms, check for public artifact storage:
- CircleCI: `app.circleci.com/pipelines/github/ORG`
- Travis: `travis-ci.com/ORG`

## Step 5: Public Paste and Leak Sites

```bash
# Search Pastebin (via Google)
# site:pastebin.com "targetcompany" "password"
# site:pastebin.com "targetcompany" "AWS"
# site:pastebin.com "@targetcompany.com"

# Search GitHub Gist (via Google)
# site:gist.github.com "targetcompany.com" "key"
```

Also check: `pastie.org`, `hastebin.com`, `dpaste.com`.

## Step 6: Validate Found Credentials

Before reporting, validate that credentials are active. Use read-only API calls — never make changes:

**AWS credentials:**
```bash
AWS_ACCESS_KEY_ID=AKIA... AWS_SECRET_ACCESS_KEY=... \
  aws sts get-caller-identity 2>&1

# Valid response → credentials are active → Critical finding
# "InvalidClientTokenId" → credentials are invalid/expired
# "ExpiredToken" → session token expired (note in report: was valid)
```

**Generic API keys — validation pattern:**
Find the service from the key format, then call its identity endpoint (e.g., `GET /api/me`, `GET /v1/user`) with the key. A 200 response confirms validity.

**Do not:**
- Make any write, modify, or delete calls
- Access production data beyond what's needed to confirm the credential is valid
- Store real credentials anywhere — redact immediately after validation

## Step 7: Assess and Report

Severity of secrets findings:

| Finding | Severity |
|---|---|
| Active AWS key with IAM/admin permissions | Critical |
| Active AWS key with limited permissions | High |
| Active API key with write access | High |
| Active API key with read access to sensitive data | High |
| Database connection string (active) | Critical |
| Private key (active TLS cert or SSH) | High |
| Expired or invalid credentials | Informational (still worth noting) |
| Hardcoded password in source (no service confirmed) | Medium |

When reporting: include the source URL (GitHub commit, npm package version, Docker tag), the credential type, the validation result, and the specific commit or layer where it was found. Never include the actual credential value — use `[REDACTED]`.

Invoke `bb-report-writer` once a secret is confirmed active and severity assessed.

Read `references/secrets-validation.md` for credential format patterns and service-specific validation endpoints.
