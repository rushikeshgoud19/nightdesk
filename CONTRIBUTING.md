# Working on nightdesk with other people

`README.md` gets one person set up. This file is about several people not
standing on each other.

---

## How the sharing actually works

There is no live shared editor, and that is deliberate.

The entire world is built from code. `src/server/BuildLobby.luau` constructs 284
parts on server boot; `src/client/GuestRenderer.luau` builds every guest. Nothing
of consequence is placed by hand in Studio. So **git is the shared world** — pull
and you have exactly what everyone else has, down to the last part.

Each person runs their own `rojo serve` and their own Studio. Studio is a
viewport onto your checkout, not a place anyone else can see into.

### Roblox Team Create is off, on purpose

Team Create and Rojo fight, and Rojo wins. Scripts edited inside Studio are
destroyed on the next sync and never reach git — `docs/ROBLOX.md` §9 has been
warning about this since before anyone lost work to it.

If you want Team Create later, the geometry has to move out of `BuildLobby.luau`
and into the place file first. That is a real project, not a setting.

### Seeing each other's work

- **Code** — push, and the other person pulls. Seconds.
- **Playing together** — publish the place and share the link. That is the only
  way two people are in the same world at the same time.

---

## The one rule that will cost you work

**Never edit a script in Roblox Studio.** Not to try something, not for one line.

Rojo overwrites `ServerScriptService`, `StarterPlayerScripts` and
`ReplicatedStorage` from `src/` on every sync. Your edit vanishes and git never
saw it, so there is nothing to recover.

Everything real lives in `src/`. Edit there, let Rojo push it across.

---

## Day to day

```bash
git pull --rebase origin master
rojo serve
```

Branch when the change is more than a few lines, so someone else can read it
before it lands:

```bash
git checkout -b guest-idle-animation
```

Small and obviously-correct changes can go straight to `master`. Pull often
either way — the merge conflicts in this repo are almost always two people
editing the same builder function.

## Before you push

All four, every time. Two of them exist because a bug got through the other two.

```bash
stylua src/ tools/
```

```bash
selene src/ tools/
```

Two warnings are expected — unused parameters in `buildHorrorArchetypes`. Do not
add more.

```bash
rojo build -o nightdesk.rbxl
```

Then **press Play and read the Output window.** A clean build proves the files
parse. It proves nothing about whether the game runs.

Look for:

```
[nightdesk] server initialized with master motel lobby
```

If that line is missing, the server bootstrap died partway and you have no lobby,
no shift, and no persistence. `src/server/init.server.luau` calls `BuildLobby()`
unprotected, so anything that throws in there takes the rest of the file with it.

This is not hypothetical. It has happened twice:

- **Lighting** — `Color3` in the project file is floats `0-1`. Someone wrote
  `[35, 35, 45]` meaning RGB. Roblox clamped it to pure white, ambient flooded
  the scene flat, and every shadow disappeared. Built clean. Linted clean.
- **Materials** — `MaterialVariant.BaseMaterial` carries Plugin security, so
  creating variants from a game script throws. It took the whole lobby build down
  with it. Built clean. Linted clean.

Neither was catchable without either looking at the screen or reading the value
back out of the built place. When you touch lighting, materials, or anything else
`default.project.json` owns, do one of those two things.

---

## MCP servers

`.mcp.json` in the repo root configures the Blender MCP for everyone. Approve it
when your client asks.

The Roblox Studio MCP is **not** in there. Its executable path contains a Studio
version hash that differs per machine:

```
C:\Users\<you>\AppData\Local\Roblox\Versions\version-<hash>\StudioMCP.exe
```

Add it to your own client config, and re-point it after a Studio update.

### Things that will waste your afternoon

- **A minimized Studio window makes `screen_capture` hang.** No error, no
  message, just a timeout that looks like the MCP is broken. Restore the window.
  Studio's real main window is also not always the one `MainWindowHandle`
  reports.
- **Never hold the camera in a `RunService.Heartbeat` loop while capturing.**
  `screen_capture` sets the camera and waits for it to settle. A loop that
  rewrites `CFrame` every frame means it never settles, and the call times out.
- **`require()` caches per instance.** Rojo replacing a module's `Source` does
  not re-run it. Clone the `ModuleScript` and require the clone to get current
  code.
- **Blender MCP needs Blender open.** The `blender-mcp` bridge process running is
  not enough — the addon lives inside Blender and there has to be a Blender
  window for it to live in.

---

## Where things live

| Path | What |
|---|---|
| `src/server/` | Server. Authority over money, verdicts, persistence. |
| `src/client/` | Client. Rendering and input only. |
| `src/shared/` | Both sides. Anomaly catalogue, remotes, materials. |
| `default.project.json` | The place itself: services, Lighting, MaterialVariants. |
| `tools/` | Blender export, mesh prep, Mistral. Run outside the game. |
| `docs/` | `ROBLOX.md` for engine facts, `ASSETS.md` for generated meshes. |

`AGENTS.md` holds the engineering rules and applies to people as much as agents.
Read it before your first change.

## Secrets

`.env` is gitignored. Copy `.env.example`, fill it in locally, and never paste a
key into a chat, an issue, or a commit.
