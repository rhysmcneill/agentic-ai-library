# Agentic AI Skills Library

A centralized library of **shared** and **group-based** AI agent rules and skills for Claude Code, Cursor, Antigravity, Codex, Copilot, and other AGENTS.md-aware tools. Skills and rules live here once and reach every repo that links to this library — no copy-pasting.

## Installing skills

There are two ways to get a skill from this library, depending on what you need:

### A. Install one skill as a Claude Code plugin

For picking up a single public skill with no setup, no clone, no fork:

```
/plugin marketplace add rhysmcneill/agentic-ai-library
/plugin install eks-upgrade-prep        # or /plugin install eks-upgrade-execute
```

Only skills listed in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) are installable this way — see [Publishing a skill as a plugin](CONTRIBUTING.md#publishing-a-skill-as-a-plugin) to add one. This is Claude Code only; other tools need Option B.

### B. Link the whole library into a repo

For your own fork, your team's shared rules, multiple groups, or non-Claude tools (Cursor, Codex, Antigravity, Copilot, Windsurf):

```bash
git clone <your-fork-url>
scripts/setup.sh --target ../my-repo --group infrastructure
```

This symlinks the global layer plus your chosen group(s) into `.agents/` in the target repo — **locally only**, gitignored automatically, nothing committed there. Tools that read `AGENTS.md` natively (Codex, Antigravity, Copilot) work immediately; others need `--ide`:

```bash
scripts/setup.sh --target ../my-repo --group infrastructure --ide claude --ide cursor
```

| Flag | Tool | Why it's needed |
|---|---|---|
| *(none)* | Codex, Antigravity, Copilot | Read `AGENTS.md` natively |
| `--ide claude` | Claude Code CLI | Needs skills explicit-imported in `CLAUDE.md` + `.claude/skills/` symlinks |
| `--ide cursor` | Cursor | Discovers skills from `.cursor/skills/`, not `.agents/skills/` |
| `--ide windsurf` | Windsurf | Reads `.windsurfrules`, not `AGENTS.md` |

Repos spanning multiple domains can opt into several groups at once:

```bash
scripts/setup.sh --target ../my-monorepo --group backend --group infrastructure --group release
```

You never need to re-run `setup.sh` after the first time — updates pulled into this library propagate automatically through the symlinks. JetBrains (Junie) is configured manually: **Settings → Junie → Project Settings → Guidelines path** → point at the target repo's `AGENTS.md`.

## Forking this library for your own org

This repo is meant to be forked. The included groups (`backend`, `infrastructure`, `open-source-contrib`, `release`) are working examples — replace them with your own:

```bash
git clone <your-fork-url> && cd agentic-ai-library
# Edit global/AGENTS.md with your baseline rules
rm -rf groups/backend groups/infrastructure groups/open-source-contrib groups/release
mkdir -p groups/my-team/skills && cp global/AGENTS.group-template.md groups/my-team/AGENTS.md
# Edit groups/my-team/AGENTS.md, then list it under "Available groups" in global/AGENTS.md
git config core.hooksPath .githooks
git add . && git commit -m "feat: customize for our org" && git push
```

To pull in upstream improvements later: `git remote add upstream <original-repo-url>`, then `git fetch upstream && git merge upstream/main`, resolving conflicts in `global/AGENTS.md`/`groups/` as needed.

## How it works

**Two layers**, loaded lowest-to-highest precedence:

| Layer | Scope | Contains |
|---|---|---|
| **Global** (`global/`) | Every repo | Baseline rules + universal skills (`skill-creator`) |
| **Group** (`groups/<name>/`) | Repos that opt in via `--group` | Domain-specific rules and skills |

Full override precedence, nearest wins: `AGENTS.local.md` (personal) → repo root `AGENTS.md` → `groups/<group>/AGENTS.md` → `global/AGENTS.md`. Override a specific rule with `<!-- override: RULE-ID -->` above its replacement.

A **group** is just any shared domain of expertise — `backend`/`infrastructure`/`release` for a company, `core`/`plugins` for an OSS project, `cs101`/`research` for a university department. Repo-specific rules that don't belong in any group go in that repo's own root `AGENTS.md` instead.

## Repository structure

```
agentic-ai-library/
├── global/                   # Applied to every repo
│   ├── AGENTS.md             # Baseline rules
│   └── skills/skill-creator/ # Skill for creating new skills
├── groups/
│   ├── backend/{AGENTS.md,skills/}
│   ├── infrastructure/{AGENTS.md,skills/}       # e.g. eks-upgrade-prep, eks-upgrade-execute, terraform-expert
│   ├── open-source-contrib/{AGENTS.md,skills/}
│   ├── release/AGENTS.md
│   └── security/{AGENTS.md,skills/}             # e.g. bug-bounty, bb-recon, bb-vuln-analysis
├── _generated/                # Committed, pre-built indexes — never hand-edit
├── .claude-plugin/
│   └── marketplace.json       # Lists skills installable via /plugin install
├── .githooks/pre-commit       # Regenerates _generated/ on every commit
└── scripts/
    ├── setup.sh               # Symlink this library into a target repo
    └── generate-indexes.sh    # Rebuild _generated/ manually
```

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for adding a skill, adding a group, modifying rules, and publishing a skill as a plugin.

## Available Skills

| Skill | Group | Description |
|---|---|---|
| [`commit`](groups/infrastructure/skills/commit/SKILL.md) | `infrastructure` | Analyzes changes and creates git commits following Conventional Commits 1.0.0 with Jira references and AI attribution. |
| [`create-issue`](groups/open-source-contrib/skills/create-issue/SKILL.md) | `open-source-contrib` | Creates well-structured issues in OSS repositories following the project's templates and guidelines. |
| [`create-pr`](groups/infrastructure/skills/create-pr/SKILL.md) | `infrastructure` | Creates pull requests for infrastructure repos with Terramate, Helm, Terraform, and ArgoCD validation. |
| [`create-pr`](groups/open-source-contrib/skills/create-pr/SKILL.md) | `open-source-contrib` | Submits pull requests to OSS repositories following contribution guidelines, PR templates, and CI requirements. |
| [`dev-env-setup`](groups/open-source-contrib/skills/dev-env-setup/SKILL.md) | `open-source-contrib` | Sets up development environments for OSS repositories. |
| [`eks-upgrade-execute`](groups/infrastructure/skills/eks-upgrade-execute/SKILL.md) | `infrastructure` | Executes an already-prepared EKS upgrade through IaC/CI: fresh backup, control-plane version bump PR, compute-type-aware node upgrade (managed node groups / Karpenter / Fargate) with health gates, then an addon version bump PR. A human approves every merge and every node-disruptive step; requires a go/no-go report from `eks-upgrade-prep` first. Also installable directly as a plugin — see [Installing skills](#a-install-one-skill-as-a-claude-code-plugin). |
| [`eks-upgrade-prep`](groups/infrastructure/skills/eks-upgrade-prep/SKILL.md) | `infrastructure` | Read-only readiness audit before an EKS version upgrade: deprecated API usage, PDB/drain blockers, EKS Upgrade Insights, and compatibility research for every addon and in-cluster controller against the target Kubernetes version. Produces a severity-rated, go/no-go report. Also installable directly as a plugin — see [Installing skills](#a-install-one-skill-as-a-claude-code-plugin). |
| [`golang-api`](groups/backend/skills/golang-api/SKILL.md) | `backend` | Enforces Go API best practices for project structure, handlers, error handling, middleware, and testing. |
| [`golang-expert`](groups/backend/skills/golang-expert/SKILL.md) | `backend` | Idiomatic Go best practices covering code organisation, error handling, security, interfaces, concurrency, CLI tool creation, file I/O, raw strings, testing, and tooling. 47 rules across 10 categories with local reference files. |
| [`repo-onboard`](groups/open-source-contrib/skills/repo-onboard/SKILL.md) | `open-source-contrib` | Onboards onto a new OSS repository by reading documentation, understanding structure, and summarising how to contribute. |
| [`repo-research`](groups/open-source-contrib/skills/repo-research/SKILL.md) | `open-source-contrib` | Researches a repository to find potential improvements, enhancements, bug fixes, and feature opportunities. |
| [`repo-structure-review`](groups/infrastructure/skills/repo-structure-review/SKILL.md) | `infrastructure` | Audits infrastructure repo structure and recommends improvements for Terraform, Helm, and ArgoCD layouts. |
| [`skill-creator`](global/skills/skill-creator/SKILL.md) | `global` | Guides agents through creating a new skill following the agentskills.io standard. |
| [`terraform-expert`](groups/infrastructure/skills/terraform-expert/SKILL.md) | `infrastructure` | Terraform and IaC optimization guidelines covering 37 rules across 10 categories (state, security, modules, variables, testing, and more). Sourced from [terramate-io/agent-skills](https://github.com/terramate-io/agent-skills). |
| [`terramate-expert`](groups/infrastructure/skills/terramate-expert/SKILL.md) | `infrastructure` | Terramate CLI, Cloud, and Catalyst best practices covering stack management, orchestration, code generation, CI/CD, and drift reconciliation. Sourced from [terramate-io/agent-skills](https://github.com/terramate-io/agent-skills). |
| [`bug-bounty`](groups/security/skills/bug-bounty/SKILL.md) | `security` | Session coordinator for authorized bug bounty research. Establishes authorization context, validates scope, and routes to specialist skills. Run at the start of every bug bounty session. |
| [`bb-program-research`](groups/security/skills/bb-program-research/SKILL.md) | `security` | Evaluates a bug bounty program before committing time to it. Analyses competition level, disclosed reports, tech stack, and scope quality to identify the lowest-competition attack surfaces. |
| [`bb-recon`](groups/security/skills/bb-recon/SKILL.md) | `security` | Cloud-first reconnaissance covering passive OSINT, certificate transparency, GitHub secrets, DNS fingerprinting, S3/GCS/Azure bucket enumeration, Shodan, and active probing. |
| [`bb-secrets-hunting`](groups/security/skills/bb-secrets-hunting/SKILL.md) | `security` | Hunts for leaked credentials across GitHub commits and forks, npm/PyPI packages, Docker Hub images, CI/CD artifact logs, and public paste sites. Includes credential validation guidance. |
| [`bb-vuln-analysis`](groups/security/skills/bb-vuln-analysis/SKILL.md) | `security` | Validates and assesses security findings including SSRF to IMDS, cloud storage misconfigs, IAM privilege escalation, subdomain takeover, DNS issues, IDOR, and general web vulnerabilities. |
| [`bb-api-testing`](groups/security/skills/bb-api-testing/SKILL.md) | `security` | Structured API security testing covering endpoint enumeration, GraphQL introspection and batching attacks, JWT algorithm confusion, BOLA/IDOR, mass assignment, and API versioning issues. |
| [`bb-report-writer`](groups/security/skills/bb-report-writer/SKILL.md) | `security` | Drafts high-quality bug bounty reports for HackerOne, Bugcrowd, and Intigriti with CVSS scoring, three-layer impact structure, precise reproduction steps, and pre-submission checklist. |

## Standards

- `AGENTS.md` files must stay **under 200 lines**.
- Use `SKILL.md` files for complex, multi-step workflows rather than packing rules into AGENTS.md.
- Skills must follow the [Agent Skills Specification](https://agentskills.io/specification).
- Agent-focused header files follow the [agents.md](https://agents.md/) standard.
- Large code snippets go in a sibling `/examples` folder, not inline.
