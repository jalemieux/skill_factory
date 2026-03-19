# skill_factory

A project for building and managing AI agent skills. Born from the need to reliably add skills to [curunir](https://github.com/jalemieux/curunir). Inspired by [Thariq's talk on how Claude Code uses skills](https://x.com/trq212/status/2033949937936085378) (category-driven templates, descriptions written for models, pre-written code over reconstruction) and [Andrew Ng's Context Hub](https://x.com/AndrewYNg/status/2033577583200354812) (agents pull curated API docs on demand instead of hallucinating). Uses [chub](https://github.com/context-hub/generator) during the research phase to search for and fetch curated API docs before falling back to web search.

## Skills

### skill-factory

Teaches AI coding agents to create new skills. Give it a description of what you want ("build a skill for managing GitHub issues with the gh CLI") and it walks the agent through requirements gathering, doc research, SKILL.md generation, and smoke testing.

```
skills/skill-factory/
├── SKILL.md                    # The skill itself
└── references/
    ├── template.md             # SKILL.md template + category heuristic table
    └── chub.md                 # Context Hub CLI reference (search → get → annotate)
```

## Usage

Load the `skill-factory` skill in your agent environment, then ask it to create a skill:

> "Create a skill called `github-issues` that teaches the agent to manage GitHub issues using the `gh` CLI."

The agent will:
1. Identify the skill category and ask clarifying questions
2. Research docs (context hub, web search, or user-provided)
3. Generate SKILL.md with the right emphasis for the category
4. Smoke test: validate structure, load test, dry-run against a test scenario
