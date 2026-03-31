---
name: create-issue
description: Creates a well-structured issue in an open-source repository following the project's templates and guidelines. Use when asked to "create an issue", "file a bug report", "open a feature request", "report a bug", "submit an issue", or "write an issue for this".
---

# Create an Issue in an Open-Source Repository

Draft and submit a high-quality issue that follows the target project's conventions and maximises the chance of maintainer engagement.

## Tools

Prefer the GitHub MCP server tools when available. Fall back to the `gh` CLI when MCP is not configured.

| Action | MCP tool | CLI fallback |
|--------|----------|--------------|
| Search for duplicates | `search_issues` | `gh issue list --search` |
| Read repo files / templates | `get_file_contents` | `gh api` or clone + read |
| Create issue | `create_issue` | `gh issue create` |
| Comment on issue | `add_issue_comment` | `gh issue comment` |

## Step 1: Check for Duplicates

Before drafting anything, use `search_issues` (MCP) or `gh issue list --search` to search for existing issues:

1. Search open issues using relevant keywords from the topic.
2. Search closed issues — the problem may have been resolved or intentionally declined.
3. If a related issue exists, assess whether to comment on it (via `add_issue_comment` or `gh issue comment`) instead of opening a new one.

If a duplicate or closely related issue is found, **stop** and present it to the user. Ask whether to comment on the existing issue or proceed with a new one.

## Step 2: Locate the Issue Template

Check for issue templates in the repository:

1. `.github/ISSUE_TEMPLATE/` — look for YAML or Markdown templates (bug report, feature request, etc.).
2. `.github/ISSUE_TEMPLATE.md` — single template fallback.
3. `CONTRIBUTING.md` — may contain issue formatting instructions even without a template directory.

If templates exist, identify the correct one for the issue type and follow its structure exactly. If no templates exist, use the fallback structures defined in Step 4.

## Step 3: Gather the Required Information

Collect all details needed for the issue. Ask the user for anything missing.

**For bug reports:**

| Field | Required |
|-------|----------|
| Summary of the bug | Yes |
| Steps to reproduce | Yes |
| Expected behaviour | Yes |
| Actual behaviour | Yes |
| Environment (OS, language version, dependency versions) | Yes |
| Error messages, logs, or screenshots | If available |
| Workaround (if known) | If available |

**For feature requests / enhancements:**

| Field | Required |
|-------|----------|
| Problem statement or motivation | Yes |
| Proposed solution | Yes |
| Alternative approaches considered | If applicable |
| Relevant code references | If applicable |
| Willingness to implement (will the user submit a PR?) | Yes |

## Step 4: Draft the Issue

Use the project's template if one was found in Step 2. Otherwise, use these fallback structures:

**Bug report fallback:**

```markdown
### Description
<Clear, one-paragraph summary of the bug>

### Steps to Reproduce
1. <Step one>
2. <Step two>
3. <Step three>

### Expected Behaviour
<What should happen>

### Actual Behaviour
<What happens instead>

### Environment
- OS: <e.g., Ubuntu 24.04>
- Version: <e.g., v1.3.2>
- <Other relevant versions>

### Additional Context
<Logs, screenshots, related issues>
```

**Feature request fallback:**

```markdown
### Problem
<What problem does this solve? Why is it needed?>

### Proposed Solution
<How should this work?>

### Alternatives Considered
<What other approaches were evaluated?>

### Additional Context
<Code references, examples from other projects, mockups>
```

**Writing rules:**
- Title must be concise and descriptive — start with the area affected if the project uses that convention (e.g., `[api] Pagination returns duplicate results`).
- Use the imperative mood for feature requests ("Add support for...") and descriptive statements for bugs ("Pagination returns duplicate results when...").
- Reference specific files, lines, or functions when applicable.
- Never include secrets, tokens, or credentials in issue text.
- If the project uses labels, suggest appropriate ones but note that only maintainers can typically apply them.

## Step 5: Review and Present

Present the complete issue (title + body) to the user for review before submission. Format it as it would appear on GitHub/GitLab.

Ask the user:
1. Does this accurately describe the problem/request?
2. Should anything be added or removed?
3. Should I submit this issue now?

Wait for explicit approval before creating the issue. If the user approves, submit using the GitHub MCP `create_issue` tool (preferred) or fall back to the CLI:

```bash
gh issue create --title "<title>" --body "<body>"
```

If neither MCP nor `gh` is available, present the final markdown for the user to paste manually.
