# AGENTS.md — global

## Context

Global [company] guide for any AI coding agent used in technical repositories.

## How to use this library

- Always load `company/AGENTS.md` as the shared baseline.
- If a change touches a specific domain, also load `teams/{domain}/AGENTS.md`.
- Activate only the skills needed for the current task.
- To override a rule from a higher-precedence file, reference its Rule ID explicitly:
  `<!-- override: GBL-001 -->` then state the replacement rule.

## Available domains

- `company/` (Global standards)
- `teams/backend/` (Team-specific: Backend services rules)
- `teams/infrastructure/` (Team-specific: Terramate, Helm, ArgoCD rules)
- `teams/release/` (Team-specific: Semver, artifacts, changelog rules)

## Global rules

<!-- rule: GBL-001 -->
1. Prioritize security and change traceability.

<!-- rule: GBL-002 -->
2. Avoid destructive actions without explicit approval.

<!-- rule: GBL-003 -->
3. Validate changes with the proper lint/tests/plan before finishing.

<!-- rule: GBL-004 -->
4. Follow the conventions defined by the affected domain.
