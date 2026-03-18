# Design: write-skill

A curunir skill that teaches the agent to create new skills.

## Identity

```yaml
name: write-skill
description: "Create a new curunir skill — gathers requirements, finds docs, generates SKILL.md, and smoke tests it"
```

Loaded when the agent is asked to create, write, or build a new skill for curunir.

## Output

A skill directory at `{skills_dir}/{skill-name}/`, containing at minimum `SKILL.md` and optionally supporting files.

**Naming:** Skill names use lowercase-kebab-case (e.g., `web-search`, `email-send`). The directory name IS the skill name — the loader matches on `*/SKILL.md`.

**Conflict check:** Before writing, check whether `{skills_dir}/{skill-name}/` already exists. If it does, ask the user whether to overwrite or choose a different name. This skill is for creation, not updating existing skills.

## Workflow

### Phase 1 — Requirements

1. User describes the skill they want.
2. Agent identifies the **skill category** (see Category Heuristic below) to shape template emphasis.
3. Agent asks 1-2 clarifying questions: scope, which operations, any gotchas.
4. Agent asks for (or proposes) a **success criteria / test scenario** the skill can be verified against.

### Phase 2 — Research

5. If context-hub (`chub`) is installed, try `chub search` for curated docs. If `chub` is not installed or returns an error, skip to step 6. Do not attempt to install it.
6. If no chub docs or insufficient, web search for API docs / references.
7. If user provided docs directly, use those.
8. Read 1-2 existing skills from `{skills_dir}/` as style reference. If no existing skills are found, use the template and core guidance as the sole reference.

### Phase 3 — Generate

9. Assess whether the skill needs supporting files (see Directory Structure below).
10. Generate SKILL.md using the template with embedded guidance (see Template below).
11. Generate any supporting files (scripts, references, templates, examples).
12. Write to `{skills_dir}/{skill-name}/`.

### Phase 4 — Smoke Test

13. **Structural validation** — frontmatter parses correctly, `name` and `description` present, file at correct path.
14. **Load test** — use the `load_skill` tool with the new skill's name. Verify it returns the skill content, not "Skill not found: {name}".
15. **Dry-run against success criteria** — load the generated skill and walk through its instructions for the test scenario. Execute any read-only steps. For skills that call external APIs, compose the commands but do not execute them. For skills that only produce output (reports, analysis), run the full workflow against test data. Stop before any mutating side effects.
16. Report pass/fail to user. If fail, fix and re-test.

## Template (with embedded generation guidance)

```markdown
---
name: {skill-name}
description: "{trigger condition — when should the agent load this? Write for model discovery, not humans}"
tools: {optional — comma-separated opt-in tools to unlock when skill loads}
---

# {Skill Title}

{1-2 sentences: what this does. Don't explain things the agent already knows —
focus on what's specific to THIS tool/API/workflow.}
{Required env vars, prerequisites, or dependent skills.}

## Usage

{Pre-written code blocks — curl commands, scripts, jq patterns.
The agent should be able to copy and adapt these, not reconstruct from scratch.
Cover the core operations, not every possible option.}

## Examples

{1-2 concrete end-to-end examples.
Show varied situations — not just the happy path.
Give the agent enough to handle real variation.}

## Parameters / Reference

{Optional — only if there's reference data (API params, config options, schemas).
For large references, put in a separate file in the skill directory
and tell the agent to read it on demand. Progressive disclosure.}

## Tips

{Practical guidance. Short. Things that change default behavior.
Skip anything the agent would already do.}

## Common Mistakes

{Highest-value section. Capture specific failure modes:
- What goes wrong
- Why it goes wrong
- What to do instead
Update this section as new gotchas are discovered.}
```

Sections scale to complexity. The agent reads existing skills in `{skills_dir}/` for calibration on length and density.

### The `tools` frontmatter field

Skills can declare opt-in tools they need via the `tools` field. When the agent loads a skill with `tools: attach`, the `attach` tool becomes available for the session. Available opt-in tools:

