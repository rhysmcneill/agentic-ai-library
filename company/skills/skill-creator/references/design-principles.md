# Skill Design Principles

Core design principles for writing effective Agent Skills.

## Conciseness

Agents have limited context windows and charge per token. Every word in a skill costs time and accuracy.

**Rule:** Remove all conversational filler ("please", "here is how you", "this skill will").

```markdown
# Bad
This skill will help you deploy the application. Please make sure to read the instructions carefully.
First, you need to check the current status of the pods.
You can do this by running `kubectl get pods`.

# Good
## Deployment Process
1. Check pod status: `kubectl get pods`
```

## Degrees of Freedom

Agents get confused when presented with too many options or ambiguous instructions.

**Rule:** Reduce degrees of freedom. Provide exact commands, rigid paths, and deterministic decision trees.

```markdown
# Bad
Find the configuration file and update the memory limit to something appropriate for production.

# Good
1. Open `config/production.yaml`
2. Set `resources.limits.memory` to `4Gi`
```

## Progressive Disclosure

Loading a 2000-line skill file slows the agent down and dilutes the relevance of specific instructions.

**Rule:** Keep SKILL.md focused on core workflows and triggers. Push detailed domain knowledge into separate reference files that the agent can read *only if needed*.

```markdown
1. Detect the framework used in the project
2. If using Next.js, read `references/nextjs-deployment.md`
3. If using Vite, read `references/vite-deployment.md`
```

## Description as Trigger

Agents use the `description` field in the frontmatter to decide when to activate a skill. If the description is vague, the skill won't be used.

**Rule:** Write descriptions in the third person. Include specific "trigger phrases" that a user is likely to type. Do NOT include instructions or references in the description.

```yaml
# Bad
description: I help you fix bugs in the authentication flow.

# Good
description: Troubleshoots and fixes authentication bugs. Use when asked to "fix auth issue", "debug login", or "resolve authentication error".
```

## Imperative Voice

Skills are direct instructions from a lead engineer to a junior developer.

**Rule:** Use imperative voice (commands) instead of descriptive voice.

```markdown
# Bad
The agent should parse the log file and look for "OOMKilled" messages, which indicate memory issues.

# Good
1. Parse the log file
2. Search for "OOMKilled"
3. If found, report a memory issue
```

## Consistent Terminology

Using different words for the same concept confuses the agent.

**Rule:** Pick one term for each entity and use it consistently. Don't alternate between "API endpoint", "URL", "route", and "path" if they refer to the same thing. Define terms early if they are ambiguous.

## Avoid Duplication

Don't duplicate information that is already in general documentation or other skills.
If a rule applies to *all* skills in a repository, put it in `AGENTS.md`, not in individual `SKILL.md` files.

## Avoid Time-Sensitive Information

Don't hardcode version numbers, dates, or file paths that are likely to change frequently, unless you can provide a reliable script or command for the agent to discover the current value dynamically.

## Long Reference Files

When a reference file must be long (> 10k words):
1. **Provide an index:** Give the agent grep commands in `SKILL.md` to search the reference file instead of reading it entirely.
2. **Use structured data:** Format data as JSON or YAML so a script can parse it, rather than expecting the agent to read a massive Markdown table.
