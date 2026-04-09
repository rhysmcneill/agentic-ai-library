---
name: skill-creator
description: Guides agents through the process of creating a new AI coding agent skill following the agentskills.io standard. Use when asked to "create a new skill", "build a skill", "write a skill", or "add a skill".
---

# Create a New Skill

## Step 1: Understand the Skill
Gather requirements before writing anything.

**Ask the user:**
1. What should this skill do? (one sentence)
2. When should an agent use it? (trigger phrases users would say)
3. What tools does the skill need? (Bash, file system tools, etc.)
4. Where should the skill live? (which group directory, e.g., `groups/<group>/skills/`)

**Determine the skill name:**
- Lowercase letters, digits, and hyphens only (`a-z`, `0-9`, `-`)
- 1-64 characters; must not start or end with `-`; no consecutive hyphens (`--`)
- Descriptive and unique among existing skills
- Prefer action-oriented names: `processing-pdfs`, `fix-issue`, `code-review`
- Check the target skills directory to avoid name collisions

**Choose a complexity tier:**

| Tier | Structure | Use When |
|------|-----------|----------|
| **Simple** | `SKILL.md` only | Self-contained instructions under ~200 lines |
| **With references** | `SKILL.md` + `references/` | Domain knowledge that agents load conditionally |
| **With scripts** | `SKILL.md` + `scripts/` | Workflow automation needing Python/Bash scripts |
| **Full** | All of the above | Complex skills with automation and domain knowledge |

Read `references/design-principles.md` for guidance on keeping skills focused and concise.

## Step 2: Plan the Skill
Analyze how each use case would be executed from scratch. Identify what reusable resources would help when executing these tasks repeatedly.

For each concrete example, ask:
1. What code would be rewritten every time? → candidate for `scripts/`
2. What documentation is needed to inform decisions? → candidate for `references/`
3. What templates or assets are used in output? → candidate for `assets/`

Example analysis:
- "Rotate a PDF" → rotating requires rewriting the same code → `scripts/rotate_pdf.py`
- "Query project database" → need table schemas each time → `references/schema.md`
- "Build a standard frontend component" → same boilerplate code → `assets/component-template/`

## Step 3: Study Existing Skills
Before writing, study 1-2 existing skills that match the chosen tier. Look for skills in the target repository to understand local conventions.

Read `references/skill-patterns.md` for concrete examples of each tier.

Also read `AGENTS.md` at the repository root and the target domain for repo-specific conventions that the skill should follow.

## Step 4: Write the SKILL.md
Create `<skill-directory>/<name>/SKILL.md`.

### Frontmatter
The YAML frontmatter **must** be the first thing in the file. No comments or blank lines before `---`.

```yaml
---
name: <skill-name>
description: <what it does>. Use when <trigger phrases>. <key capabilities>.
---
```

**Required fields:**
- `name` — must match the directory name exactly
- `description` — up to 1024 chars, no angle brackets (`<` or `>`); include trigger keywords that help agents match user intent

**Optional fields:**
- `license` — specifies the license applied to the skill (e.g., name or path to a file)
- `compatibility` — specific environment requirements (max 500 chars, e.g., `Requires git, docker`)
- `metadata` — arbitrary map from string keys to string values for additional properties
- `allowed-tools` — space-delimited list of allowed tools (e.g., `Bash(git:*) Read`); omit to allow all tools

### Description Guidelines
The description is the **primary trigger mechanism** — it determines when agents activate the skill. All "when to use" information belongs here, not in the body.

**Write in third person:**
- Good: "Processes Excel files and generates reports. Use when..."
- Bad: "I can help you process Excel files" or "You can use this to..."

**Include natural trigger phrases:**
```yaml
# Good — specific triggers users would actually say
description: Security code review for vulnerabilities. Use when asked to "security review", "find vulnerabilities", "check for security issues", "audit security".

# Bad — too vague, no trigger phrases
description: A helpful skill for code quality.
```

**Pattern:** `<What it does>. Use when <trigger phrases>. <Key capabilities>.`

### Body Guidelines
Write the body in **imperative voice** — these are instructions, not documentation.

| Do | Don't |
|----|-------|
| "Read the file and extract..." | "This skill reads the file and extracts..." |
| "Report only HIGH confidence findings" | "The agent should report only HIGH confidence findings" |
| "Ask the user which option to use" | "You may want to ask the user..." |

**Structure:**
1. Start with a one-line summary of what the skill does
2. Organize steps with `## Step N: Title` headings
3. Use tables for decision logic and mappings
4. Include concrete examples of expected output
5. End with validation criteria or exit conditions

For workflow and output patterns, read:
- `references/workflow-patterns.md` — sequential workflows, feedback loops, plan-validate-execute

**Size limits:**
- Keep SKILL.md under **500 lines**
- If approaching the limit, move reference material to `references/` files
- Load reference files conditionally based on context (not all at once)

**Use consistent terminology** — pick one term for each concept and stick with it throughout.

### Attribution
If the skill is based on or adapted from external sources, add an HTML comment **after** the frontmatter closing `---`.

## Step 5: Create Supporting Files

### What NOT to Include
Do not create extraneous documentation or auxiliary files:
- README.md, INSTALLATION_GUIDE.md, QUICK_REFERENCE.md, CHANGELOG.md

### References (`references/`)
Use for domain knowledge the agent loads conditionally.

Reference from SKILL.md with:
```markdown
Read `references/topic-a.md` for details on [topic].
```

Guidelines:
- Keep each reference file focused on one topic
- Keep references **one level deep** from SKILL.md (no nested reference chains)
- For files over 100 lines, add a table of contents at the top
- Information should live in either SKILL.md or references, not both

### Scripts (`scripts/`)
Use for workflow automation. Try to use simple Python or bash scripts if necessary. Provide clear documentation on arguments and expected execution path. Use `uv run` if executing Python scripts.

## Step 6: Validate the Skill
Run the official Python validation tool to check for format and required fields. Create and use a local virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate
pip install skills-ref
agentskills validate <path/to/skill-directory>
```

Fix any errors and re-run until validation passes.

## Step 7: Verify
Run through this checklist before finishing:

- [ ] `name` matches directory name, only lowercase/digits/hyphens
- [ ] `description` is under 1024 characters, third person, includes triggers
- [ ] SKILL.md is under 500 lines, imperative voice
- [ ] Uses conditional reference loading

<!--
Based on skill-creator by getSentry:
https://github.com/getsentry/skills/tree/main/plugins/sentry-skills/skills/skill-creator
-->
