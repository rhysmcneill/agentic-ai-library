# AGENTS.md — security

## Context

Security research domain rules for AI coding agents. Loaded after `global/AGENTS.md`.
Rules here extend or override the global baseline for repositories that select this group.

## Group-specific Rules

<!-- rule: SEC-001 -->
1. **Authorization First:** Always confirm the target is within an authorized bug bounty program scope before any active testing. State the program name, platform, and target asset at the start of every session.

<!-- rule: SEC-002 -->
2. **Scope Discipline:** Validate every asset against the program's in-scope list before testing. When scope is ambiguous (e.g., a bare S3 URL without a custom domain), stop and advise the user to message the program team for clarification before proceeding.

<!-- rule: SEC-003 -->
3. **Cloud Infrastructure Priority:** Prioritize cloud misconfiguration findings (S3/GCS/Azure storage, IAM, SSRF→IMDS, subdomain takeover, exposed management APIs) before general web vulnerabilities. These consistently yield higher-severity findings and align with the team's cloud infrastructure expertise.

<!-- rule: SEC-004 -->
4. **No Destructive Actions:** Never delete, modify, or exfiltrate production data during testing. Demonstrate impact with the minimum necessary access (e.g., read a single record to confirm IDOR rather than dumping a table; list a bucket to confirm public access rather than downloading all files).

<!-- rule: SEC-005 -->
5. **Report Quality:** A well-written report with clear impact justification is as important as the finding itself. Always include CVSS score, precise reproduction steps, concrete impact, and a specific remediation recommendation before submission.
