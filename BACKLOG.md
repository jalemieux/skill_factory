# Curunir Skills — Backlog

## Skills to Build

### context-hub
Implement a skill that integrates [Context Hub](https://github.com/andrewyng/context-hub) (`chub`) — Andrew Ng's open CLI tool that gives coding agents curated, versioned API documentation.

**What it does:**
- `chub search "topic"` — search for relevant API docs
- `chub get provider/api --lang js` — fetch specific docs in target language
- Self-improving: agents can annotate docs with notes that persist across sessions
- Community-maintained, 6K+ GitHub stars, 1000+ API documents

**Why:** Curunir agents could use chub to get accurate, up-to-date API docs instead of hallucinating APIs. Reduces need to bake API knowledge into individual skills.

**Source:** https://x.com/AndrewYNg/status/2033577583200354812

---

### Document: How to Write Skills (skill-writing guide)
Write a guide for creating curunir skills, incorporating lessons from Anthropic's Claude Code team (Thariq's article).

**Key principles to document:**

1. **Nine skill categories** (from Thariq's article):
   - Library & API Reference
   - Product Verification
   - Data Fetching & Analysis
   - Business Process & Team Automation
   - Code Scaffolding & Templates
   - Code Quality & Review
   - CI/CD & Deployment
   - Runbooks
   - Infrastructure Operations

2. **Best practices:**
   - Don't state the obvious — focus on org-specific knowledge that changes default behavior
   - Build gotcha sections — capture common failure points, update as new issues arise
   - Use file system architecture — leverage progressive disclosure (folder structure, reference files, scripts, examples) not just dense markdown
   - Provide flexibility — give info + adaptability, not overly specific instructions
   - Write descriptions for models, not humans — the description determines skill discovery
   - Provide pre-written code — supply scripts so agent composes rather than reconstructs
   - Plan setup carefully — config files, ask user questions when needed

3. **Two categories of skills** (from ecosystem analysis):
   - **Capability Uplift** — grant new abilities (web scraping, PDF creation, etc.)
   - **Encoded Preference** — guide through team-specific workflows for things the agent already knows

**Source:** https://x.com/trq212/status/2033949937936085378
