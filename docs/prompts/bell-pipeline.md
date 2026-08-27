# Prompt: full-pipeline test (Blender → Studio)

Paste into `agy --model gemini-3.7-flash-high` from the repo root.

Exercises all four tools in one task, and asks the agent to judge which asset
route is actually better rather than assuming.

---

```
Read docs/ROBLOX.md sections 5 and 6 before touching assets. Roblox Studio is
open with the nightdesk place loaded, and Blender is running with the BlenderMCP
server started. You have both MCP servers available.

TASK 1 - make the game visible.

The lighting is currently set for 2am and nothing is visible while building.
Switch it to daytime in default.project.json: raise ClockTime, Brightness and
the ambient values enough to actually see the lobby. Leave Technology as Future.

Add a short comment above the block saying these are development values and the
night-time values that shipped before were ClockTime 2 / Brightness 0.4 /
Ambient 0.03,0.03,0.04, so they can be put back for the atmosphere pass.

TASK 2 - model a front desk bell.

A motel front desk needs a bell - the small dome-and-plunger kind a guest slaps
to get your attention. Build it in Blender using the blender MCP server.

Requirements:
- Follow the pattern in tools/models/keyrack.py: the SCRIPT is the source. Write
  tools/models/deskbell.py so re-running it reproduces the mesh exactly. Do not
  rely on a saved .blend.
- Under 1,000 triangles. It is a small prop.
- Proportions exaggerated for game viewing, not real-world accurate. Read the
  comment at the top of keyrack.py about why.
- Join it into a single mesh before export - Roblox imports one MeshPart.
- Export with tools/blender_export.py. Do NOT use Blender's export menu; the
  script handles the 0.01 scale factor, applies transforms on a duplicate, and
  checks the triangle budget.
- Take a viewport screenshot and actually look at it before you call it done. If
  it does not read as a bell, fix it and look again.

TASK 3 - build the same bell a second way, out of Roblox parts.

Using the Roblox_Studio MCP server, build a bell out of primitive Parts directly
in the live data model, placed on the counter in Workspace.Lobby. Anchor
everything. Name the model DeskBell_Parts.

TASK 4 - judge which route is better, and say why.

Compare the two honestly on:
- Did each route actually complete, or did something block it? If you could not
  import the FBX into Studio through MCP, say so plainly - that is a real
  finding, not a failure to hide.
- Triangle cost of each.
- How each one looks.
- How much work each was.
- Which one you would use for a prop like this, and which for something larger.

Do not pretend a route worked if it did not.

CONSTRAINTS
- All file changes go in the repo under tools/ and default.project.json. Never
  edit scripts inside Studio.
- Do not touch anything in src/. This task adds an asset and changes lighting;
  it does not change game logic.
- The project must still build. Run: rojo build -o /tmp/check.rbxl
- Run stylua src/ and selene src/ before you finish.

REPORT
Tell me the triangle count of each version, which route you recommend and why,
and anything you deliberately left out.
```

---

## Expected, so you can catch a bluff

| claim | check it against |
|---|---|
| "exported the FBX" | `assets/DeskBell.fbx` exists and is non-zero |
| "script is the source" | `tools/models/deskbell.py` reruns to the same triangle count |
| "built parts in Studio" | `Workspace.Lobby.DeskBell_Parts` exists in the live tree |
| "under 1,000 triangles" | the export script prints the real count |

The FBX-into-Studio step is the one most likely to block — Roblox's 3D Importer
is a GUI flow and may not be reachable over MCP. If the agent claims it imported
the mesh, ask it which tool call did that.
