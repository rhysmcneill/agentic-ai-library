# ai-agents-config-library

A centralized library of **company-wide** and **team-based** AI agent rules and skills at [Company]. It provides consistent, layered instructions to AI agents (Antigravity/Gemini, Claude Code, Cursor, etc.) that can be applied to any repository.

> **Local-only by design.** Running `setup.sh` against a target repo installs rules and skills **locally on your machine** via symlinks. All managed files are automatically added to `.gitignore` — nothing is committed or pushed to version control in the target repo. Each developer runs the script once per repo; subsequent library updates propagate automatically through the symlinks.

## Quick Start

### Using skills in your repos

```bash
# 1. Clone this library (once)
git clone <library-url>

# 2. Connect a target repo to the library (once per repo)
scripts/setup.sh --target ../my-repo --group infrastructure
```

That's it. Your repo now has access to all company-wide and infrastructure-team skills and rules. Open your IDE, and the AI agent will pick them up automatically. When someone adds new skills to the library, just `git pull` here — your repos update through the symlinks.

### Creating a new skill

```bash
# 1. Clone this library and enable the pre-commit hook (once)
git clone <library-url>
git config core.hooksPath .githooks

# 2. Open the library in your IDE and ask your agent:
#    "Create a new skill for [what it does]"
#    The skill-creator skill guides you through the full process.

# 3. Commit and push — the pre-commit hook updates the indexes automatically
git add .
git commit -m "feat: add new skill"
git push
```

Every developer who pulls this library will have the new skill available in their repos immediately — no action needed on their side.

## Repository Structure

```
ai-agents-config-library/
├── company/                       # Company-wide standards (applied to all repos)
│   ├── AGENTS.md                  # Baseline rules: security, PRs, YAML
│   ├── AGENTS.team-template.md    # Template for new team domains
│   ├── AGENTS.repo-template.md    # Template for new repo root AGENTS.md
│   └── skills/                    # Company-wide skills
│       └── skill-creator/         # Skill for creating new skills
├── infrastructure/                # Team-specific domain (Infra)
│   ├── AGENTS.md                  # Terramate, Helm, ArgoCD rules
│   └── skills/                    # Infra-specific skills
│       └── commit/                # Conventional Commits skill
├── _generated/                    # Pre-built indexes per team (committed)
│   └── infrastructure/
│       ├── master-index.md        # Master config index for infra repos
│       └── skills-index.md        # Skills catalog for infra repos
├── .githooks/
│   └── pre-commit                 # Auto-regenerates _generated/ on commit
└── scripts/
    ├── setup.sh                   # One-time local setup for target repos
    └── generate-indexes.sh        # Rebuild _generated/ when skills/teams change
```

## How It Works

### Two Layers of Skills and Rules

| Layer | Scope | What it contains |
|---|---|---|
| **Company** (`company/`) | All repositories | Baseline rules (security, PRs, YAML) and universal skills (e.g., `skill-creator`) |
| **Team** (`infrastructure/`, …) | Repositories that opt in via `--group` | Domain-specific rules and skills (e.g., Conventional Commits for Infrastructure) |

When you run `setup.sh`, both the company layer and your chosen team layer are symlinked into the target repo. The agent sees them as local files and loads them automatically. Updates to skills and rules in this library propagate through those symlinks — no re-running required.

### Override Hierarchy

Rules follow a **"Nearest First"** precedence. The agent loads files from lowest to highest precedence, with later rules taking effect over earlier ones:

| Precedence | Scope | AGENTS Layer | SKILL Layer |
|---|---|---|---|
| **1 (Highest)** | Local | `AGENTS.local.md` | Personal `SKILL.md` |
| **2** | Repo | Root `/AGENTS.md` | `.agents/skills/*.md` |
| **3** | Team | `library/[team]/AGENTS.md` | `library/[team]/skills/*.md` |
| **4 (Lowest)** | Company | `library/company/AGENTS.md` | `library/company/skills/*.md` |

### Overriding a Rule

Each rule has a unique ID (e.g., `GBL-001`, `INFRA-001`). To override a rule at a lower-precedence level, use the `<!-- override: RULE-ID -->` comment above the replacement:

