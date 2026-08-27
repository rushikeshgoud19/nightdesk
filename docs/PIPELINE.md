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

`agy` is a single Go binary — no Node, no Python. It replaced Gemini CLI, which
Google retired on 18 June 2026. If you still have `@google/gemini-cli` installed,
it is dead software; uninstall it.

Then, in the repo:

```powershell
agy
```

`CLAUDE.md` in the repo root carries the project rules. Point `agy` at it so it
inherits the same constraints — server authority, no editing inside Studio, no
compatibility layers.

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

**Not yet run end to end:**

- `agy` — documented from Google's install docs, not executed here
- `tools/blender_export.py` — written against the Blender 5.x Python API, not yet
  run against a real scene. Expect to fix one thing on first use.
- Blender MCP connection — addon installed, but the server has not been started

Treat the second list as "should work" rather than "does work", and fix what
breaks rather than assuming you did it wrong.
