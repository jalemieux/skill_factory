# skill_factory

A project for building and managing AI agent skills. Born from the need to reliably add skills to [curunir](https://github.com/jalemieux/curunir). Inspired by [Thariq's talk on how Claude Code uses skills](https://x.com/trq212/status/2033949937936085378) (category-driven templates, descriptions written for models, pre-written code over reconstruction) and [Andrew Ng's Context Hub](https://x.com/AndrewYNg/status/2033577583200354812) (agents pull curated API docs on demand instead of hallucinating). Uses [chub](https://github.com/context-hub/generator) during the research phase to search for and fetch curated API docs before falling back to web search.

## Manifest Schema

Skills declare dependencies in a `manifest.yaml` file alongside SKILL.md. All sections are optional.

```yaml
name: skill-name                    # must match SKILL.md frontmatter name
cli: [gh, jq]                       # CLI tools — checked via `which`, installed via system pkg manager
tools: [web_fetch]                   # LLM tools — must be in the agent's tool context at runtime
skills: [web-search]                 # other skills this skill depends on
npm: ["@some/package"]               # npm packages — installed globally
npx: ["@some/other-package"]         # npm packages run via npx — no global install needed
pip: [some-package]                  # Python packages — installed via pipx (preferred) or pip
mcp: [...]                           # MCP servers — see installation.md for full schema
secrets: [...]                       # API keys / env vars — see installation.md for full schema
```

The `tools` field declares LLM runtime tools the skill expects the host agent to provide (e.g., `web_fetch` in curunir, `WebFetch` in Claude Code). These are validated at install time but not installed — the host platform must already provide them.

## Skills

### skill-factory

Teaches AI coding agents to create new skills. Give it a description of what you want ("build a skill for managing GitHub issues with the gh CLI") and it walks the agent through requirements gathering, dependency installation, doc research, SKILL.md generation, and smoke testing. Handles installing CLI tools, npm packages, MCP servers, and Python packages — with support for containerized environments.

```
skills/skill-factory/
├── SKILL.md                    # The skill itself
└── references/
    ├── template.md             # SKILL.md template + category heuristic table
    ├── installation.md         # Dependency installation workflow + manifest schema
    └── chub.md                 # Context Hub CLI reference (search → get → annotate)
```

## Workflows

The skill-factory skill has been automated into a full contribution workflow via [git-contribute](examples/git-contribute/SKILL.md) — an autonomous issue-to-merge lifecycle that picks up GitHub issues, plans implementations via draft PRs, and shepherds them through code review. Run it on a loop to continuously pick up work from a project's issue tracker.

## Usage

Load the `skill-factory` skill in your agent environment, then ask it to create a skill:

> "Create a skill called `github-issues` that teaches the agent to manage GitHub issues using the `gh` CLI."

The agent will:
1. Identify the skill category and ask clarifying questions
2. Research docs (context hub, web search, or user-provided)
3. Generate SKILL.md with the right emphasis for the category
4. Smoke test: validate structure, load test, dry-run against a test scenario

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
