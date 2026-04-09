# AGENTS.md — global

## Context

Global baseline guide for any AI coding agent. This file applies to all repositories linked to the library.

## How to use this library

- Always load `global/AGENTS.md` as the shared baseline.
- If a change touches a specific domain, also load `groups/{domain}/AGENTS.md`.
- A repository can use **multiple groups** simultaneously (e.g., `--group backend --group golang`).
- Activate only the skills needed for the current task.
- To override a rule from a higher-precedence file, reference its Rule ID explicitly:
  `<!-- override: GBL-001 -->` then state the replacement rule.

## Available groups

- `groups/backend/` (Backend services rules)
- `groups/infrastructure/` (Terramate, Helm, ArgoCD rules)
- `groups/open-source-contrib/` (Open-source contribution rules)
- `groups/release/` (Semver, artifacts, changelog rules)

## Global rules

<!-- rule: GBL-001 -->
1. Prioritize security and change traceability.

<!-- rule: GBL-002 -->
2. Avoid destructive actions without explicit approval.

<!-- rule: GBL-003 -->
3. Validate changes with the proper lint/tests/plan before finishing.

<!-- rule: GBL-004 -->
4. Follow the conventions defined by the affected domain.
