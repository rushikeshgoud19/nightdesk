# The pipeline

Four tools, each owning one thing. The point of the split is that no tool is
asked to do a job it is bad at.

| Tool | Owns | Talks to the agent via |
|---|---|---|
| **Rojo** | Source of truth. `src/` → Studio, one direction. | files on disk |
| **Roblox Studio** | Runtime. Playtest, console, the actual game. | built-in MCP server |
| **Blender** | Assets. Rooms, props, the motel itself. | BlenderMCP addon |
| **Antigravity (`agy`)** | Writing Luau. | it *is* the agent |

Claude is optional and appears only in Lane B below.

---

## Lane A — no Claude required

This is the path anyone cloning the repo can run. `agy` does the building; you do
the judging.

```
   you ──► agy ──► src/*.luau ──► rojo serve ──► Studio ──► playtest
                        ▲                                      │
                        └──────────── you read the result ◄─────┘

   you ──► agy ──► Blender (MCP) ──► tools/blender_export.py ──► .fbx ──► Studio
```

**Setup, once:**

```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

`agy` is a single Go binary — no Node, no Python. It installs to
`%LOCALAPPDATA%\agy\bin` and adds itself to your user PATH, so **open a new
terminal afterwards** or the command will look missing. It replaced Gemini CLI,
which Google retired on 18 June 2026; if you still have `@google/gemini-cli`
installed, that is dead software.

Then, in the repo:

```powershell
agy
```

`AGENTS.md` at the repo root carries the project rules, and `agy` parses it
automatically on startup — server authority, no editing inside Studio, no
compatibility layers. `CLAUDE.md` is a one-line `@AGENTS.md` import so both
agents read the same file and it cannot drift.

**Models available through `agy models`:**

```
gemini-3.7-flash-{high,medium,low}    gemini-3.1-pro-{high,low}
gemini-3.6-flash-{high,medium,low}    claude-sonnet-4-6
gemini-3.5-flash-{high,medium,low}    claude-opus-4-6-thinking
gpt-oss-120b-medium
```

Pick per session with `--model`, or `/model` inside the session.

### Run it interactively, not headless

`agy -p "..."` (print mode) **cannot ask for tool permissions**, so it silently
denies them and produces nothing. The log line is
`Print mode: soft-denying tool confirmation "RunCommand"`. This is not a
misconfiguration — print mode has no way to prompt.

For building, run plain `agy` and approve tools as it asks. Reserve `-p` for
prompts that need no tools at all.

There is also a [known permissions bug on Windows](https://github.com/google-antigravity/antigravity-cli/issues/614):
the matcher splits on spaces before handling quotes, so a rule like
`command(git)` fails to match once Windows resolves it to
`C:\Program Files\Git\cmd\git.exe` — `C:\Program Files` tokenizes as
`C:\Program`. You will be asked to approve the same command repeatedly, and
"Yes, permanently" writes a rule that never matches. Until it is fixed, either
approve as you go or add `command(*)` to your allow list — which auto-approves
*every* command, so decide that deliberately rather than to stop the prompting.

Do not use wildcards in path rules — `write_file(C:\repo\*)` crashes with
"globs not supported". Directory rules are already recursive; write the path bare.

**Permissions currently set** in `~/.gemini/antigravity-cli/settings.json`:

```json
"permissions": {
  "allow": [
    "read_file(C:\\Users\\rushi\\Desktop\\nightdesk)",
    "write_file(C:\\Users\\rushi\\Desktop\\nightdesk)",
    "command(rojo)", "command(stylua)", "command(selene)",
    "command(wally)", "command(git)"
  ],
  "deny": [
    "command(rm -rf)", "command(git push --force)", "command(rojo upload)"
  ]
}
```

File writes are scoped to this repo only. Adjust the path for your own clone.

**The loop:**

1. `rojo serve` in one terminal, Studio connected via the Rojo plugin.
2. `agy` in another, working on `src/`.
3. Changes appear in Studio live. Press Play. Judge it yourself.
4. `stylua src/ && selene src/` before committing.

---

## Lane B — with Claude as planner and reviewer

Same machinery, one role added. Claude does not write the Luau; it decides what
should be written and checks what came back.

```
   you ──► Claude ──► plan + contract ──► agy ──► src/*.luau
              ▲                                       │
              └────────── Claude reviews the diff ◄────┘
                                                       │
                                    rojo serve ──► Studio ──► playtest
```

Why split it this way: the expensive judgement is *what to build and whether the
result is right*. The typing is cheap. Keeping the planner and the builder as
separate agents means the reviewer did not write the code it is reviewing, which
is the entire value of a review.

Claude also holds the Studio and Blender MCP connections in this lane, so it can
read the live data model and inspect the scene when reviewing.

---

## Assets: Blender → Studio

Three things break every first import. `tools/blender_export.py` handles all
three, so use it rather than Blender's export menu directly.

| Trap | What happens | Handled by |
|---|---|---|
| FBX scale | model lands 100× too large | export at `global_scale=0.01` |
| Unapplied transforms | model arrives skewed | transforms baked on a duplicate |
| Triangle budget | Studio refuses the import | counted and reported before export |

**Roblox limits, current:**

- **21,000 triangles** per MeshPart on single import
- **~10,000** through Asset Manager batch import — the script targets this lower
  number so an asset works through either path
- **1024×1024** textures or smaller; Roblox downsamples anything larger
- Geometry must be watertight, no zero-thickness faces

**Usage:**

```bash
# from Blender's Text Editor, with meshes selected — or headless:
blender motel.blend --background --python tools/blender_export.py -- --out assets/
```

### Model scripts are the source, not the .blend

Models built procedurally live in `tools/models/*.py` and those scripts are what
gets committed. A `.blend` is a binary you cannot diff or review; a script is
text that regenerates the identical mesh, and a reviewer can see that a change
moved a hook 12mm rather than seeing "binary file changed".

`tools/models/keyrack.py` is the worked example — verified to rebuild the same
360-triangle mesh when re-run.

Hand-sculpted work is different: commit the `.blend` for that, since no script
produced it. Exported `.fbx` stays gitignored either way — it is an intermediate
on the way to a Roblox asset ID.

Then in Studio: **Avatar tab → 3D Importer**, or drag the `.fbx` into the viewport.

The script never modifies your scene. Transforms are applied to a temporary
duplicate which is deleted afterwards.

---

## MCP wiring

**Roblox Studio** ships an MCP server inside Studio as of 2026. The old standalone
`Roblox/studio-rust-mcp-server` was archived in April 2026 — ignore tutorials that
tell you to build it.

> Studio → **Assistant Settings → MCP Servers → Enable Studio as MCP server** →
> **Quick connect** → pick your client.

Quick connect writes the client config with the correct paths for your machine.
That is why this repo ships no `.mcp.json` — a hardcoded one would be wrong on
every machine but the one that made it.

**Blender** uses the [BlenderMCP addon](https://github.com/ahujasid/blender-mcp).
Install it in Blender's addon preferences, then start the server from the
BlenderMCP panel in the 3D viewport sidebar (`N` key). It listens on
`localhost:9876`. If your agent reports "cannot connect to Blender", the cause is
almost always that Blender is closed or the server was never started — the addon
being installed is not enough.

---

## What is verified, and what is not

Straight about which of this was actually run on a machine:

**Verified working:**

- Rojo 7.7.0 → Studio sync, plugin installed, `rojo build` produces a valid place
- `stylua --check` and `selene` pass clean on `src/`
- Studio installed with the built-in MCP available
- BlenderMCP addon present in Blender 5.1
- `agy` 1.1.22 installed, authenticated, `agy models` returns the full list
- Blender registered as an `agy` MCP server (`agy mcp list` shows it enabled)

**Known-limited, cause understood:**

- `agy -p` (print mode) cannot complete tool-using tasks — it soft-denies every
  permission because it cannot prompt. Use interactive `agy`. Not a bug in this
  setup.

**Not yet run end to end:**

- Interactive `agy` on a real task — needs a human at the prompt, so it has not
  been driven here
- `tools/blender_export.py` — parses clean, written against the Blender 5.x
  Python API, but never run on a real scene. Expect to fix one thing first use.
- Blender MCP connection — addon installed and Blender was running, but the
  server was never started, so `localhost:9876` stayed closed. Start it from the
  sidebar: `N` → **BlenderMCP** tab → **Connect to MCP server**.

Treat the third list as "should work" rather than "does work", and fix what
breaks rather than assuming you did it wrong.
