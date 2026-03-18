# Curunir Skills Specification

Skills are **markdown-based instruction sets** that extend the curunir agent's capabilities. They are loaded on-demand and teach the agent how to use external APIs, tools, and workflows.

> "Skills are prompts. Complex workflows are captured as markdown instructions the agent loads on demand."

## Core Principles

- **Declarative** — defined as markdown files with YAML frontmatter
- **Lazy-loaded** — not in the system prompt by default; loaded only when needed via `load_skill` tool
- **Composable** — can reference/depend on other skills
- **API-first** — most skills teach bash/curl patterns, not new Python tools

## Directory Structure

A skill is a directory containing at minimum `SKILL.md`, and optionally supporting files:

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

**Naming:** Skill names use lowercase-kebab-case (e.g., `web-search`, `email-send`). The directory name IS the skill name — the loader matches on `*/SKILL.md`.

**When to add supporting files:**

- Reference data too large to inline in SKILL.md → `references/`
- Reusable scripts the agent should execute, not reconstruct → `scripts/`
- Boilerplate the agent should copy/adapt → `templates/`
- Sample data that clarifies expected formats → `examples/`

SKILL.md references supporting files explicitly (e.g., "Read `references/api-params.md` for the full parameter table"). The agent discovers supporting files through SKILL.md, not by scanning the directory.

## SKILL.md Format

```markdown
---
name: {skill-name}
description: "{trigger condition — when should the agent load this?}"
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

Sections scale to complexity — a simple API wrapper might be 50 lines, a multi-step workflow might be 90+. Read existing skills for calibration.

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Machine-readable identifier, lowercase-kebab-case |
| `description` | Yes | Trigger condition — when should the agent load this skill |
| `tools` | No | Comma-separated opt-in tools to unlock (e.g., `attach`) |

Missing `name` or `description` → skill is skipped by the manifest builder.

### Writing Good `description` Fields

The `description` determines whether the agent recognizes when to load the skill. Write it for **model discovery**, not humans. Describe the **trigger condition**.

- Good: `"Use when processing Slack catch-ups, meeting notes, or incident summaries to extract durable knowledge"` — tells the agent WHEN
- Bad: `"A skill for extracting learnings from text"` — vague, doesn't trigger on specific situations

### The `tools` Frontmatter Field

Skills can declare opt-in tools via `tools`. When the agent loads a skill with `tools: attach`, that tool becomes available for the session. Available opt-in tools:

- `attach` — attach a file to the response (used by `deep-research` for PDF reports)
- `delegate` — delegate work to another agent

Only declare `tools` if the skill genuinely needs a tool not in the default set. Most skills don't need this.

## How Skills Are Loaded

1. **At startup**: `build_skill_manifest()` scans `skills/*/SKILL.md`, extracts frontmatter, builds a markdown table shown in the system prompt
2. **On demand**: Agent uses the `load_skill` tool with a skill name → receives full SKILL.md content
3. **Tool activation**: If skill declares `tools:` in frontmatter, those tools are added to the session for its lifetime

## Writing Skills — Core Guidance

Based on lessons from Anthropic's Claude Code team (Thariq's "Lessons from Building Claude Code: How We Use Skills"):

1. **Don't state the obvious** — the agent already knows how to code. Focus on org-specific knowledge, API quirks, and things that change default behavior.
2. **Write descriptions for models** — the `description` field determines skill discovery. Describe the trigger condition, not the contents.
3. **Build gotcha sections** — capture common failure points. The Common Mistakes section is the highest-value section in any skill.
4. **Provide pre-written code** — curl commands, scripts, jq patterns. The agent should compose and adapt, not reconstruct from scratch.
5. **Progressive disclosure** — SKILL.md is the entry point. Large references, scripts, and schemas go in supporting files within the skill directory.
6. **Provide flexibility** — give enough info for varied situations, not just the happy path. Avoid overly rigid step-by-step scripts.
7. **Identify the category** — knowing the skill type shapes where to invest depth (see Category Heuristic).

## Skill Categories

Nine recurring categories shape how skills should be structured:

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

This is a heuristic, not a rigid rule. Adapt based on actual complexity.

## Constraints

- One `SKILL.md` per subdirectory
- Frontmatter parser is simple key-value (`key: value`), strips surrounding quotes
- Skills can depend on other skills (e.g., `deep-research` loads `web-search` first)
- Opt-in tools remain active for the session lifetime

## Key Source Files (in curunir)

| File | Purpose |
|------|---------|
| `src/skills.py` | Discovery, loading, frontmatter parsing |
| `src/agent/system_prompt.py` | Builds system prompt with skill manifest |
| `src/agent/agent.py` | Agent loop, tool calling, skill tool activation |
| `src/tools/skill_tool.py` | `load_skill` tool executor |
| `src/tools/schemas.py` | Tool schema definitions (default + opt-in) |
| `src/config.py` | `AgentConfig` with `skills_dir` path |
