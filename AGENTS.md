# AGENTS.md — ai-agents-config-library

## Context

Repo-specific rules for AI coding agents. This is the **configuration library itself** — the central source of truth for AI agent rules and skills at [Company]. Changes here affect all repositories that link to this library.

This file is loaded directly at repo scope (Layer 2). There are no parent team symlinks here — this repo is the source, not a consumer.

To override a global rule, reference its Rule ID explicitly:

```
<!-- override: GBL-001 -->
1. <Your replacement rule here>
```

To add a new rule, use a `REPO-` prefixed ID:

```
<!-- rule: REPO-001 -->
1. <Your new rule here>
```

## Repository Map

```
ai-agents-config-library/
├── company/                       # Company-wide baseline (applies to all repos)
│   ├── AGENTS.md                  # GBL-* rules. Load this first.
│   ├── AGENTS.team-template.md    # Copy when adding a new team domain
│   ├── AGENTS.repo-template.md    # Copy when onboarding a new repository
│   └── skills/
│       └── skill-creator/         # Use this skill to create any new skill
├── backend/                       # Backend team domain
│   ├── AGENTS.md                  # BACKEND-* rules
│   └── skills/
├── infrastructure/                # Infra team domain (Terramate, Helm, ArgoCD)
│   ├── AGENTS.md                  # INFRA-* rules
│   └── skills/
│       └── commit/                # Conventional Commits skill
├── _generated/                    # Pre-built indexes per team (committed)
│   ├── backend/
│   │   ├── master-index.md        # Master config index for backend repos
│   │   └── skills-index.md        # Skills catalog for backend repos
│   └── infrastructure/
│       ├── master-index.md        # Master config index for infra repos
│       └── skills-index.md        # Skills catalog for infra repos
├── .githooks/
│   └── pre-commit                 # Auto-regenerates _generated/ on commit
└── scripts/
    ├── setup.sh                   # One-time local setup for target repos
    └── generate-indexes.sh        # Rebuild _generated/ when skills/teams change
```

## Key Conventions

### Rule IDs
- `GBL-NNN` — global company rules (`company/AGENTS.md`)
- `BACKEND-NNN` — backend team rules (`backend/AGENTS.md`)
- `INFRA-NNN` — infra team rules (`infrastructure/AGENTS.md`)
- `REPO-NNN` — rules specific to this library repo

### Skill Locations
Skills live under `{domain}/skills/{skill-name}/SKILL.md`. The `company/skills/` directory holds skills available to all domains; team-specific skills live under their respective domain directory.

### Creating a New Skill
Always use the `skill-creator` skill. Trigger it with:
> "Create a new skill for [what it does]"

## Repo-specific Overrides

<!-- No overrides yet. Add entries here using the override comment syntax above. -->

## Repo-specific Rules

<!-- rule: REPO-001 -->
1. **Templates are canonical:** Do not edit `AGENTS.repo-template.md` or `AGENTS.team-template.md` without updating all existing domain AGENTS.md files to stay consistent.

<!-- rule: REPO-002 -->
2. **Keep AGENTS.md files under 200 lines.** Move verbose documentation to the `README.md`.

<!-- rule: REPO-003 -->
3. **Update `README.md` Available Skills table** when adding or removing a skill. Keep entries sorted alphabetically by skill name.

<!-- rule: REPO-004 -->
4. **Keep the Repository Map up to date.** When adding, moving, or removing files and directories in this repo, update the map in this `AGENTS.md` file to reflect the current structure.

<!-- rule: REPO-005 -->
5. **Rules/skills design instructions:** When generating or modifying rules and skills, actively prevent repetitions and collisions across the hierarchy (company > team > repo > local).
   - **Repetitions (Consolidate):** Push shared, generic instructions UP the hierarchy to keep files small. Push highly specialized details DOWN the hierarchy. Do not duplicate rules. **CRITICAL: Higher-level files (e.g., company) must be the smallest and most concise possible.**
   - **Collisions (Override):** If a specific domain intentionally contradicts a broader rule, you must explicitly use the `<!-- override: GBL-XXX -->` syntax in the lower-level file.
