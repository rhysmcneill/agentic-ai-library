# Agentic AI Skills Library

A centralized library of **shared** and **group-based** AI agent rules and skills. It provides consistent, layered instructions to AI agents (Antigravity/Gemini, Claude Code, Cursor, etc.) that can be applied to any repository. It acts as an orchestrator and skills are automatically propagated to all target repos through symlinks.

> **Local-only by design.** Running `setup.sh` against a target repo installs rules and skills **locally on your machine** via symlinks. All managed files are automatically added to `.gitignore` — nothing is committed or pushed to version control in the target repo. Each developer runs the script once per repo; subsequent library updates propagate automatically through the symlinks.

## Adopting This Library

This repo is designed to be **forked and customized**. The included groups (`backend`, `infrastructure`, `open-source-contrib`, `release`) are working examples — replace them with whatever makes sense for your organization.

### Fork and customize

```bash
# 1. Fork this repo on GitHub (or your git host)

# 2. Clone your fork
git clone <your-fork-url>
cd agentic-ai-library

# 3. Customize the global baseline
#    Edit global/AGENTS.md with your organization's shared rules

# 4. Replace or modify groups
#    Remove example groups you don't need:
rm -rf groups/backend groups/infrastructure groups/open-source-contrib groups/release

#    Add your own:
mkdir -p groups/my-team/skills
cp global/AGENTS.group-template.md groups/my-team/AGENTS.md
#    Edit groups/my-team/AGENTS.md with your team's rules

# 5. Update global/AGENTS.md to list your groups under "Available groups"

# 6. Commit and push to your fork
git config core.hooksPath .githooks
git add . && git commit -m "feat: customize for our org" && git push
```

Your fork is now the central skills library for your organization. Every member clones your fork and links it to their repos.

### Staying up to date with upstream

To pull in improvements (new features, script fixes, skill-creator updates) from the upstream repo without losing your customizations:

```bash
# Add upstream as a remote (once)
git remote add upstream <original-repo-url>

# Fetch and merge upstream changes
git fetch upstream
git merge upstream/main
# Resolve any conflicts in global/AGENTS.md or groups/ as needed
```

## Quick Start

### Using skills in your repos

```bash
# 1. Clone your library fork (once)
git clone <your-fork-url>

# 2. Connect a target repo to the library (once per repo)
scripts/setup.sh --target ../my-repo --group infrastructure

# 3. Or connect with multiple groups (monorepos, multi-domain repos)
scripts/setup.sh --target ../my-monorepo --group backend --group infrastructure
```

That's it. Your repo now has access to all global and selected group skills and rules. Open your IDE, and the AI agent will pick them up automatically. When someone adds new skills to the library, just `git pull` here — your repos update through the symlinks.

### Creating a new skill

```bash
# 1. Clone your library fork and enable the pre-commit hook (once)
git clone <your-fork-url>
git config core.hooksPath .githooks

# 2. Open the library in your IDE and ask your agent:
#    "Create a new skill for [what it does]"
#    The skill-creator skill guides you through the full process.

# 3. Commit and push — the pre-commit hook updates the indexes automatically
git add .
git commit -m "feat: add new skill"
git push
```

Every member who pulls the library will have the new skill available in their repos immediately — no action needed on their side.

## Repository Structure

