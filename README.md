# nightdesk

A co-op anomaly-horror game for Roblox, built the boring way: source files in git,
Rojo syncing into Studio, linted and formatted in CI-able commands, and an AI
agent wired into Studio over MCP.

You work the night desk of a highway motel. Guests arrive one at a time. Some of
them are not guests. Between shifts you spend the takings on the motel — more
rooms, working lights, cameras that show you more.

**This repo is also a template.** If you just want the setup and not the game,
delete `src/` and keep everything else. The toolchain, the editor config, the
Studio and Blender MCP wiring and the asset exporter are all game-agnostic.

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

## The agent pipeline

Four tools, each owning one thing — Rojo for source, Studio for runtime, Blender
for assets, Antigravity for writing Luau. Claude is optional.

**[docs/PIPELINE.md](docs/PIPELINE.md)** has the full wiring, and documents two
lanes: **Lane A** needs no Claude at all, **Lane B** adds Claude as planner and
reviewer on top of the same machinery.

Short version:

```powershell
irm https://antigravity.google/cli/install.ps1 | iex   # once, installs agy
agy                                                    # then, in the repo
```

`agy` is a single Go binary. It replaced Gemini CLI, which Google retired on
18 June 2026 — if you still have `@google/gemini-cli` installed, it is dead
software.

### Why not free OpenRouter models

Tried and dropped, so you don't repeat it. GLM 5.2 free has exactly one provider
(Decart) whose free pool is saturated: **5 of 6 raw calls returned 429**, and
Claude Code spent **203 seconds** retrying before giving up without completing a
one-line edit. MiniMax M3 free does work — clean tool calls, correct edits — but
ranks #108 of 225 on agentic benchmarks, which is exactly the axis that matters
here. Poolside's coding models answered but would not call tools at all.

More API keys do not help: OpenRouter governs capacity per account globally, so
extra keys and extra accounts change nothing.

`agy` puts Gemini 3.x, Claude Sonnet 4.6, Claude Opus 4.6 and GPT-OSS 120B behind
one command. That is a better answer than hunting free endpoints.

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
tools/         blender_export.py — Roblox-ready FBX export
assets/        exported .fbx, ready to import into Studio
docs/ROBLOX.md the platform reference — architecture, limits, assets, traps
docs/PIPELINE.md how the four tools fit together
docs/PROMPT.md copy-paste session starters
AGENTS.md      project rules — read by agy natively, and by Claude via CLAUDE.md
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
