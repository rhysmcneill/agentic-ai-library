---
name: repo-research
description: Researches an open-source repository to find potential improvements, enhancements, bug fixes, and feature opportunities. Use when asked to "find things to contribute", "research this repo", "look for improvements", "find bugs to fix", "what can I work on", or "identify contribution opportunities".
---

# Research a Repository for Contribution Opportunities

Systematically analyse a repository to identify actionable improvements that could become issues or pull requests.

## Tools

Prefer the GitHub MCP server tools when available. Fall back to the `gh` CLI when MCP is not configured.

| Action | MCP tool | CLI fallback |
|--------|----------|--------------|
| Search issues | `search_issues` | `gh issue list --search` |
| List open issues | `list_issues` | `gh issue list` |
| List PRs | `list_pull_requests` | `gh pr list` |
| Search code | `search_code` | `gh search code` |
| Read files | `get_file_contents` | `gh api` or clone + read |

## Step 1: Review Existing Issues and Discussions

Before looking for new opportunities, understand what the community already knows:

1. Use `search_issues` (MCP) or `gh issue list` to read open issues — note recurring themes, stale issues, and `good first issue` / `help wanted` labels.
2. Read recent closed issues and merged PRs — understand what changes are being accepted and what gets rejected.
3. Check Discussions or mailing lists if available — maintainers often share roadmap hints there.

Produce a short summary of:
- Active areas of development
- Known pain points the community has raised
- Topics maintainers have explicitly said they want help with

## Step 2: Analyse Code Quality

Scan the codebase for common improvement signals:

| Signal | Where to look | Opportunity type |
|--------|---------------|------------------|
| `TODO`, `FIXME`, `HACK`, `XXX` comments | Grep across source files | Bug fix / enhancement |
| Deprecated API usage | Import statements, compiler warnings | Enhancement |
| Missing or outdated dependencies | Dependency files, security advisories | Maintenance |
| Inconsistent error handling | Source files | Bug fix / enhancement |
| Dead code or unused exports | Static analysis, IDE warnings | Cleanup |
| Hardcoded values that should be configurable | Source files, config | Enhancement |

For each finding, note the file, line, and a one-sentence description of the issue.

## Step 3: Evaluate Test Coverage

Identify testing gaps:

1. **Missing test files** — source files with no corresponding test file.
2. **Untested edge cases** — functions that handle errors, boundary conditions, or configuration variants without test coverage.
3. **Flaky or skipped tests** — tests marked as `skip`, `pending`, or `xfail`.
4. **Integration test gaps** — features that only have unit tests but interact with external systems.

If a coverage report is available (e.g., `coverage.html`, Codecov badge), reference it.

## Step 4: Review Documentation

Look for documentation issues:

1. **Outdated README** — setup instructions that no longer work, broken links, screenshots of old UI.
2. **Missing API docs** — public functions/types without doc comments.
3. **Incomplete examples** — example code that doesn't compile or is out of date.
4. **Translation gaps** — if the project supports i18n, check for missing or stale translations.

## Step 5: Check for Security and Performance

Flag potential concerns (without making false claims):

1. **Dependency vulnerabilities** — check if `dependabot`, `renovate`, or similar tools are enabled; note any open security PRs.
2. **Obvious performance issues** — N+1 queries, unbounded allocations, missing pagination on list endpoints.
3. **Missing input validation** — user-facing endpoints or CLI commands that accept untrusted input without sanitisation.

Only report findings you can substantiate with specific code references.

## Step 6: Categorise and Prioritise Findings

Present all findings in a structured table:

```
| # | Category     | Summary                          | File(s)           | Impact | Effort |
|---|-------------|----------------------------------|-------------------|--------|--------|
| 1 | Bug fix     | Off-by-one in pagination logic   | api/list.go:42    | High   | Low    |
| 2 | Enhancement | Add retry logic to HTTP client   | pkg/client.go     | Medium | Medium |
| 3 | Docs        | Broken install link in README    | README.md:15      | Low    | Low    |
```

**Category values:** Bug fix, Enhancement, Feature, Docs, Tests, Maintenance, Performance, Security

**Impact:** How much this affects users or contributors (High / Medium / Low)

**Effort:** Estimated size of the change (Low / Medium / High)

Sort by impact descending, then effort ascending (high-impact, low-effort items first).

## Step 7: Recommend Next Steps

Based on the findings, recommend 3-5 concrete next steps the user should take. Prioritise:

1. Items labelled `good first issue` or `help wanted` by maintainers
2. High-impact, low-effort findings from the analysis
3. Items aligned with the project's stated roadmap or recent activity

For each recommendation, state whether it should become an issue, a PR, or a discussion post.