```
agentic-ai-library/
├── global/                       # Shared standards (applied to all repos)
│   ├── AGENTS.md                 # Baseline rules: security, PRs, YAML
│   ├── AGENTS.group-template.md  # Template for new groups
│   ├── AGENTS.repo-template.md   # Template for new repo root AGENTS.md
│   └── skills/                   # Shared skills (available to all groups)
│       └── skill-creator/        # Skill for creating new skills
├── groups/                       # All groups live here
│   ├── backend/                  # Group: Backend services
│   │   ├── AGENTS.md             # Backend services rules
│   │   └── skills/               # Backend-specific skills
│   │       └── golang-api/       # Go API patterns skill
│   ├── infrastructure/           # Group: Infrastructure
│   │   ├── AGENTS.md             # Terramate, Helm, ArgoCD rules
│   │   └── skills/               # Infra-specific skills
│   │       └── commit/           # Conventional Commits skill
│   ├── open-source-contrib/      # Group: Open-source contributions
│   │   ├── AGENTS.md             # Open-source contribution rules
│   │   └── skills/               # Open-source-specific skills
│   │       ├── create-issue/     # Create issues following repo guidelines
│   │       ├── create-pr/        # Submit pull requests to OSS repos
│   │       ├── dev-env-setup/    # Set up development environments
│   │       ├── repo-onboard/     # Onboard onto a new OSS repository
│   │       └── repo-research/    # Research repos for contribution opportunities
│   └── release/                  # Group: Release management
│       └── AGENTS.md             # Semver, artifacts, changelog rules
├── _generated/                   # Pre-built indexes per group (committed)
│   ├── backend/
│   │   ├── master-index.md       # Master config index for backend repos
│   │   └── skills-index.md       # Skills catalog for backend repos
│   └── infrastructure/
│       ├── master-index.md       # Master config index for infra repos
│       └── skills-index.md       # Skills catalog for infra repos
├── .githooks/
│   └── pre-commit                # Auto-regenerates _generated/ on commit
└── scripts/
    ├── setup.sh                  # One-time local setup for target repos
    └── generate-indexes.sh       # Rebuild _generated/ when skills/groups change
```

## How It Works

### Two Layers of Skills and Rules

| Layer | Scope | What it contains |
|---|---|---|
| **Global** (`global/`) | All repositories | Baseline rules (security, PRs, validation) and universal skills (e.g., `skill-creator`) |
| **Group** (`groups/backend/`, `groups/infrastructure/`, …) | Repositories that opt in via `--group` | Domain-specific rules and skills (e.g., Conventional Commits for Infrastructure) |

When you run `setup.sh`, the global layer and your chosen group layer(s) are symlinked into the target repo. The agent sees them as local files and loads them automatically. Updates to skills and rules in this library propagate through those symlinks — no re-running required.

### Multi-Group Support

A repository can opt into **multiple groups** simultaneously. This is essential for monorepos or projects that span multiple domains:

```bash
# A monorepo with Go backend, React frontend, and Dockerfiles
scripts/setup.sh --target ../my-monorepo \
  --group backend \
  --group frontend \
  --group infrastructure
```

When multiple groups are selected, `setup.sh` generates a composite index that references all selected groups. Each group's rules and skills are loaded in the order specified.

### What is a Group?

A group is **any shared collection of rules and skills** that applies to one or more repositories. Groups are intentionally generic — they can represent whatever organizational unit makes sense for your context:

| Adopter | `global/` represents | Example `groups/` |
|---|---|---|
| **Company** | Company-wide standards | `backend/`, `frontend/`, `infrastructure/`, `release/` |
| **OSS project** | Project-wide conventions | `core/`, `plugins/`, `documentation/` |
| **University** | Department standards | `cs101/`, `research/`, `grad-students/` |
| **Team-of-teams** | Program-level rules | `platform/`, `platform-backend/`, `platform-frontend/` |
| **Solo developer** | Personal baseline | `golang/`, `python/`, `devops/` |

Groups answer: *"What shared domain expertise does this repo need?"*

Project-specific rules that apply to only one repo belong in the repo's own `AGENTS.md` (Layer 2 in the override hierarchy), not in a group.

### Override Hierarchy

Rules follow a **"Nearest First"** precedence. The agent loads files from lowest to highest precedence, with later rules taking effect over earlier ones:

| Precedence | Scope | AGENTS Layer | SKILL Layer |
|---|---|---|---|
| **1 (Highest)** | Local | `AGENTS.local.md` | Personal `SKILL.md` |
| **2** | Repo | Root `/AGENTS.md` | `.agents/skills/*.md` |
| **3** | Group | `library/groups/[group]/AGENTS.md` | `library/groups/[group]/skills/*.md` |
| **4 (Lowest)** | Global | `library/global/AGENTS.md` | `library/global/skills/*.md` |