```markdown
<!-- override: GBL-001 -->
1. My team-specific replacement for this rule.
```

## Local Setup (run once per repo)

Run `setup.sh` to install this library into any target repository. The script creates **local symlinks only** — it never commits, pushes, or modifies version-controlled files.

```bash
# From this library repository:
scripts/setup.sh --target ../my-repo --group infrastructure
```

What the script does:

1.  **Symlinks rules** into `.agents/rules/` (company + team AGENTS.md files).
2.  **Symlinks skills** into `.agents/skills/` (company + team skill directories).
3.  **Symlinks pre-built indexes** from `_generated/` (master index + skills catalog).
4.  **Updates the root `AGENTS.md`** to point to the master index, keeping the root clean.
5.  **Adds `.agents/` to `.gitignore`** so nothing leaks into version control.

Because everything is a symlink back to this library, updates you pull here propagate to all your target repos automatically. **You never need to re-run `setup.sh`** after the initial setup.

### Generated Project Structure (local, gitignored)

```text
my-repo/
├── AGENTS.md                          ← Root entry point
└── .agents/                           ← Entire directory is gitignored
    ├── AGENTS.md                       → symlink to _generated/{team}/master-index.md
    ├── rules/
    │   ├── agents-company-link         → symlink to library/company/AGENTS.md
    │   └── agents-infrastructure-link  → symlink to library/infrastructure/AGENTS.md
    └── skills/
        ├── AGENTS.md                   → symlink to _generated/{team}/skills-index.md
        ├── company-links/              → symlink to library/company/skills/
        └── infrastructure-links/       → symlink to library/infrastructure/skills/
```

After setup, customise your repo-level rules at the bottom of the root `AGENTS.md`.

## Updating the Library (for contributors)

When you add or remove a skill or team, the `_generated/` indexes need to be rebuilt. A **pre-commit hook** handles this automatically — just commit as normal and the indexes are regenerated and staged for you.

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

Some IDEs do not automatically load the `AGENTS.md` file. If yours doesn’t, make sure your AI agent is properly configured by pointing your IDE to the `AGENTS.md` file located at the root of your repository.

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

## Adding a New Team Domain

1. Create a new directory: `mkdir -p [team]/skills`
2. Copy the team template: `cp company/AGENTS.team-template.md [team]/AGENTS.md`
3. Edit `[team]/AGENTS.md` — replace the `[TEAM]-` prefix with your team name (e.g., `QA-`, `FRONTEND-`).
4. Update `company/AGENTS.md` to list the new domain under **Available domains**.
5. Commit — the pre-commit hook regenerates `_generated/` automatically.

## Adding a New Skill

All new skills must be created using the **`skill-creator`** skill ([`company/skills/skill-creator/`](company/skills/skill-creator/SKILL.md)). Open this library in your IDE and ask your agent:

> "Create a new skill for [what it does]"

The skill-creator guides the full authoring process: gathering requirements, choosing the right complexity tier, writing the SKILL.md with correct frontmatter, and validation. It enforces the [Agent Skills Specification](https://agentskills.io/specification) and places the skill in the correct domain directory.

Commit when done — the pre-commit hook regenerates `_generated/` automatically.

## Available Skills

| Skill | Domain | Description |
|---|---|---|
| [`commit`](infrastructure/skills/commit/SKILL.md) | `infrastructure` | Analyzes changes and creates git commits following Conventional Commits 1.0.0 with Jira references and AI attribution. |
| [`skill-creator`](company/skills/skill-creator/SKILL.md) | `company` | Guides agents through creating a new skill following the agentskills.io standard. |

## Standards

- `AGENTS.md` files must stay **under 200 lines**.
- Use `SKILL.md` files for complex, multi-step workflows rather than packing rules into AGENTS.md.
- Skills must follow the [Agent Skills Specification](https://agentskills.io/specification).
- Agent-focused header files follow the [agents.md](https://agents.md/) standard.
- Large code snippets go in a sibling `/examples` folder, not inline.
