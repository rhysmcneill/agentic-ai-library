# AGENTS.md — backend

## Context

Backend domain rules for AI coding agents. Loaded after `company/AGENTS.md`.
Rules here extend or override the global baseline for this team's repositories.

To override a global rule, reference its Rule ID explicitly:

```
<!-- override: GBL-001 -->
1. <Your replacement rule here>
```

To add a new team rule, use a team-prefixed ID:

```
<!-- rule: BACKEND-001 -->
1. <Your new rule here>
```

## Team-specific Overrides

<!-- No overrides yet. Add entries here using the override comment syntax above. -->

## Team-specific Rules

<!-- rule: BACKEND-001 -->
1. **No direct DB access from handlers:** Never import or call repository/database packages from HTTP handlers. All data access must go through the service layer.

<!-- rule: BACKEND-002 -->
2. **Dependency management:** Run `go mod tidy` after adding or removing imports. Never commit a `go.mod` with unused or missing dependencies.
