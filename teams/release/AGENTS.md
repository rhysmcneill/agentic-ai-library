# AGENTS.md — release

## Context

Release domain rules for AI coding agents. Loaded after `company/AGENTS.md`.
Rules here extend or override the global baseline for this team's repositories.

To override a global rule, reference its Rule ID explicitly:

```
<!-- override: GBL-001 -->
1. <Your replacement rule here>
```

To add a new team rule, use a team-prefixed ID:

```
<!-- rule: RELEASE-001 -->
1. <Your new rule here>
```

## Team-specific Overrides

<!-- No overrides yet. Add entries here using the override comment syntax above. -->

## Team-specific Rules

<!-- rule: RELEASE-001 -->
1. **All services, tools and integrations should follow semver:** Never allow any service, tool or integration to be released without complying to semver for their artifacts.

<!-- rule: RELEASE-002 -->
2. **Artifact generation:** All releases should create a release artifact (binary, docker image, helm chart etc) and upload to a secured repository (ECR, GHCR, DockerHub etc).

<!-- rule: RELEASE-003 -->
3. **Changelog required:** Every release must include a human-readable changelog entry or GitHub release notes. Generate entries from conventional commit messages or PR titles when available.

<!-- rule: RELEASE-004 -->
4. **Immutable releases:** Once a version is published, it must never be overwritten or re-tagged. If a fix is needed, bump the version.

<!-- rule: RELEASE-005 -->
5. **Git tagging:** Every release must be tagged in git using the format `vMAJOR.MINOR.PATCH`. The tag version must match the artifact version exactly.

<!-- rule: RELEASE-006 -->
6. **Pre-release validation:** All CI checks (tests, linting, security scans) must pass before a release is cut. Never skip or bypass pipeline gates.

<!-- rule: RELEASE-007 -->
7. **No breaking changes without major bump:** Breaking API or contract changes require a major version increment. Backwards-incompatible changes must never ship under a minor or patch release.
