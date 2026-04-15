---
name: create-pr
description: Creates a pull request for an infrastructure repository following the project's branch strategy, PR template, and CI requirements. Use when asked to "create a PR", "submit a pull request", "open a PR", "raise a PR for this change", or "push and create a PR". Supports Terramate, Helm, Terraform, and ArgoCD workflows.
---

# Create a Pull Request for an Infrastructure Repository

Prepare and submit a well-structured pull request that follows the project's conventions and passes all required checks.

## Tools

Prefer the GitHub MCP server tools when available. Fall back to the `gh` CLI when MCP is not configured.

| Action | MCP tool | CLI fallback |
|--------|----------|--------------|
| Create branch | `create_branch` | `git checkout -b` |
| Read repo files / templates | `get_file_contents` | `gh api` or local read |
| Create pull request | `create_pull_request` | `gh pr create` |
| Check PR status | `get_pull_request_status` | `gh pr checks` |
| Search for related issues | `search_issues` | `gh issue list --search` |

## Step 1: Verify Prerequisites

Before writing any code, confirm these prerequisites:

1. **CONTRIBUTING.md** — if one exists, read it fully. Note branch naming conventions, commit style, and any required approvals.
2. **Branch protection** — determine whether the target branch (`main`/`master`) has required reviewers, status checks, or merge restrictions.
3. **Related ticket** — check if the project requires a Jira ticket or issue before a PR. If so, confirm one exists.

If any prerequisite is missing, **stop** and inform the user before proceeding.

## Step 2: Set Up the Working Branch

```bash
git fetch origin
git checkout -b <branch-name> origin/main
```

**Branch naming rules:**
- Follow the project's convention if documented.
- If no convention exists, use: `<type>/<ticket-id>-<short-description>` (e.g., `feat/JI-1234-add-vpc-peering`, `fix/JI-5678-helm-values`).
- Always include the ticket ID when one exists.

## Step 3: Implement the Change

Follow these principles:

1. **Minimal diff** — change only what is necessary. Do not refactor unrelated code or fix unrelated linting issues.
2. **Match existing style** — use the same indentation, naming, and patterns as the surrounding code. Run the project's linter/formatter if one is configured.
3. **Do not edit generated files** — if the project uses Terramate code generation, edit the source templates and run `terramate generate`.
4. **Update documentation** — if the change affects behaviour, update relevant docs (README, runbooks, inline comments).

## Step 4: Validate Locally

Run the appropriate validation suite for the affected domain(s):

| Domain | Validation commands |
|--------|-------------------|
| Terramate | `terramate generate`, `terramate run -- terraform fmt -check`, `terramate run -- terraform validate` |
| Terraform (standalone) | `terraform fmt -check`, `terraform validate`, `terraform plan` |
| Helm | `helm lint <chart-path>`, `helm template <chart-path>` |
| ArgoCD | Validate Application manifests point to valid paths/revisions |
| Kubernetes YAML | `kubectl apply --dry-run=client -f <file>` |

1. All existing checks must still pass.
2. Linter must produce no new warnings on changed files.
3. If a `terraform plan` is required, confirm the plan output looks correct and contains no unexpected changes.

If any check fails, fix the issue before proceeding. Do not submit a PR with known failures.

## Step 5: Commit the Changes

Use the `commit` skill if available in this project. Otherwise, follow Conventional Commits:

```
<type>[optional scope]: <description>

[optional body]

Refs: <Ticket-ID>
Co-Authored-By: <Agent Name> <Agent Email>
```

Keep commits atomic — one logical change per commit. If the project squashes on merge, a single commit is acceptable.

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

### Related Ticket
Refs: <Ticket-ID>

### Changes
- <Bullet list of specific changes made>

### Validation
- <Which validation commands were run and their results>
- <terraform plan summary, helm lint output, etc.>

### Checklist
- [ ] Linter/formatter passes with no new warnings
- [ ] Validation commands pass (`terraform validate`, `helm lint`, etc.)
- [ ] No secrets, tokens, or credentials included in the diff
- [ ] Commit message follows project conventions
- [ ] Documentation updated (if applicable)
```

**Writing rules:**
- Title should match the project's convention (often mirrors the commit message format, e.g., `feat(vpc): add peering to shared-services`).
- Link to the related ticket.
- Be specific about what changed and why — reviewers who don't have your context need to understand the motivation.
- Include `terraform plan` summaries or `helm diff` output when relevant, as these help reviewers assess impact.
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
