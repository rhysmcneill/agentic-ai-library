# Ticket tracking for Critical/High findings

This skill never assumes a specific ticketing system — Jira, Linear, GitHub Issues, Azure DevOps, or anything else. Detect what's available in this session and adapt to it; don't hardcode a vendor or a tool name anywhere in this flow.

## 1. Detect what's available

- Check whether a ticketing tool is already usable in this session (a connected Jira/Linear/GitHub/other MCP integration, or similar). If one is, use it.
- If none is connected, ask the user directly: "Want tracking tickets created for the Critical/High items? If so, what do you use (Jira, Linear, GitHub Issues, something else), and is there a tool or CLI I can use, or would you rather I just hand you a list to raise yourself?"
- If the user doesn't use any ticketing system, or declines, skip this step entirely — it's a convenience layer on top of the report, never a prerequisite for the go/no-go verdict.

## 2. Only offer this for Critical/High

Don't proactively offer to ticket Medium/Low findings here — those already have a home in the report's "Open items for follow-up" section. If the user wants those ticketed too, let them ask for it; don't expand scope on your own.

## 3. Ask for destination specifics before creating anything

Never guess a project, board, or parent issue. Ask for:

- **Project/space** the tickets belong in (e.g. a Jira project key, a Linear team, a GitHub repo).
- **Issue type**, if the system distinguishes them (bug, task, story, etc.).
- **Parent to link under**, if their workflow uses one (epic, initiative, story) — optional; don't force a parent on someone whose workflow doesn't use one.

## 4. One ticket per finding, not one umbrella ticket

Create a separate ticket per Critical/High row so each is independently assignable, trackable, and closable on its own schedule. Title it from the finding's own description; body = the finding detail plus its suggested remediation, plus a pointer back to this prep report (its path, once written) so whoever works the ticket has full context without re-deriving it from scratch.

## 5. Record the result back in the report, not in a side list

After a ticket is created, write its key/URL into the `Tracking` column of the relevant findings table (see `references/report-template.md`) — the table is the single source of truth for "is this tracked, and where," not a separate list that can drift out of sync with it.

## 6. Nothing gets ticketed silently

Only create tickets after the user has explicitly said yes to this batch. If a row doesn't get a ticket (user declined, or ticketing isn't in play at all), leave its `Tracking` cell as `—`, not blank — blank reads as "forgotten to fill in," `—` reads as "deliberately not ticketed."

## Why this matters for execution

`eks-upgrade-execute` reads this report before acting and, in its close-out step, reminds the user which tracking tickets raised here should now be closed. It can only do that if tickets actually got created and logged in the table — this step is what makes that link real instead of aspirational.
