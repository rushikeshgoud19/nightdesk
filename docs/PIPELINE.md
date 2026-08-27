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

**Rule matching is broken for scoped rules — you will need the wildcards.**
Tested on Windows, August 2026: `command(git)`, `read_file(<repo path>)`,
`list_dir(<repo path>)` and `mcp(blender)` all failed to match, one after
another, each denying a different tool on each run. Only `command(*)` and
`mcp(*)` actually match. Path rules like `write_file(<repo>)` do still scope
writes, so keep them — but expect to add the two wildcards before headless agy
does anything at all.

This is the price of headless. Interactive `agy` prompts and you approve, so it
sidesteps the whole mess.

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

### Building the world in Studio, and getting it back into git

Hand-writing geometry as JSON is miserable and does not scale past one room. You
want to drag walls around in Studio. Rojo 7.7 can do that — `rojo syncback` reads
a `.rbxl` and writes the file system from it.

```bash
# 1. build the lobby by hand in Studio, then save the place as place.rbxl
# 2. see exactly what would change, writing nothing:
rojo syncback --input place.rbxl world.project.json --dry-run --list
# 3. if it looks right:
rojo syncback --input place.rbxl world.project.json
```

**`world.project.json` exists to make this safe.** Syncback writes the file system
from the place file. Pointed at `default.project.json` it would happily overwrite
`src/*.luau` with whatever script content is in that `.rbxl` — which is how you
lose a day to a stale build. `world.project.json` maps *only* `Workspace.Lobby`,
so the worst a bad syncback can do is scramble some parts. **Code stays one-way,
permanently.**

Syncback prompts before writing unless you pass `-y`, and `--dry-run --list`
shows the full file list first. Use it. Verified here: a dry-run against the
lobby listed 11 files and touched nothing in `src/server`, `src/client`, or
`src/shared`.

The world lands as `.rbxm` — binary, not diffable. That is the real cost, and it
is the right trade for geometry: nobody reviews a wall position by reading a
diff, they look at it. Code stays text.

### Which sync tool — Rojo, Argon, or Lync

Checked rather than assumed, August 2026:

| | stars | open issues | last push | latest release |
|---|---|---|---|---|
| **Rojo** | 1712 | 201 | 2026-07-06 | v7.7.0 (2026-07-02) |
| Argon | 141 | 18 | 2026-07-01 | 2.0.29 (2026-05-19) |
| Lync | 37 | 9 | 2026-08-17 | 0.30.14 (2026-08-11) |

All three are maintained. **This repo uses Rojo**, for three reasons:

1. **Live two-way sync is a liability for code, not a feature.** Argon's pitch is
   continuous Studio→file sync. That directly invites editing scripts in Studio,
   which this project forbids because those edits are unreviewed and undiffable.
   Syncback gives the same benefit for geometry as a deliberate, inspectable step.
2. **Argon's two-way sync has a reported reliability history** — non-script
   objects not syncing back, partial writes, and sync latency degrading from
   instant to minutes over a session. Some may be fixed; the repo does not say.
3. **Rojo is 12× the community.** For a repo other people clone, the tool with
   the most documentation and the most people who can answer a question wins.

Argon is a reasonable choice for someone who genuinely builds inside Studio all
day and accepts the trade. Lync is the most niche of the three but is the most
recently released. Neither is an MCP — that is a separate layer, and this repo
uses both a sync tool and an MCP.

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

### "If Studio has an MCP, why keep Rojo?"

Reasonable question, and the answer is short: **they solve different problems and
neither replaces the other.**

The Studio MCP lets an agent read and edit the *live data model*. Those edits
exist in the Studio session and, once saved, inside a binary `.rbxl`. They are not
files. They do not diff, they do not merge, they cannot be code-reviewed, and two
people cannot work on them at once.

Rojo is what makes this a repo you can share. Code lives as `.luau` on disk, in
git, reviewable in a pull request. That is the entire reason a friend can clone
this and contribute.

Use both, for what each is good at:

| Job | Tool |
|---|---|
| Writing and reviewing Luau | files + Rojo |
| Reading the live tree, running code, playtesting | Studio MCP |
| Building geometry by hand | Studio, captured with `rojo syncback` |
| Making assets | Blender + BlenderMCP |

Dropping Rojo would mean the game lives in a binary nobody can review. That is
the one thing a shared repo cannot survive.

---

**Verified working** (checked on a real machine, not assumed):

- Rojo 7.7.0 → Studio sync, plugin installed, `rojo build` produces a valid place
- `rojo syncback` round-trips the lobby without touching any code
- `stylua --check` and `selene` pass clean on `src/`
- Roblox Studio installed; `nightdesk.rbxl` opens with the full tree
- Studio's MCP server exists at `%LOCALAPPDATA%\Roblox\mcp.bat`
- BlenderMCP addon live — scene read over the socket, model built, FBX exported
- `tools/blender_export.py` and `tools/models/keyrack.py` both run for real
- `agy` 1.1.22 installed, authenticated, returns correct output from `-p="..."`
- Both MCP servers registered with agy — `agy mcp list` shows Roblox_Studio and
  blender enabled
- **agy can edit game code.** Given `src/shared/Anomalies.luau` and a new entry
  to add, it produced the correct edit in 56s, preserved the four existing
  entries, and the result passed `selene` and `stylua --check` unchanged.
- **agy can drive Blender through MCP.** Asked for the scene contents and the
  triangle count of `KeyRack`, it returned `Camera, Cube, KeyRack, Light` and
  `360` — a number it could only get by querying the live scene and running
  code in it.

**Verified broken:**

- **Gemini CLI (`@google/gemini-cli` 0.42.0)** — server returns
  `UNSUPPORTED_CLIENT` and instructs you to migrate to Antigravity. Dead, not
  misconfigured.
- **`agy -p` with tools** — print mode cannot prompt for permissions, so it
  soft-denies them and produces nothing. Use interactive `agy`. Also note the
  prompt must be attached as `-p="..."`; a bare `-p` reading stdin just prints
  help.

**Known-limited, cause understood:**

- `agy -p` (print mode) cannot complete tool-using tasks — it soft-denies every
  permission because it cannot prompt. Use interactive `agy`. Not a bug in this
  setup.

**Not yet run end to end:**

- Interactive `agy` driving a real task through the Studio MCP — needs a human at
  the permission prompt, so it has not been driven here.
- A full playtest. The place opens and the tree is correct; nobody has pressed
  Play and judged whether the loop is fun.

Fix what breaks rather than assuming you did it wrong.
