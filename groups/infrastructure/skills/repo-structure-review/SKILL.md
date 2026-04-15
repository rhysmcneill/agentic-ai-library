---
name: repo-structure-review
description: Analyzes infrastructure repository structure and recommends improvements based on best practices for Terraform modules, stack separation, Helm chart monorepos, and ArgoCD app-of-apps patterns. Use when asked to "review repo structure", "audit this repo", "suggest improvements", "refactor this repo", "restructure the repo", "assess repo layout", or "how should I organize this repo". Produces actionable findings with severity and concrete remediation steps.
---

# Review Infrastructure Repository Structure

Analyze one or more infrastructure repositories, identify structural anti-patterns, and produce a prioritized findings report with concrete remediation steps.

## Overview

The review follows this flow:

1. Scan the repo to detect which infrastructure domains are present
2. Load the relevant best-practice reference for each detected domain
3. Check the repo structure against each checklist
4. Produce a structured findings report

## Step 1: Clarify Scope

Ask the user:

1. Which repo(s) should be reviewed? (paths or URLs)
2. What is the goal? Pick one:

| Goal | Focus |
|------|-------|
| **New repo** | Recommend an ideal structure from scratch |
| **Refactor** | Identify anti-patterns and propose a migration path |
| **Update** | Review recent changes against best practices |

3. Are there any constraints? (e.g., "we must keep a single repo", "we use Terramate", "no Helm operator")

## Step 2: Detect Infrastructure Domains

Scan the repository root and up to three levels deep. Classify files into domains:

| Indicator | Domain |
|-----------|--------|
| `*.tf`, `*.tf.json`, `terramate.tm.hcl`, `.terraform/` | Terraform |
| `Chart.yaml`, `values.yaml`, `templates/` | Helm |
| `Application` or `ApplicationSet` kind in YAML, `argocd/` directory | ArgoCD |
| `Dockerfile`, `docker-compose.yml` | Container |
| `Makefile`, `Taskfile.yml`, `justfile` | Build tooling |

Run these commands to build a quick inventory:

```bash
# Directory tree (depth 3, directories only)
find . -maxdepth 3 -type d | head -80

# File type counts
find . -type f -name '*.tf' | wc -l
find . -type f -name 'Chart.yaml' | wc -l
find . -type f \( -name '*.yaml' -o -name '*.yml' \) | head -40
```

Record the detected domains. If none are found, inform the user and stop.

## Step 3: Load Domain References

Load **only** the references for detected domains:

| Domain | Reference |
|--------|-----------|
| Terraform | Read `references/terraform-patterns.md` |
| Helm | Read `references/helm-patterns.md` |
| ArgoCD | Read `references/argocd-patterns.md` |

Do **not** load references for domains that are absent from the repo.

## Step 4: Analyze Structure

For each detected domain, walk through the checklist in the corresponding reference file. For every checklist item:

1. Inspect the relevant files and directories.
2. Determine whether the repo follows, partially follows, or violates the practice.
3. Record a finding if the practice is violated or partially followed.

### Finding format

Record each finding with these fields:

| Field | Description |
|-------|-------------|
| **ID** | Sequential number (F-001, F-002, ...) |
| **Severity** | `critical`, `high`, `medium`, `low` |
| **Domain** | Terraform, Helm, ArgoCD, or General |
| **Title** | One-line summary |
| **Current state** | What the repo does today (with file paths) |
| **Recommendation** | What to change and why |
| **Example** | Concrete directory layout or code snippet showing the fix |

### Severity definitions

| Severity | Criteria |
|----------|----------|
| **Critical** | Security risk, state corruption risk, or blocks CI/CD |
| **High** | Causes significant maintenance burden or drift risk |
| **Medium** | Deviates from best practice but works; will cause pain at scale |
| **Low** | Style or convention improvement |

## Step 5: Produce the Report

Present findings to the user in this format:

```markdown
# Infrastructure Repo Structure Review

**Repo:** <repo name or path>
**Goal:** <new / refactor / update>
**Domains detected:** <list>
**Date:** <today>

## Summary

| Severity | Count |
|----------|-------|
| Critical | N |
| High     | N |
| Medium   | N |
| Low      | N |

## Findings

### F-001: <Title> [<severity>]

**Domain:** <domain>

**Current state:**
<What the repo does today, with specific file paths.>

**Recommendation:**
<What to change and why, in concrete terms.>

**Example:**
<Directory tree, code snippet, or config showing the target state.>

---

(repeat for each finding)

## Recommended Target Structure

<Proposed directory tree for the repo after all findings are addressed.
 Only include this section if the goal is "new repo" or "refactor".>
```

### Report rules

- Sort findings by severity (critical first).
- Every recommendation must include a concrete example — never say "restructure this" without showing the target layout.
- If the goal is "new repo", skip the "Current state" field and focus on the recommended structure.
- If multiple repos are being reviewed, produce one report per repo.
- Keep the report actionable. Do not include findings the user explicitly constrained away (e.g., if they said "single repo is required", do not recommend splitting into multiple repos).
