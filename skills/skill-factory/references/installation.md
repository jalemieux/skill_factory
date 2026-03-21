# Installation Reference

Guide for installing a skill's files and dependencies into the target environment.

## Dependency Declaration

Skills declare dependencies in two places:

### Frontmatter (simple CLI tools)

```yaml
---
name: my-skill
description: "..."
dependencies: [gh, jq, ripgrep]
---
```

Each entry is a CLI command name. The agent checks availability with `which <tool>` and installs missing ones.

### Body section (complex dependencies)

For dependencies that need arguments, version constraints, or MCP server configuration, add a `## Dependencies` section in the skill body:

```markdown
## Dependencies

- `gh` — GitHub CLI, used for issue and PR operations
- `@anthropic-ai/mcp-server-slack` — MCP server, run via `npx`
  - scope: project
  - args: []
  - env: { SLACK_BOT_TOKEN: "xoxb-...", SLACK_TEAM_ID: "T01..." }
- `chub` — Context Hub CLI, install via `npm install -g @anthropic-ai/chub`
  - version: ">=1.0.0"
```

## Installation Workflow

### Step 1 — Copy skill files

Copy the skill directory to the chosen destination (`{skills_dir}/{skill-name}/`). This was already selected during Phase 1 requirements gathering:

- **Project-local** (`./skills/`) — committed with the repo
- **User-global** (`~/.claude/skills/`) — available across projects
- **Custom path** — user-specified

### Step 2 — Detect environment

Determine where dependencies will be installed:

```bash
# Check if running in a container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
  echo "container"
# Check if Dockerfile exists in project (hybrid setup)
elif [ -f Dockerfile ] || [ -f docker-compose.yml ]; then
  echo "hybrid"
else
  echo "local"
fi
```

Ask the user to confirm the detected environment. For hybrid setups, ask which dependencies should be local vs containerized.

### Step 3 — Detect package manager

For local installs, detect the system package manager:

| OS | Detection | Package manager |
|----|-----------|-----------------|
| macOS | `uname -s` = Darwin | `brew` |
| Debian/Ubuntu | `-f /etc/debian_version` | `apt` |
| Alpine | `-f /etc/alpine-release` | `apk` |
| RHEL/Fedora | `-f /etc/redhat-release` | `yum` or `dnf` |

For Node.js packages, check for `npm` or `yarn`. For Python packages, check for `pip` or `pipx`.

Let the user override the detected package manager if needed.

### Step 4 — Install dependencies by type

#### CLI tools (brew/apt/apk)

```bash
# macOS
brew install gh jq ripgrep

# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y gh jq ripgrep

# Alpine
apk add --no-cache gh jq ripgrep
```

**Package name mapping** — some tools have different package names across managers. Common mappings:

| Tool | brew | apt | apk |
|------|------|-----|-----|
| `gh` | `gh` | `gh` | `github-cli` (edge) |
| `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` |
| `jq` | `jq` | `jq` | `jq` |
| `fd` | `fd` | `fd-find` | `fd` |

When unsure about a package name, check with the user rather than guessing.

#### npm packages (global)

```bash
npm install -g @context-hub/generator
```

#### npm packages (npx — no global install)

Some tools run via `npx` and don't need global installation. Just verify `npx` is available:

```bash
which npx || npm install -g npx
```

#### MCP servers

MCP servers need a config entry rather than (or in addition to) a global install. Generate the appropriate config based on scope:

**Project-level** (`.mcp.json` in project root):

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
      }
    }
  }
}
```

**User-level** (`~/.claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-slack"],
      "env": {
        "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}",
        "SLACK_TEAM_ID": "${SLACK_TEAM_ID}"
      }
    }
  }
}
```

When generating MCP config:
- If the config file already exists, merge the new server entry — do not overwrite existing servers.
- Use `${VAR}` syntax for secrets so they're read from the environment, not hardcoded.
- Ask the user which scope (project vs user) to use.

#### Python packages

```bash
# Prefer pipx for CLI tools (isolated environments)
pipx install tool-name

# Fall back to pip if pipx unavailable
pip install tool-name
```

### Step 5 — Container installation

For containerized environments, generate Dockerfile instructions instead of running commands directly.

**Detect base image package manager:**

| Base image | Package manager |
|------------|-----------------|
| `node:alpine`, `alpine` | `apk` |
| `node:slim`, `debian`, `ubuntu` | `apt` |
| `python:*` | `apt` (system), `pip` (Python) |

**Generate Dockerfile RUN lines:**

```dockerfile
# CLI tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gh \
    jq \
    && rm -rf /var/lib/apt/lists/*

# npm global packages
RUN npm install -g @context-hub/generator

# Python tools
RUN pip install --no-cache-dir tool-name
```

**For docker-compose setups**, suggest adding to the `build` section or a dedicated install stage.

Present the generated Dockerfile lines to the user for review before writing them.

### Step 6 — Validate installation

After installing, verify each dependency:

```bash
# Check command exists
which gh && gh --version
which jq && jq --version

# For npx tools, verify the package resolves
npx --yes @anthropic-ai/mcp-server-slack --help 2>/dev/null

# For MCP servers, verify config is valid JSON
python3 -c "import json; json.load(open('.mcp.json'))" 2>/dev/null \
  || node -e "JSON.parse(require('fs').readFileSync('.mcp.json'))"
```

Report results per dependency: installed (with version), failed (with error), or skipped (user chose not to install).

## Handling No Dependencies

If the skill declares no `dependencies` frontmatter field and has no `## Dependencies` body section, skip the entire installation workflow. Just copy the skill files and move on to the credential check step.

## Common Mistakes

- **Forgetting PATH after install** — tools installed via `npm install -g` or `pipx` may not be on PATH in the current shell. Suggest `export PATH` or shell restart if `which` fails after install.
- **Running apt without update** — always `apt-get update` before `apt-get install` in containers. Stale package lists cause "package not found" errors.
- **Hardcoding secrets in MCP config** — use `${ENV_VAR}` references, not literal tokens. Secrets belong in the environment, not in config files.
- **Overwriting existing MCP config** — always read and merge, never overwrite. Users may have other servers configured.
- **Missing base image packages** — Alpine images lack many tools by default. `curl`, `git`, and `bash` often need explicit installation.
- **Assuming brew on Linux** — brew works on Linux but isn't standard. Default to `apt` on Debian/Ubuntu.
- **Installing globally when npx suffices** — MCP servers and one-off tools should use `npx -y` rather than polluting the global namespace.
- **Skipping user confirmation** — always present the install commands before running them. Never install software without the user's explicit approval.