- `attach` — attach a file to the response (used by `deep-research` for PDF reports)
- `delegate` — delegate work to another agent

Only declare `tools` if the generated skill genuinely needs a tool that isn't in the default set. Most skills (especially API wrappers) don't need this.

### Writing good `description` fields

The `description` determines whether the agent recognizes when to load the skill. It should describe the **trigger condition**, not summarize contents.

- Good: `"Use when processing Slack catch-ups, meeting notes, or incident summaries to extract durable knowledge"` — tells the agent WHEN
- Bad: `"A skill for extracting learnings from text"` — vague, doesn't trigger on specific situations

## Directory Structure

A skill can be more than SKILL.md:

```
skills/{skill-name}/
├── SKILL.md              # Always required — entry point
├── scripts/              # Optional — pre-written scripts the agent runs
│   └── search.sh
├── references/           # Optional — large reference docs, schemas, param tables
│   └── api-params.md
├── templates/            # Optional — boilerplate/scaffolding files
│   └── config.json
└── examples/             # Optional — example inputs/outputs
    └── sample-request.json
```

**When to add supporting files:**

- Reference data too large to inline in SKILL.md → `references/`
- Reusable scripts the agent should execute, not reconstruct → `scripts/`
- Boilerplate the agent should copy/adapt → `templates/`
- Sample data that clarifies expected formats → `examples/`

SKILL.md references supporting files explicitly (e.g., "Read `references/api-params.md` for the full parameter table"). The agent discovers supporting files through SKILL.md, not by scanning the directory.

The `write-skill` agent decides during generation whether supporting files are needed based on complexity. Simple API wrappers → SKILL.md only. Complex workflows → multi-file.

## Category Heuristic

The agent identifies the skill category early in requirements to shape where to invest depth:

| Category | Template emphasis |
|----------|------------------|
| Library / API Reference | Heavy on Usage + Parameters, pre-written code blocks |
| Product Verification | Heavy on Examples, test patterns, pass/fail criteria |
| Data Fetching & Analysis | Heavy on Usage + output parsing (jq, formatting) |
| Business Process Automation | Heavy on workflow steps, guard rails |
| Code Scaffolding & Templates | Heavy on Examples with varied inputs |
| Code Quality & Review | Heavy on Tips + Common Mistakes (the rules) |
| CI/CD & Deployment | Heavy on Usage + Common Mistakes (destructive action guards) |
| Runbooks | Heavy on step-by-step workflow, multiple tool coordination |
| Infrastructure Operations | Heavy on Common Mistakes (guardrails for destructive actions) |

This is a heuristic, not a rigid rule. The agent adapts based on actual complexity.

## Core Guidance (from Thariq's "Lessons from Building Claude Code: How We Use Skills")

These principles are embedded in the template comments and enforced during generation:

1. **Don't state the obvious** — the agent already knows how to code. Focus on org-specific knowledge, API quirks, and things that change default behavior.
2. **Write descriptions for models** — the `description` field determines skill discovery. Describe the trigger condition.
3. **Build gotcha sections** — capture common failure points. Highest-value section.
4. **Provide pre-written code** — curl commands, scripts, jq patterns. Agent composes, not reconstructs.
5. **Progressive disclosure** — SKILL.md is the entry point. Large references go in supporting files.
6. **Provide flexibility** — enough info for varied situations, not just the happy path.
7. **Identify the category** — shapes template emphasis.

## Research Strategy

Priority order for gathering information:

1. **User-provided docs** — highest fidelity, use directly
2. **Context Hub** (`chub search` / `chub get`) — curated, versioned API docs (if installed; skip if unavailable)
3. **Web search** — fallback for APIs not in chub
4. **Agent's own knowledge** — lowest priority, supplement only

## Decisions

- Output path is `{skills_dir}/{skill-name}/` — relative to the project, not hardcoded
- Smoke test includes structural validation, load test, and dry-run against user-approved success criteria
- Agent proposes test scenario, user can override
- Supporting files are generated when complexity warrants, not by default
- Existing skills in `{skills_dir}/` are read as live style references, not embedded in the skill
