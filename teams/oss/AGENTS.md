# AGENTS.md — oss

## Context

Open-source contribution domain rules for AI coding agents. Loaded after `company/AGENTS.md`.
Rules here extend or override the global baseline for OSS-related workflows.

To override a global rule, reference its Rule ID explicitly:

```
<!-- override: GBL-001 -->
1. <Your replacement rule here>
```

To add a new team rule, use a team-prefixed ID:

```
<!-- rule: OSS-001 -->
1. <Your new rule here>
```

## Team-specific Overrides

<!-- No overrides yet. Add entries here using the override comment syntax above. -->

## Team-specific Rules

<!-- rule: OSS-001 -->
1. **Follow upstream guidelines first:** Always locate and read `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, and any contribution-related documentation before making changes or opening issues. The project's rules take precedence over personal preferences.

<!-- rule: OSS-002 -->
2. **Respect project conventions:** Adopt the repository's existing coding style, linter configuration, formatting rules, and naming conventions. Never impose external standards on a project you do not own.

<!-- rule: OSS-003 -->
3. **Check for duplicates:** Before creating an issue or pull request, search existing open and closed issues/PRs to avoid duplicating work or discussions.

<!-- rule: OSS-004 -->
4. **Minimal, focused contributions:** Each issue or PR should address a single concern. Do not bundle unrelated changes. Small, well-scoped contributions are easier to review and more likely to be accepted.

<!-- rule: OSS-005 -->
5. **Never expose secrets:** Do not commit, log, or reference secrets, tokens, API keys, or credentials in any OSS repository. Audit staged changes before every commit.

<!-- rule: OSS-006 -->
6. **Respect licensing:** Verify the project's license before contributing. Ensure any code, dependencies, or assets you introduce are compatible with that license.
