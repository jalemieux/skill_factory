# SKILL.md Template

Generate this structure. Scale each section to the skill's complexity.

**Core guidance to embed:** Don't state the obvious. Write descriptions for models (trigger conditions, not summaries). Build gotcha sections. Provide pre-written code the agent copies and adapts. Use progressive disclosure — large references go in supporting files. Provide flexibility for varied situations, not just the happy path.

```markdown
---
name: {skill-name}
description: "{trigger condition — when should the agent load this? Describe WHEN, not WHAT}"
tools: {optional — comma-separated opt-in tools, only if genuinely needed}
dependencies: {optional — list of CLI tools the skill requires, e.g. [gh, jq]}
---

# {Skill Title}

{1-2 sentences: what this does. Skip things the agent already knows.
Required env vars, prerequisites, or dependent skills.}

## Usage

{Pre-written code blocks — curl commands, scripts, jq patterns.
The agent copies and adapts these, not reconstructs from scratch.
Cover the core operations, not every possible option.}

## Examples

{1-2 concrete end-to-end examples.
Show varied situations — not just the happy path.}

## Parameters / Reference

{Optional — only if there's reference data (API params, config options, schemas).
For large references, put in a separate file and tell the agent to read it on demand.}

## Tips

{Practical guidance. Short. Things that change default behavior.
Skip anything the agent would already do.}

## Common Mistakes

{Highest-value section. Capture specific failure modes:
- What goes wrong
- Why it goes wrong
- What to do instead}
```

## Dependencies Field

The optional `dependencies` frontmatter field declares CLI tools the skill needs. The installation workflow (see `references/installation.md`) uses this to install missing tools.

**Simple — CLI tools only:**

```yaml
dependencies: [gh, jq]
```

**Complex dependencies** (MCP servers, version constraints, tools needing special install instructions) go in a `## Dependencies` body section instead of frontmatter:

```markdown
## Dependencies

- `gh` — GitHub CLI
- `@anthropic-ai/mcp-server-slack` — MCP server, run via `npx`
  - scope: project
  - env: { SLACK_BOT_TOKEN: "...", SLACK_TEAM_ID: "..." }
```

Use frontmatter for simple CLI deps, body section for complex cases. Both can coexist — frontmatter for quick tools, body section for detailed setup.

## Category Heuristic

Identify the category early to shape where to invest depth:

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
