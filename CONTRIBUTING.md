# Contributing to Agentic AI Skills Library

Thank you for your interest in contributing! This library provides shared AI agent rules and skills that propagate to all linked repositories via symlinks. Because of this design, changes here have a wide impact — so we appreciate careful, well-structured contributions.

## Table of Contents

- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Adding a New Skill](#adding-a-new-skill)
- [Adding a New Group](#adding-a-new-group)
- [Modifying Rules](#modifying-rules)
- [Conventions and Standards](#conventions-and-standards)
- [Generated Files](#generated-files)
- [Pull Request Guidelines](#pull-request-guidelines)
- [License](#license)

## Getting Started

### Prerequisites

- Git
- Bash (for running scripts and hooks)
- Python 3 (for skill validation via `agentskills validate`)

### Development Setup

```bash
# 1. Fork and clone the repository
git clone <your-fork-url>
cd agentic-ai-library

# 2. Enable the pre-commit hook (required)
git config core.hooksPath .githooks
```

The pre-commit hook runs `scripts/generate-indexes.sh` automatically on every commit, keeping the `_generated/` directory in sync with your changes.

## Types of Contributions

| Contribution | Where to make changes |
|---|---|
| New skill | `global/skills/<name>/` or `groups/<group>/skills/<name>/` |
| New group | `groups/<group>/` |
| Rule changes (global) | `global/AGENTS.md` |
| Rule changes (group) | `groups/<group>/AGENTS.md` |
| Script improvements | `scripts/` |
| Documentation | `README.md`, `CONTRIBUTING.md` |
| Bug fixes | Wherever the bug lives |

## Adding a New Skill

All skills **must** be created using the `skill-creator` skill. This ensures consistency with the [Agent Skills Specification](https://agentskills.io/specification).

### Quick steps

1. Open the library in your IDE and ask your AI agent:
   > "Create a new skill for [what it does]"

2. The `skill-creator` (at `global/skills/skill-creator/SKILL.md`) will guide you through requirements gathering, naming, writing, and validation.

3. Validate the skill:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install skills-ref
   agentskills validate <path/to/skill-directory>
   ```

4. Update the **Available Skills** table in `README.md` — keep entries sorted alphabetically by skill name.

5. Commit. The pre-commit hook regenerates `_generated/` automatically.

### Skill naming rules

- Lowercase letters, digits, and hyphens only (`a-z`, `0-9`, `-`)
- 1–64 characters
- Must not start or end with `-`; no consecutive hyphens (`--`)
- Directory name must match the `name` field in the SKILL.md frontmatter

### Skill structure tiers

| Tier | Structure | Use when |
|---|---|---|
| Simple | `SKILL.md` only | Self-contained instructions under ~200 lines |
| With references | `SKILL.md` + `references/` | Domain knowledge loaded conditionally |
| With scripts | `SKILL.md` + `scripts/` | Workflow automation needing Python/Bash |
| Full | All of the above | Complex skills with automation and domain knowledge |

### Skill placement

- **Global skills** (`global/skills/`) — available to all groups and repositories.
- **Group skills** (`groups/<group>/skills/`) — available only to repositories that opt into that group.

Place a skill at the narrowest scope that makes sense. If only one group needs it, put it in that group. If multiple groups benefit, promote it to global.

## Adding a New Group

1. Create the directory structure:
   ```bash
   mkdir -p groups/<group>/skills
   ```

2. Copy the group template:
   ```bash
   cp global/AGENTS.group-template.md groups/<group>/AGENTS.md
   ```

3. Edit `groups/<group>/AGENTS.md`:
   - Replace the `[group-name]` placeholder with your group name.
   - Replace `[GROUP]-` rule ID prefix with your group's prefix (e.g., `FRONTEND-`, `QA-`).

4. Update `global/AGENTS.md` to list the new group under **Available groups**.

5. Commit — the pre-commit hook regenerates `_generated/` automatically.

## Modifying Rules

### Rule ID conventions

| Prefix | Scope | Location |
|---|---|---|
| `GBL-NNN` | Global baseline | `global/AGENTS.md` |
| `REPO-NNN` | This library repo only | Root `AGENTS.md` |
| `<GROUP>-NNN` | Group-specific | `groups/<group>/AGENTS.md` |

When adding a new rule, assign the next sequential number within the appropriate prefix.

### Override hierarchy

Rules follow **"Nearest First"** precedence (highest to lowest):

1. `AGENTS.local.md` (personal, gitignored)
2. Root `AGENTS.md` (repo-level)
3. `groups/<group>/AGENTS.md` (group-level)
4. `global/AGENTS.md` (global baseline)

To intentionally override a rule from a higher-precedence layer, use the override comment:

```markdown
<!-- override: GBL-001 -->
1. Your replacement rule here.
```

### Avoiding duplication

- Push shared, generic instructions **up** the hierarchy (toward global).
- Push specialized details **down** (toward group or repo).
- Never duplicate the same rule across multiple layers.
- Higher-level files should be the smallest and most concise.

## Conventions and Standards

### File size limits

- `AGENTS.md` files: **under 200 lines**. Move verbose content to `README.md` or skills.
- `SKILL.md` files: **under 500 lines**. Move reference material to `references/`.

### Writing style

- **AGENTS.md**: concise, declarative rules.
- **SKILL.md body**: imperative voice ("Read the file and extract..."), not descriptive ("This skill reads the file...").
- **SKILL.md description**: third person ("Processes Excel files..."), with trigger phrases.

### What not to create

Do not add auxiliary files inside skill directories such as `README.md`, `CHANGELOG.md`, `INSTALLATION_GUIDE.md`, or `QUICK_REFERENCE.md`. The `SKILL.md` is the single entry point.

### Repository map

When adding, moving, or removing files or directories, update the **Repository Map** in the root `AGENTS.md` to reflect the current structure.

### Templates

If you modify `AGENTS.repo-template.md` or `AGENTS.group-template.md`, ensure all existing group `AGENTS.md` files remain consistent with the updated templates.

## Generated Files

The `_generated/` directory contains pre-built indexes (`master-index.md`, `skills-index.md`) for each group. These files are **committed to the repo** but should **never be edited by hand**.

They are rebuilt automatically by:
- The **pre-commit hook** (`.githooks/pre-commit`) on every commit.
- Running `scripts/generate-indexes.sh` manually.

If you notice stale indexes, run:

```bash
scripts/generate-indexes.sh
```

## Pull Request Guidelines

1. **One concern per PR.** Keep pull requests focused — a new skill, a new group, or a rule change. Avoid mixing unrelated changes.

2. **Enable the pre-commit hook.** Ensure `git config core.hooksPath .githooks` is set so `_generated/` is up to date.

3. **Validate skills.** If your PR adds or modifies a skill, run `agentskills validate` and confirm it passes.

4. **Update documentation.** If you add a skill, update the Available Skills table in `README.md` (alphabetical order). If you add a group, update the Available groups list in `global/AGENTS.md`.

5. **Test with `setup.sh`.** If your change affects the setup flow, verify it works by running `scripts/setup.sh` against a test repository:
   ```bash
   scripts/setup.sh --target /tmp/test-repo --group <your-group>
   ```

6. **Describe your changes.** Explain what you changed and why. For new skills, include a brief description of what the skill does and when it should be used.

## License

By contributing to this project, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).
