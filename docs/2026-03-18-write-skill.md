# write-skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a generic skill-writer skill that teaches an agent to gather requirements, research docs, generate SKILL.md files, and smoke test them.

**Architecture:** Single SKILL.md file implementing a 4-phase workflow (Requirements → Research → Generate → Smoke Test). The skill is project-agnostic — no references to any specific agent framework. It discovers skills directory location from context.

**Tech Stack:** Markdown (SKILL.md with YAML frontmatter)

**Spec:** `docs/superpowers/specs/2026-03-18-write-skill-design.md`

**Style references:** Existing skills in the skills directory (web-search ~400 words, deep-research ~450 words) for length/density calibration. Output goes to `skills/write-skill/` in this workspace.

---

### Task 1: Write SKILL.md

**Files:**
- Create: `skills/write-skill/SKILL.md`

- [ ] **Step 1: Create skill directory**

```bash
mkdir -p skills/write-skill
```

- [ ] **Step 2: Write SKILL.md with frontmatter and all sections**

Write `skills/write-skill/SKILL.md` with the following structure. Content is derived from the design spec, generalized to remove framework-specific references.

**Frontmatter:**

```yaml
---
name: write-skill
description: "Use when asked to create, write, or build a new skill — gathers requirements, finds docs, generates SKILL.md, and smoke tests it"
---
```

**Body sections (in order):**

1. **Title + intro** (2 sentences) — What this skill does: guides the agent through creating a new skill from scratch. Notes that skills are markdown instruction sets loaded on demand.

2. **Workflow** — The 4-phase workflow adapted from spec, with these generalizations:
   - Phase 1 (Requirements): Identify category, validate skill name is lowercase-kebab-case, ask 1-2 clarifying questions, propose success criteria / test scenario
   - Phase 2 (Research): Try `chub search` if available (skip if not installed), fall back to web search, read 1-2 existing skills from the project's skills directory as style reference
   - Phase 3 (Generate): **Conflict check** — verify `{skills_dir}/{skill-name}/` doesn't already exist; if it does, ask user whether to overwrite or rename. Then assess need for supporting files, generate SKILL.md using template, write files.
   - Phase 4 (Smoke Test): Structural validation (frontmatter parses, name/description present), **load test** (use the skill loading tool available in the environment to load the new skill by name and verify it returns content), dry-run against success criteria

   Key generalization: Replace all `load_skill` references with "use the skill loading tool available in your environment" or similar. Replace `{skills_dir}` with "the project's skills directory" and note the agent should discover this from project config or ask the user. Weave the 7 Core Guidance principles (from Thariq's talk) into the template's embedded generation comments — don't state the obvious, write descriptions for models, build gotcha sections, provide pre-written code, progressive disclosure, provide flexibility, identify the category.

3. **Template** — The SKILL.md template from the spec (the ```markdown block), with embedded generation guidance comments. This is the core reference — the agent copies and fills this in.

4. **Category Heuristic** — The 9-category table from the spec, as-is. Agent identifies category early to shape template emphasis.

5. **Directory Structure** — When to add supporting files (references/, scripts/, templates/, examples/). From spec.

6. **Writing Good Descriptions** — The trigger-condition guidance. Good vs bad examples. From spec.

7. **The `tools` Frontmatter Field** — Brief note that skills can declare opt-in tools. Available tools are environment-specific; give examples (e.g., `attach`, `delegate`) but note the agent should check what's available. Only declare if the generated skill genuinely needs one.

8. **Research Strategy** — Priority order: user-provided docs > context hub (if available) > web search > agent knowledge. From spec.

9. **Common Mistakes** — Highest-value section. Include:
   - Writing descriptions that summarize contents instead of trigger conditions
   - Stating things the agent already knows (how to code, how to use curl)
   - Skipping the conflict check (overwriting existing skill)
   - Not reading existing skills for style calibration
   - Generating supporting files by default (should be complexity-driven)
   - Skipping the smoke test
   - Hardcoding framework-specific tool names instead of using what's available

- [ ] **Step 3: Verify frontmatter parses correctly**

```bash
head -5 skills/write-skill/SKILL.md
```

Verify: first line is `---`, `name: write-skill` present, `description:` present, closing `---` present.

- [ ] **Step 4: Check word count and density**

```bash
wc -w skills/write-skill/SKILL.md
```

Target: 400-600 words. Calibrated against existing skills — web-search is ~400 words, deep-research is ~450 words. This skill is more complex (Runbook category) so up to 600 is acceptable. If over 600, trim — move large reference content to a supporting file.

- [ ] **Step 5: Commit**

```bash
git add skills/write-skill/SKILL.md
git commit -m "feat: add write-skill — teaches agent to create new skills"
```

---

### Task 2: Smoke Test

- [ ] **Step 1: Structural validation**

Read `skills/write-skill/SKILL.md` and verify:
- YAML frontmatter has `name` and `description`
- `name` is lowercase-kebab-case, letters/numbers/hyphens only
- `description` starts with "Use when" and describes trigger condition
- All template sections present (Workflow, Template, Category Heuristic, Common Mistakes at minimum)

- [ ] **Step 2: Load test**

If a skill loading tool is available in the environment, load `write-skill` by name and verify it returns the SKILL.md content (not a "skill not found" error). If no loading tool is available, verify the file exists at the expected path and frontmatter is parseable.

- [ ] **Step 3: Dry-run against test scenario**

Test scenario: "Create a skill called `github-issues` that teaches the agent to create, search, and manage GitHub issues using the `gh` CLI."

Walk through the skill's instructions mentally:
1. Does the workflow guide through requirements gathering? (category = Library/API Reference)
2. Does research phase make sense? (would search for gh CLI docs)
3. Does the template produce a valid SKILL.md structure?
4. Does smoke test phase describe how to verify the generated skill?

If any phase is unclear or missing guidance, fix and re-verify.

- [ ] **Step 4: Fix any issues found and re-commit**

```bash
git add -u
git commit -m "fix: address smoke test findings in write-skill"
```

Only run if changes were needed.
