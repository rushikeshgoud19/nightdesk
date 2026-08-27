# nightdesk

A co-op anomaly-horror game for Roblox, built the boring way: source files in git,
Rojo syncing into Studio, linted and formatted in CI-able commands, and an AI
agent wired into Studio over MCP.

You work the night desk of a highway motel. Guests arrive one at a time. Some of
them are not guests. Between shifts you spend the takings on the motel — more
rooms, working lights, cameras that show you more.

**This repo is also a template.** If you just want the setup and not the game,
delete `src/` and keep everything else. The toolchain, the editor config, the
Studio MCP wiring and the OpenRouter launcher are all game-agnostic.

---

## Quick start

```bash
git clone <your-fork> nightdesk
cd nightdesk
```

Then, in order:

### 1. Toolchain

[Rokit](https://github.com/rojo-rbx/rokit) pins every tool so your clone and mine
run identical versions. Install it once, machine-wide:

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

**macOS / Linux:**
```bash
curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash
```

Then, in the repo:

```bash
rokit install
```

That reads `rokit.toml` and puts these on your PATH:

| Tool | Version | Job |
|---|---|---|
| [Rojo](https://rojo.space) | 7.7.0 | Syncs `src/` into Studio |
| [Wally](https://wally.run) | 0.3.2 | Package manager |
| [Selene](https://kampfkarren.github.io/selene/) | 0.31.0 | Linter |
| [StyLua](https://github.com/JohnnyMorganz/StyLua) | 2.5.2 | Formatter |

One more one-time step — Selene's Roblox standard library is generated per clone,
not committed:

```bash
selene generate-roblox-std
```

### 2. Studio ↔ Rojo

Install the Rojo Studio plugin:

```bash
rojo plugin install
```

Then start the sync server and leave it running:

```bash
rojo serve
```

In Studio: open the Rojo plugin, hit **Connect**. Your `src/` tree appears in the
Explorer. Edit files in VS Code, watch them update live in Studio.

> **The rule that makes this work:** never write game logic in Studio's script
> editor. Studio is a viewer and a playtest harness. Everything real lives in
> `src/` and flows one way. Anything typed into Studio is gone on the next sync.

### 3. Editor

Open the folder in VS Code and accept the recommended extensions
(`.vscode/extensions.json`) — luau-lsp, StyLua, Selene, Rojo. `.vscode/settings.json`
already points luau-lsp at `default.project.json`, so `require` across the tree
resolves and `game` is typed.

### 4. Studio MCP — let the agent drive Studio

Roblox ships an MCP server **inside Studio** now. The old standalone
[`Roblox/studio-rust-mcp-server`](https://github.com/Roblox/studio-rust-mcp-server)
was archived in April 2026 — don't follow tutorials that tell you to build it.

In Studio:

1. **Assistant Settings → MCP Servers**
2. Turn on **Enable Studio as MCP server**
3. **Quick connect** → pick your client (Claude Code, Cursor, …)

Quick connect writes the client config for you, with the right paths for your
machine. That's why this repo does not ship an `.mcp.json` — the command is
machine-specific and a hardcoded one would just be wrong on your box. If you want
it repo-scoped instead of global, copy what Quick connect generated into a
`.mcp.json` at the repo root.

Once connected, the agent can read the Instance tree, write and run Luau in the
live session, read the console, and start/stop playtests. Keep Studio open — that
is where the work actually happens.

### 5. Studio plugins worth having

Optional, but they save real time on the building side:

| Plugin | Why |
|---|---|
| **Rojo** | Required. Step 2 installed it. |
| **Building Tools by F3X** | Fast geometry work without fighting the default tools |
| **ResizeAlign** / **GapFill** | Makes hand-built rooms actually meet at the corners |
| **Tag Editor** | Manage `CollectionService` tags visually |

> Studio plugins run arbitrary code with full access to your place. Install from
> the Creator Store, prefer ones with large install counts and a named author, and
> don't grant script injection permission to anything you haven't heard of.

---

## Running Claude Code on a free OpenRouter model

Optional. Uses [OpenRouter](https://openrouter.ai) as an Anthropic-compatible
gateway so Claude Code talks to a different model.

```bash
cp .env.example .env       # then put your key in it
```

```powershell
.\scripts\openrouter.ps1                # MiniMax M3 (default)
.\scripts\openrouter.ps1 -Model glm     # GLM 5.2
```

```bash
./scripts/openrouter.sh                 # MiniMax M3 (default)
./scripts/openrouter.sh --glm           # GLM 5.2
```

The scripts set the environment for that one shell only — `claude` in any other
terminal still uses your normal account.

### The endpoint, specifically

This is the part everyone gets wrong. OpenRouter's docs list the Anthropic-format
endpoint as:

```
https://openrouter.ai/api/v1/messages
```

That is correct **for raw curl**. It is *not* what goes in `ANTHROPIC_BASE_URL`.
Claude Code appends `/v1/messages` itself, so the variable takes the API **root**:

```bash
ANTHROPIC_BASE_URL="https://openrouter.ai/api"      # ✅
ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1"   # ❌ → /api/v1/v1/messages → 404
```

The full set:

```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="sk-or-v1-..."   # your key
export ANTHROPIC_API_KEY=""                  # MUST be blank, or CC falls back to Anthropic auth
export ANTHROPIC_MODEL="z-ai/glm-5.2:free"
export ANTHROPIC_SMALL_FAST_MODEL="z-ai/glm-5.2:free"
```

`ANTHROPIC_AUTH_TOKEN`, not `ANTHROPIC_API_KEY` — the second one is for Anthropic
direct and must be explicitly empty when you're pointing at a gateway.

### Which model — measured, not guessed

Both were tested through Claude Code on 2026-08-28, same task: read a Luau file
and change one value.

| | MiniMax M3 free | GLM 5.2 free |
|---|---|---|
| Providers on OpenRouter | several | **Decart only** |
| Raw API call | 200 first try | 429 on 5 of 6 tries |
| Claude Code, one-line edit | **succeeded, clean** | **failed after 203s** |
| Context served | 1M | 256K |
| Agentic benchmark rank | #108 of 225 | notably better |

GLM is the better model on paper for agentic work. It is also the one that could
not finish a one-line edit, because it has a single provider whose free pool is
saturated. Claude Code needs many sequential calls; a model that answers one call
in six cannot complete a task, and it burns three minutes discovering that.

**Default to MiniMax M3.** It is the weaker model that actually returns. Switch to
GLM if the pool ever frees up and you want the better reasoning.

Other limits, whichever you pick:

- **50 requests/day** on a $0 balance, shared across *all* `:free` models — you
  do not get 50 each. A one-time $10 top-up raises it to **1,000/day**
  permanently. That is the real difference between a toy and a tool.
- **20 requests/minute**, hard cap, credits or not.
- More keys do not help. OpenRouter governs capacity per account, globally —
  extra keys or extra accounts change nothing, and the second one breaks their
  terms.
- GLM is a reasoning model: it spends output tokens thinking before answering.
  Give it generous `max_tokens` or it hits the cap mid-thought.

Sensible split: free models for grunt work — bulk renames, writing out anomaly
table entries, first-draft boilerplate. Something stronger for architecture and
the server-authority code, where a malformed edit costs more than it saves.

### Keys

`.env` is gitignored. `.env.example` is the only key-shaped file that gets
committed and it contains a placeholder.

If a key ever lands somewhere public — a chat, a screenshot, a commit, an issue —
treat it as burned. Delete it at
[openrouter.ai/settings/keys](https://openrouter.ai/settings/keys) and make a new
one. It takes ten seconds and there is no partial version of this.

---

## Daily loop

```bash
rojo serve                       # terminal 1, leave running, connect from Studio
stylua src/                      # format before committing
selene src/                      # lint
rojo build -o nightdesk.rbxl     # standalone place file when you need one
```

## Layout

```
src/shared/    → ReplicatedStorage.Shared       types, anomaly table, remote declarations
src/server/    → ServerScriptService.Server     authority: guests, verdicts, economy
src/client/    → StarterPlayerScripts.Client    rendering and input only
scripts/       launchers
CLAUDE.md      instructions for AI agents working in this repo
```

`default.project.json` is the map between those folders and the Roblox tree. It
also sets Future lighting and a 2 AM clock, because the atmosphere is the product.

## Where this is

Week 1 of the plan: one guest, one desk, four anomalies, admit or refuse, server
scores it. It runs. It is not fun yet.

Next: the shift timer and guest queue, then co-op, then DataStore persistence,
then the upgrade tree — in that order, because the upgrade tree is the retention
spine and it needs saving underneath it before it means anything.

## Licence

MIT. Take the setup, ignore the game.
