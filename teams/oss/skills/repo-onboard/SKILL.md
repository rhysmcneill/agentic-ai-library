---
name: repo-onboard
description: Onboards onto a new open-source repository by reading its documentation, understanding its structure, and summarising how to contribute. Use when asked to "understand this repo", "onboard onto a project", "how do I contribute to this repo", "read the contribution guidelines", or "explore this codebase".
---

# Onboard onto an Open-Source Repository

Systematically explore a new repository to build a complete picture of its purpose, structure, conventions, and contribution workflow.

## Tools

Prefer the GitHub MCP server tools when available. Fall back to the `gh` CLI or local file reads when MCP is not configured.

| Action | MCP tool | CLI fallback |
|--------|----------|--------------|
| Read repo files | `get_file_contents` | `gh api` or clone + read |
| Search code | `search_code` | `gh search code` |
| List issues | `list_issues`, `search_issues` | `gh issue list` |
| List PRs | `list_pull_requests` | `gh pr list` |

## Step 1: Locate Core Documentation

Use `get_file_contents` (MCP) to read each file directly from the repository without cloning. Search the repository root and common locations for these files (not all will exist):

| File | Purpose |
|------|---------|
| `README.md` | Project purpose, quick start, architecture overview |
| `CONTRIBUTING.md` | Contribution workflow, branch strategy, PR process |
| `CODE_OF_CONDUCT.md` | Community behaviour expectations |
| `LICENSE` / `COPYING` | License type and obligations |
| `SECURITY.md` | Vulnerability reporting process |
| `CHANGELOG.md` / `RELEASES.md` | Release cadence and versioning style |
| `.github/ISSUE_TEMPLATE/` | Issue templates and required fields |
| `.github/PULL_REQUEST_TEMPLATE.md` | PR template and checklist |

Read every file found. If `CONTRIBUTING.md` does not exist, look for contribution instructions inside `README.md`.

## Step 2: Identify the Tech Stack

Determine the languages, frameworks, and build tools from dependency and config files:

| Indicator | What it reveals |
|-----------|-----------------|
| `package.json` | Node.js / JavaScript / TypeScript ecosystem |
| `go.mod` | Go module, dependencies, minimum Go version |
| `Cargo.toml` | Rust crate and edition |
| `pyproject.toml` / `requirements.txt` | Python ecosystem |
| `Makefile` / `Taskfile.yml` / `justfile` | Build and task automation |
| `Dockerfile` / `docker-compose.yml` | Container workflow |
| CI config (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`) | CI/CD pipeline, required checks |

Note the test framework, linter, and formatter in use (e.g., `eslint`, `golangci-lint`, `ruff`, `clippy`).

## Step 3: Map the Project Structure

Produce a high-level directory tree (top two levels). Identify:

1. **Source code root** — where the main application code lives
2. **Test locations** — co-located or separate test directories
3. **Documentation** — `docs/`, wiki references, or inline
4. **Configuration** — environment files, CI, linter configs
5. **Generated code** — directories that should not be manually edited

## Step 4: Understand the Contribution Workflow

Extract and summarise:

1. **Branch strategy** — trunk-based, gitflow, fork-and-PR, etc.
2. **Commit conventions** — conventional commits, signed commits, DCO sign-off
3. **PR requirements** — required reviewers, CI checks that must pass, squash policy
4. **Issue workflow** — how issues are triaged, labelled, and assigned
5. **Release process** — who releases, how versions are bumped, changelog expectations

If the project uses a fork-and-PR model, note any specific instructions about keeping forks up to date.

## Step 5: Produce the Onboarding Summary

Present a structured summary to the user with these sections:

```
## Project Overview
<One paragraph: what the project does and who it's for>

## Tech Stack
<Languages, frameworks, build tools, CI>

## Project Structure
<Abbreviated directory tree with annotations>

## How to Contribute
<Step-by-step based on CONTRIBUTING.md or README>

## Key Conventions
<Commit style, branch naming, code style, test expectations>

## Gotchas
<Anything unusual: CLA requirements, DCO sign-off, mono-repo quirks, etc.>
```

If any section could not be determined from the available documentation, say so explicitly and suggest the user ask the maintainers.