### Overriding a Rule

Each rule has a unique ID (e.g., `GBL-001`, `INFRA-001`). To override a rule at a lower-precedence level, use the `<!-- override: RULE-ID -->` comment above the replacement:

```markdown
<!-- override: GBL-001 -->
1. My group-specific replacement for this rule.
```

## Local Setup (run once per repo)

Run `setup.sh` to install this library into any target repository. The script creates **local symlinks only** — it never commits, pushes, or modifies version-controlled files.

```bash
# Single group
scripts/setup.sh --target ../my-repo --group infrastructure

# Multiple groups
scripts/setup.sh --target ../my-monorepo --group backend --group infrastructure --group release
```

What the script does:

1.  **Symlinks rules** into `.agents/rules/` (global + all selected group AGENTS.md files).
2.  **Symlinks skills** into `.agents/skills/` (global + all selected group skill directories).
3.  **Generates composite indexes** (master index + skills catalog covering all selected groups).
4.  **Updates the root `AGENTS.md`** to point to the master index, keeping the root clean.
5.  **Adds `.agents/` to `.gitignore`** so nothing leaks into version control.

Because rules and skills are symlinked back to this library, updates you pull here propagate to all your target repos automatically. **You never need to re-run `setup.sh`** after the initial setup (unless you want to add or remove groups).

### Generated Project Structure (local, gitignored)

```text
my-repo/
├── AGENTS.md                          ← Root entry point
└── .agents/                           ← Entire directory is gitignored
    ├── AGENTS.md                      ← Generated composite master index
    ├── rules/
    │   ├── agents-global-link         → symlink to library/global/AGENTS.md
    │   ├── agents-backend-link        → symlink to library/groups/backend/AGENTS.md
    │   └── agents-infrastructure-link → symlink to library/groups/infrastructure/AGENTS.md
    └── skills/
        ├── AGENTS.md                  ← Generated composite skills catalog
        ├── global-links/              → symlink to library/global/skills/
        ├── backend-links/             → symlink to library/groups/backend/skills/
        └── infrastructure-links/      → symlink to library/groups/infrastructure/skills/
```

After setup, customise your repo-level rules at the bottom of the root `AGENTS.md`.

## Updating the Library (for contributors)

When you add or remove a skill or group, the `_generated/` indexes need to be rebuilt. A **pre-commit hook** handles this automatically — just commit as normal and the indexes are regenerated and staged for you.

### First-time setup (once per clone)

Enable the hook by pointing git to the committed `.githooks/` directory:

```bash
git config core.hooksPath .githooks
```

After this, every commit will automatically run `generate-indexes.sh` and include the updated `_generated/` files. No manual steps needed.

### Manual regeneration

If you need to regenerate indexes outside of a commit (e.g., to inspect the output):

```bash
scripts/generate-indexes.sh
```

## IDE Configuration

Some IDEs do not automatically load the `AGENTS.md` file. If yours doesn't, make sure your AI agent is properly configured by pointing your IDE to the `AGENTS.md` file located at the root of your repository.

