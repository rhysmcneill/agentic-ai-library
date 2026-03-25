# Skill Patterns

Common patterns for structuring Agent Skills, classified by complexity tier.

## Simple: SKILL.md Only

The simplest tier is just a `SKILL.md` file. Use this for straightforward workflows that require no domain knowledge or automation. The instructions must be under ~200 lines to avoid overwhelming the agent.

```
<skill-name>/
└── SKILL.md
```

**Works best for:**
- Checklist reminders (e.g., "how to properly format a PR")
- Simple boilerplate generation
- Wrapper scripts for a single, easy-to-use CLI

## Workflow: SKILL.md + Scripts

When a workflow involves repetitive, deterministic tasks or complex parsing, write a Python/Bash script in `scripts/` and have the agent call it.

```
<skill-name>/
├── SKILL.md
└── scripts/
    └── automation.py
```

**Why do this?**
- Agents are bad at executing 15-step deterministic processes flawlessly.
- Automation scripts execute deterministically and instantly.
- Scripts can output structured JSON, which agents parse perfectly.

## Domain Expert: SKILL.md + References

When a workflow requires significant domain knowledge (e.g., "how this legacy system is architected", "the rules for our specific deployment process"), push that knowledge into `references/`.

```
<skill-name>/
├── SKILL.md
└── references/
    ├── architecture.md
    └── common-errors.md
```

The `SKILL.md` acts as an index, telling the agent *when* to consult which reference file.

---

# Anti-Patterns (What NOT to do)

Avoid these common mistakes when authoring skills.

## Over-long SKILL.md
**Problem:** The `SKILL.md` file is 800 lines long, containing workflow steps, reference tables, and troubleshooting guides.
**Why it's bad:** The agent forgets instructions, hallucinates, and wastes tokens loading the file for simple queries.
**Fix:** Move reference data to `references/` and load it conditionally.

## Missing Trigger Keywords
**Problem:** The frontmatter description is vague (e.g., `description: Helps with Docker.`)
**Why it's bad:** The agent doesn't know *when* to use it versus a general shell command.
**Fix:** Add triggers: `description: ... Use when asked to "build container", "fix dockerfile", or "deploy image".`

## Trigger Info in Body Instead of Description
**Problem:** The `SKILL.md` body lists "When to use this skill...".
**Why it's bad:** The agent only reads the body *after* it has already decided to activate the skill.
**Fix:** Move all trigger/activation criteria to the `description` in the frontmatter.

## Unconditional Reference Loading
**Problem:** The `SKILL.md` says "Always read `references/arch.md` and `references/api.md` before starting."
**Why it's bad:** Wastes tokens and context window space if the user's request only involves the API and not the architecture.
**Fix:** "If the user asks about the API, read `references/api.md`."

## Extraneous Files
**Problem:** The skill dir includes `README.md`, `.gitignore`, `tests/`, etc.
**Why it's bad:** An Agent Skill is not a complete Python package for humans. Extraneous files confuse the agent.
**Fix:** Delete everything except `SKILL.md`, `scripts/`, `references/`, and `assets/`.

## First/Second Person Descriptions
**Problem:** The frontmatter says `description: I can help you fix bugs.`
**Why it's bad:** The description is parsed by the agent orchestrator. It expects a tool description.
**Fix:** Use third person: `description: Helps fix bugs...`
