# Installation Reference

Guide for installing a skill's dependencies into the target environment. Dependencies are declared in `manifest.yaml`, not in SKILL.md.

## Dependency Declaration

Skills declare dependencies in a `manifest.yaml` file alongside SKILL.md. If no manifest.yaml exists, skip the entire installation workflow.

### Manifest Schema

```yaml
name: skill-name                    # must match SKILL.md frontmatter name

cli: [gh, jq]                       # CLI tools — checked via `which`, installed via system pkg manager

npm:                                 # npm packages — installed globally
  - "@some/package"

npx:                                 # npm packages run via npx — no global install needed
  - "@some/other-package"

pip:                                 # Python packages — installed via pipx (preferred) or pip
  - some-package

mcp:
  - name: gemini                     # human-readable server name (used as key in config)
    command: npx                     # command to run the server (default: npx)
    package: "@anthropic-ai/rlabs-gemini-mcp"  # npm package (for npx-based servers)
    scope: user                      # required — user | project
    args: []                         # additional args after package name
    env: [GEMINI_API_KEY]            # references to secrets section
    required: true                   # default true
  - name: jina
    transport: http                  # http transport (instead of stdio)
    url: "https://mcp.jina.ai/v1"
    scope: user
    env: [JINA_API_KEY]
    required: false

secrets:
  - name: GEMINI_API_KEY
    required: true
    description: "Gemini API key for grounded search and YouTube analysis"
    url: "https://aistudio.google.com/apikey"
  - name: JINA_API_KEY
    required: false
    description: "Jina Reader API key — removes rate limits on page fetching"
    url: "https://jina.ai/#api-key"
```

All sections are optional. Don't create a manifest.yaml for skills with no dependencies.

Version constraints can be embedded inline using native syntax: `"@some/package@^2.0"` for npm, `"some-package>=2.0"` for pip.

MCP server packages listed in the `mcp` section do not need to also appear in `npx` — the installer handles npx availability as part of MCP server setup.

### Field Reference

**MCP entry fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Human-readable server name (used as key in config) |
| `command` | string | `npx` | Command to run the server (`npx`, `uvx`, `python`, a binary name, etc.) |
| `package` | string | — | npm package name (for npx-based servers) |
| `transport` | string | `stdio` | `stdio` or `http` |
| `url` | string | — | URL for http transport servers |
| `scope` | string | required | `user` or `project` — no default, skill author must choose |
| `args` | list of strings | `[]` | Additional CLI args after package name |
| `env` | list of strings | `[]` | Secret names this server needs (references `secrets` section) |
| `required` | boolean | `true` | Whether the server is required for the skill to function |

**Secret entry fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Environment variable name |
| `required` | boolean | `true` | Whether the skill fails without this secret |
| `description` | string | — | Human-readable description for the setup prompt |
| `url` | string | — | Signup/API key URL |

## Installation Workflow

### Step 1 — Copy skill files

Copy the skill directory to the chosen destination (`{skills_dir}/{skill-name}/`). This was already selected during Phase 1 requirements gathering:

- **Project-local** (`./skills/`) — committed with the repo
- **User-global** (`~/.claude/skills/`) — available across projects
- **Custom path** — user-specified

### Step 2 — Check for manifest.yaml

Look for `manifest.yaml` in the skill directory. If it doesn't exist, skip Steps 3-8 entirely.

### Step 3 — Detect environment

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

### Step 4 — Detect package manager

For local installs, detect the system package manager:

| OS | Detection | Package manager |
|----|-----------|-----------------|
| macOS | `uname -s` = Darwin | `brew` |
| Debian/Ubuntu | `-f /etc/debian_version` | `apt` |
| Alpine | `-f /etc/alpine-release` | `apk` |
| RHEL/Fedora | `-f /etc/redhat-release` | `yum` or `dnf` |

For Node.js packages, check for `npm` or `yarn`. For Python packages, check for `pip` or `pipx`.

Let the user override the detected package manager if needed.

### Step 5 — Install dependencies by type

Process manifest sections in order: `cli` → `npm` → `npx` → `pip` → `secrets` → `mcp`.