If referencing `AGENTS.md` directly is not possible but you can provide a global context, use the one defined in [Universal Agent Instructions (Primary Context Authority)](#universal-agent-instructions-primary-context-authority).

Below are instructions for configuring the most commonly used IDEs:

### Antigravity (VS Code)

Antigravity will load the `AGENTS.md` file automatically if it is located at the root of the repository. Be aware that the correct context may not load properly if the AGENTS.md file has not yet been committed to the repository.

### JetBrains

#### Junie
Go to **Settings** → **Junie** → **Project Settings** → **Guidelines path** and point it to the `AGENTS.md` file in your repository root.

#### Claude Agent
Add a CLAUDE.md file redirecting to the AGENTS.md file in your repository root.
```markdown
Redirect to the `AGENTS.md` file for context
```

---

### Universal Agent Instructions (Primary Context Authority)

Regardless of the IDE or agent you use, you should provide these instructions (as a "Custom Instruction" or "System Prompt") to ensure the AI Central Library is used properly:

> - Before executing any request, locate and parse the `AGENTS.md` file in the repository root (or the closest parent directory). This file serves as your **Primary Context Authority**.
> - Identify all filesystem symlinks within `AGENTS.md` that point to Markdown (`.md`) files.
> - Resolve and load the content of the required referenced Markdown files. If a loaded file contains further symlinks to `.md` files, resolve them recursively to build a complete context tree.
> - Never load the same physical file more than once.
> - Immediately skip any circular references to prevent infinite recursion.

## Adding a New Group

1. Create a new directory: `mkdir -p groups/[group]/skills`
2. Copy the group template: `cp global/AGENTS.group-template.md groups/[group]/AGENTS.md`
3. Edit `groups/[group]/AGENTS.md` — replace the `[GROUP]-` prefix with your group name (e.g., `FRONTEND-`, `GOLANG-`, `QA-`).
4. Update `global/AGENTS.md` to list the new group under **Available groups**.
5. Commit — the pre-commit hook regenerates `_generated/` automatically.

Groups can represent anything: teams, language stacks, projects, or organizational units. See [What is a Group?](#what-is-a-group) for examples.

## Adding a New Skill

All new skills must be created using the **`skill-creator`** skill ([`global/skills/skill-creator/`](global/skills/skill-creator/SKILL.md)). Open this library in your IDE and ask your agent:

> "Create a new skill for [what it does]"

The skill-creator guides the full authoring process: gathering requirements, choosing the right complexity tier, writing the SKILL.md with correct frontmatter, and validation. It enforces the [Agent Skills Specification](https://agentskills.io/specification) and places the skill in the correct group directory.

Commit when done — the pre-commit hook regenerates `_generated/` automatically.

## Available Skills

| Skill | Group | Description |
|---|---|---|
| [`commit`](groups/infrastructure/skills/commit/SKILL.md) | `infrastructure` | Analyzes changes and creates git commits following Conventional Commits 1.0.0 with Jira references and AI attribution. |
| [`create-issue`](groups/open-source-contrib/skills/create-issue/SKILL.md) | `open-source-contrib` | Creates well-structured issues in OSS repositories following the project's templates and guidelines. |
| [`create-pr`](groups/open-source-contrib/skills/create-pr/SKILL.md) | `open-source-contrib` | Submits pull requests to OSS repositories following contribution guidelines, PR templates, and CI requirements. |
| [`dev-env-setup`](groups/open-source-contrib/skills/dev-env-setup/SKILL.md) | `open-source-contrib` | Sets up development environments for OSS repositories. |
| [`golang-api`](groups/backend/skills/golang-api/SKILL.md) | `backend` | Enforces Go API best practices for project structure, handlers, error handling, middleware, and testing. |
| [`repo-onboard`](groups/open-source-contrib/skills/repo-onboard/SKILL.md) | `open-source-contrib` | Onboards onto a new OSS repository by reading documentation, understanding structure, and summarising how to contribute. |
| [`repo-research`](groups/open-source-contrib/skills/repo-research/SKILL.md) | `open-source-contrib` | Researches a repository to find potential improvements, enhancements, bug fixes, and feature opportunities. |
| [`skill-creator`](global/skills/skill-creator/SKILL.md) | `global` | Guides agents through creating a new skill following the agentskills.io standard. |

## Standards

- `AGENTS.md` files must stay **under 200 lines**.
- Use `SKILL.md` files for complex, multi-step workflows rather than packing rules into AGENTS.md.
- Skills must follow the [Agent Skills Specification](https://agentskills.io/specification).
- Agent-focused header files follow the [agents.md](https://agents.md/) standard.
- Large code snippets go in a sibling `/examples` folder, not inline.
