---
name: create-pr
description: Creates a pull request for an open-source repository following the project's contribution guidelines, PR template, and CI requirements. Use when asked to "create a PR", "submit a pull request", "open a PR", "contribute a fix", "send a patch", or "submit this change upstream".
---

# Create a Pull Request for an Open-Source Repository

Prepare and submit a well-structured pull request that follows the target project's conventions and passes all required checks.

## Tools

Prefer the GitHub MCP server tools when available. Fall back to the `gh` CLI when MCP is not configured.

| Action | MCP tool | CLI fallback |
|--------|----------|--------------|
| Fork repository | `fork_repository` | `gh repo fork` |
| Create branch | `create_branch` | `git checkout -b` |
| Read repo files / templates | `get_file_contents` | `gh api` or clone + read |
| Create pull request | `create_pull_request` | `gh pr create` |
| Check PR status | `get_pull_request_status` | `gh pr checks` |
| Search for related issues | `search_issues` | `gh issue list --search` |

## Step 1: Verify Contribution Prerequisites

Before writing any code, confirm these prerequisites:

1. **CONTRIBUTING.md** — read it fully. Note branch naming conventions, commit style, CLA/DCO requirements, and any setup instructions.
2. **Fork vs. direct push** — determine whether the project accepts PRs from forks (most OSS) or from branches in the main repo.
3. **Related issue** — check if the project requires an issue before a PR. If so, confirm one exists or create it first using the `create-issue` skill.
4. **Assignment** — some projects ask contributors to comment on the issue to claim it before starting work. If that's the case, confirm the user has done so.

If any prerequisite is missing, **stop** and inform the user before proceeding.

## Step 2: Set Up the Working Branch

### If the project uses fork-and-PR (most common):

```bash
# Ensure the fork exists (gh handles creation if needed)
gh repo fork --clone=false

# Verify remotes
git remote -v

# Sync with upstream
git fetch upstream
git checkout -b <branch-name> upstream/main
```

### If the project accepts branches on the main repo:

```bash
git fetch origin
git checkout -b <branch-name> origin/main
```

**Branch naming rules:**
- Follow the project's convention if documented (e.g., `fix/issue-123`, `feature/add-retry`).
- If no convention exists, use: `<type>/<short-description>` (e.g., `fix/pagination-offset`, `feat/add-retry-logic`).
- Include the issue number when one exists (e.g., `fix/123-pagination-offset`).

## Step 3: Implement the Change

Make the changes needed to address the issue or feature. Follow these principles:

1. **Minimal diff** — change only what is necessary. Do not refactor unrelated code, fix unrelated linting issues, or update formatting outside the affected area.
2. **Match existing style** — use the same indentation, naming, and patterns as the surrounding code. Run the project's linter/formatter if one is configured.
3. **Add or update tests** — if the project has tests, add coverage for the change. Match the existing test framework and patterns.
4. **Update documentation** — if the change affects user-facing behaviour, update relevant docs (README, API docs, inline comments).

## Step 4: Validate Locally

Before committing, run the project's validation suite:

```bash
# Look for common task runners and execute them
# Makefile → make test, make lint
# package.json → npm test, npm run lint
# go.mod → go test ./..., golangci-lint run
# Cargo.toml → cargo test, cargo clippy
# pyproject.toml → pytest, ruff check
```

1. All existing tests must still pass.
2. New tests must pass.
3. Linter must produce no new warnings on changed files.
4. If the project uses type checking (mypy, tsc, etc.), that must pass too.

If any check fails, fix the issue before proceeding. Do not submit a PR with known failures.

## Step 5: Commit the Changes

Follow the project's commit conventions:

| Convention | How to detect |
|------------|---------------|
| Conventional Commits | Look for `feat:`, `fix:` in recent commit history |
| DCO sign-off | CONTRIBUTING.md mentions "Developer Certificate of Origin" or `Signed-off-by` |
| Signed commits (GPG) | CONTRIBUTING.md mentions signed commits or the repo requires them |
| Squash preference | Check if the project squashes on merge (single-commit PRs are cleaner) |

If the project uses DCO, add the sign-off flag:

```bash
git commit -s -m "<message>"
```

Keep commits atomic — one logical change per commit. If the project squashes on merge, a single commit is fine.

## Step 6: Locate the PR Template

Check for PR templates before drafting:

1. `.github/PULL_REQUEST_TEMPLATE.md` — single template.
2. `.github/PULL_REQUEST_TEMPLATE/` — multiple templates (choose the appropriate one).
3. `CONTRIBUTING.md` — may describe PR format requirements.

If a template exists, follow its structure exactly.

## Step 7: Draft the PR

If no template was found, use this structure:

```markdown
### Summary
<One paragraph: what this PR does and why>

### Related Issue
Fixes #<issue-number>
<!-- or: Closes #<issue-number>, Relates to #<issue-number> -->

### Changes
- <Bullet list of specific changes made>

### Testing
- <How the changes were tested>
- <Any manual testing steps for reviewers>

### Checklist
- [ ] Tests added/updated
- [ ] Documentation updated (if applicable)
- [ ] Linter passes with no new warnings
- [ ] Commit message follows project conventions
```

**Writing rules:**
- Title should match the project's convention (often mirrors the commit message format).
- Link to the related issue using GitHub keywords (`Fixes #123`, `Closes #123`) so it auto-closes on merge.
- Be specific about what changed and why — reviewers who don't have your context need to understand the motivation.
- If the change is visual, include before/after screenshots.
- If the change is a breaking change, call it out prominently.

## Step 8: Push and Create the PR

Present the complete PR (title + body) to the user for review before submission.

Ask the user:
1. Does this accurately describe the change?
2. Should anything be added or removed?
3. Ready to push and create the PR?

Wait for explicit approval, then push the branch and submit using the GitHub MCP `create_pull_request` tool (preferred) or fall back to the CLI:

```bash
git push -u origin <branch-name>

gh pr create --title "<title>" --body "<body>"
```

If neither MCP nor `gh` is available, push the branch and present the PR markdown for the user to paste manually on the web UI.

## Step 9: Post-Submission

After the PR is created:

1. **Report the PR URL** to the user.
2. **Monitor CI** — use `get_pull_request_status` (MCP) or `gh pr checks` to check CI results. If checks fail, investigate and fix promptly. A PR with failing CI is unlikely to be reviewed.
3. **Respond to feedback** — use `get_pull_request_comments` (MCP) or `gh pr view` to check for reviewer comments. Remind the user to be prepared to iterate.