Secrets are processed before MCP so that environment variables are available when MCP config is written.

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

#### Python packages

```bash
# Prefer pipx for CLI tools (isolated environments)
pipx install tool-name

# Fall back to pip if pipx unavailable
pip install tool-name
```

#### Secrets

For each entry in the `secrets` section, check if the environment variable is already set. For missing required secrets, prompt the user with the `description` and `url` from the manifest. Offer save options:

1. Shell rc file (`~/.zshrc`, `~/.bashrc`) — persists across sessions
2. Project `.env` file — project-scoped
3. Session only — exported for the current shell, gone on close
4. Manual — user handles it themselves

For optional secrets the user declines, warn if any required MCP server references that secret in its `env` list.

#### MCP servers

Generate config entries based on scope and transport:

**stdio servers** (default):

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

When `command` is not `npx`, omit the `-y` flag and use `args` as-is.

**http servers:**

```json
{
  "mcpServers": {
    "jina": {
      "type": "http",
      "url": "https://mcp.jina.ai/v1",
      "headers": {
        "Authorization": "Bearer ${JINA_API_KEY}"
      }
    }
  }
}
```

The `type` field **must** be `"http"` — not `"url"`, not `"https"`, not `"web"`. This is the only valid value for HTTP transport servers.

**Preferred: use `claude mcp add` CLI** — this avoids config format errors entirely:

```bash
# stdio server
claude mcp add gemini --scope user \
  --env GEMINI_API_KEY=YOUR_KEY \
  -- npx -y @anthropic-ai/rlabs-gemini-mcp

# http server
claude mcp add jina --transport http --scope user \
  --header "Authorization: Bearer YOUR_KEY" \
  https://mcp.jina.ai/v1
```

When the CLI is available, prefer it over manual JSON editing. Fall back to manual config only when the CLI is unavailable (e.g., container environments or non-Claude-Code hosts).

**Config file locations:**

- `scope: project` → `.mcp.json` in project root
- `scope: user` → `~/.claude/claude_desktop_config.json`

When generating MCP config:
- If the config file already exists, merge the new server entry — do not overwrite existing servers.
- Use `${VAR}` syntax for env references. Secrets belong in the environment, not in config files.
- Build the `env` object by mapping each name in the MCP entry's `env` list to `"${NAME}"`.

### Step 6 — Container installation

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

### Step 7 — Validate installation

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

# For secrets, verify env var is set
[ -n "$GEMINI_API_KEY" ] && echo "GEMINI_API_KEY set" || echo "GEMINI_API_KEY missing"
```

Report results per dependency: installed (with version), failed (with error), or skipped (user chose not to install).

## Common Mistakes

- **Forgetting PATH after install** — tools installed via `npm install -g` or `pipx` may not be on PATH in the current shell. Suggest `export PATH` or shell restart if `which` fails after install.
- **Running apt without update** — always `apt-get update` before `apt-get install` in containers. Stale package lists cause "package not found" errors.
- **Wrong `type` for HTTP transport** — the only valid value is `"type": "http"`. Common hallucinations: `"url"`, `"https"`, `"web"`. When in doubt, use `claude mcp add --transport http` instead of manual config.
- **Hardcoding secrets in MCP config** — use `${ENV_VAR}` references, not literal tokens. Secrets belong in the environment, not in config files.
- **Overwriting existing MCP config** — always read and merge, never overwrite. Users may have other servers configured.
- **Missing base image packages** — Alpine images lack many tools by default. `curl`, `git`, and `bash` often need explicit installation.
- **Assuming brew on Linux** — brew works on Linux but isn't standard. Default to `apt` on Debian/Ubuntu.
- **Installing globally when npx suffices** — MCP servers and one-off tools should use `npx -y` rather than polluting the global namespace.
- **Skipping user confirmation** — always present the install commands before running them. Never install software without the user's explicit approval.
- **Putting dependencies in SKILL.md** — dependencies are installation-time metadata. They belong in manifest.yaml, not in the file that gets loaded into the agent's runtime prompt on every invocation.
