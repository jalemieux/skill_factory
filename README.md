# curunir-skills

Skills for the [curunir](../curunir/) agent project.

## Skills

### write-skill

Teaches AI coding agents to create new skills. Give it a description of what you want ("build a skill for managing GitHub issues with the gh CLI") and it walks the agent through requirements gathering, doc research, SKILL.md generation, and smoke testing.

```
skills/write-skill/
├── SKILL.md                    # The skill itself
└── references/
    ├── template.md             # SKILL.md template + category heuristic table
    └── chub.md                 # Context Hub CLI reference (search → get → annotate)
```

## Inspired by

- [Thariq's "Lessons from Building Claude Code: How We Use Skills"](https://x.com/trq212/status/2033949937936085378) — the nine skill categories, writing descriptions for models, building gotcha sections, and the principle that skills should provide pre-written code the agent adapts rather than reconstructs.
- [Andrew Ng's Context Hub](https://x.com/AndrewYNg/status/2033577583200354812) — the idea that agents should pull curated API docs on demand rather than hallucinating APIs. Integrated as a reference doc for the research phase (`references/chub.md`).

## Usage

Load the `write-skill` skill in your agent environment, then ask it to create a skill:

> "Create a skill called `github-issues` that teaches the agent to manage GitHub issues using the `gh` CLI."

The agent will:
1. Identify the skill category and ask clarifying questions
2. Research docs (context hub, web search, or user-provided)
3. Generate SKILL.md with the right emphasis for the category
4. Smoke test: validate structure, load test, dry-run against a test scenario
