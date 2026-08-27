# Building on Roblox properly

Reference for anyone — human or agent — working in this repo. Written to remove
guessing. Where something is uncertain it says so rather than inventing a number.

---

## 1. The mental model

A Roblox experience is **one tree, replicated**. `game` is the DataModel root;
everything is an `Instance` in it. The server holds the authoritative tree. Each
client holds a partial copy.

What replicates, and which way:

| Container | Server has | Client has | Notes |
|---|---|---|---|
| `Workspace` | yes | yes | physical world, streamed |
| `ReplicatedStorage` | yes | yes | shared modules, remotes |
| `ServerScriptService` | yes | **no** | server code, never sent to clients |
| `ServerStorage` | yes | **no** | server-only assets |
| `StarterPlayer.StarterPlayerScripts` | yes | copied into player | client code |
| `StarterGui` | yes | copied into player | UI templates |

A `Script` runs on the server. A `LocalScript` runs on a client. A `ModuleScript`
runs wherever it is required from — the same module file required by both sides
executes twice, in two separate memory spaces, sharing nothing at runtime.

Under Rojo, `init.server.luau` becomes a `Script`, `init.client.luau` becomes a
`LocalScript`, and a bare `Name.luau` becomes a `ModuleScript`.

---

## 2. The trust boundary — the thing that decides whether your game survives

**Assume every client is hostile.** Not most. Every one. Exploiters run modified
clients that can call any RemoteEvent with any arguments, read any value the
client holds, and modify any local state.

The rules that follow from that:

- **Every decision that creates or destroys value happens on the server.** Money,
  items, progress, score, unlocks, hit registration. No exceptions.
- **RemoteEvents carry intent, never outcomes.** The client says "I pressed
  admit", not "I earned 40". Validate the shape *and* the meaning of every
  argument — `typeof(x) ~= "boolean" then return`.
- **Rate-limit remotes.** A client can fire one thousand times a second. Track
  last-call time per player and drop the excess.
- **The client will know anything it renders.** If the player must see it, the
  client has it, and a memory scanner can read it. This is not a leak to fix —
  it is a fact to design around. Protect the *verdict*, not the *stimulus*.

That last point is worth dwelling on for this game specifically: the anomaly's
tell has to reach the client, because the player looks at it. What must not reach
the client is whether that tell counts, and what it pays.

**RemoteFunction vs RemoteEvent:** prefer `RemoteEvent`. A `RemoteFunction`
invoked on a client can hang forever if that client never returns, blocking the
calling thread. Server→client `RemoteFunction` is a footgun; avoid it.

---

## 3. Luau, and how it differs from Lua

Luau is Lua 5.1 plus a gradual type system and a lot of ergonomics.

```luau
--!strict                      -- turn on real type checking, per file

local n: number = 5
n += 1                          -- compound assignment
local s = `Guest {n} arrived`   -- string interpolation, backticks
for i, v in someTable do end    -- generalized iteration, no ipairs/pairs needed

type Guest = { name: string, anomaly: Anomaly? }   -- ? means optional
export type Anomaly = { id: string, tell: string } -- export to other modules
```

`--!strict` at the top of every file. It costs nothing at runtime and catches the
class of bug that otherwise shows up as a nil index three systems away.

Things that bite:

- `task.wait(n)` returns **actual** elapsed time, not `n`. Never accumulate it as
  if exact.
- Use `task.spawn` / `task.defer` / `task.delay`, not the deprecated `spawn`,
  `delay`, `wait`.
- `:GetService("X")` always, never `game.X`.
- `WaitForChild` on anything the client might not have yet. With streaming on,
  that is most of `Workspace`.

---

## 4. Persistence

`DataStoreService` is the only durable storage. It is a key-value store with
rate limits, and it will fail sometimes — treat every call as fallible.

**Do not hand-roll this.** Use [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore)
(the successor to ProfileService, same author). It gives you the three things a
naive implementation gets wrong:

1. **Session locking.** Without it, the same player loaded on two servers
   produces duplicated items and lost progress. ProfileStore writes a lock token
   and hands ownership over cleanly.
2. **Retry logic** with backoff on the DataStore's transient failures.
3. **Autosave** on a timer, so a crash costs seconds not hours.

Whatever you use:

- `UpdateAsync` for anything read-modify-write. `SetAsync` overwrites blindly and
  loses concurrent changes.
- **`game:BindToClose`** is mandatory. `Players.PlayerRemoving` does not fire
  reliably on server shutdown; without BindToClose you lose the last session of
  every player on every restart.
- Never store a table you cannot version. Put a `schemaVersion` field in from day
  one — migrating data you did not version is genuinely painful.

---

## 5. Performance

**Instance streaming** (`Workspace.StreamingEnabled`) is on by default for new
places. The client only holds instances near the player.

- `StreamingTargetRadius` — start at **256 studs**, lower it until quality drops.
- Aim for **under 50,000 instances** in the loaded area around a player.
- With streaming on, `WaitForChild` is not optional. Parts outside the radius do
  not exist on the client at all.

What actually costs you:

| Cost | Cause | Fix |
|---|---|---|
| Frame rate | too many parts rendering | fewer, larger parts; streaming |
| Memory | high-res textures, instance count | 1024×1024 textures, cull instances |
| Network | chatty remotes, big payloads | batch, send deltas not state |
| Server CPU | per-frame loops over players | event-driven, not `RunService.Heartbeat` |

Unions (CSG) are expensive — prefer real meshes from Blender for anything
complex. `Anchored = true` on everything that does not move; unanchored parts
cost physics simulation forever.

For a small game none of this matters yet. It matters the moment you have a real
map. Do not pre-optimise, but do not build 200,000 unanchored parts either.

---

## 6. Assets — every route, honestly compared

### 6a. Roblox's own generative AI

`GenerationService:GenerateModelAsync()` — text (and optionally image) to a 3D
model, powered by **Cube 3D**, Roblox's 1.8B-parameter 3D foundation model
trained on ~1.5M assets. Output structure is controlled with a `PredefinedSchema`
or a custom `SchemaDefinition`, and it can produce multi-part functional models,
not just static props.

- Docs: [GenerationService](https://create.roblox.com/docs/reference/engine/classes/GenerationService#GenerateModelAsync)
- Runs **in-experience**, which is the interesting part — you can generate at
  runtime, not only at authoring time.
- Status has moved through beta; check the current docs before relying on it in
  production.

Studio also ships **Assistant**, a **Material and Texture Generator**, and
**Code Assist** built in.

### 6b. Blender — the route this repo uses

Full control, no per-asset cost, works offline. Use `tools/blender_export.py`
rather than Blender's export menu; it handles the three traps below.

**Verified working in this repo** — exported the default cube to a valid
15KB FBX, correct triangle count, scene left untouched.

| Trap | Symptom | Handled by the script |
|---|---|---|
| FBX scale | model lands 100× too large | exports at `global_scale=0.01` |
| Unapplied transforms | model arrives skewed | baked onto a temp duplicate |
| Triangle budget | Studio refuses the import | counted and reported first |

**Hard limits:**

- **21,000 triangles** per MeshPart, single import
- **~10,000** through Asset Manager batch import — target this, it works for both
- **4,000** for rigid accessories
- Textures **1024×1024 or smaller**; larger gets downsampled anyway
- Geometry watertight, no zero-thickness faces, quads where possible

### 6c. The BlenderMCP addon's built-in asset sources

The [BlenderMCP addon](https://github.com/ahujasid/blender-mcp) already installed
here exposes four asset routes an agent can drive directly. All four are
**disabled by default** — enable each with its checkbox in the BlenderMCP sidebar
panel (`N` → **BlenderMCP** tab).

| Source | What it gives | Kind |
|---|---|---|
| **PolyHaven** | HDRIs, PBR textures, models — free, CC0 | library |
| **Sketchfab** | large model library, mixed licences | library |
| **Rodin** (Hyper3D) | text/image → 3D | generative |
| **Hunyuan** | text/image → 3D | generative |

PolyHaven is the one to reach for first: CC0 means no licence problem, and its
PBR textures are genuinely good for the grimy-interior look this game needs.

**Check the licence on anything from Sketchfab before it ships.** "Free to
download" is not "free to publish in a monetised experience".

### 6d. External generators

Meshy, Tripo, 3D AI Studio and similar do text/image → 3D with Roblox-aware
export. Meshy advertises a one-click Roblox bridge that sends GLB to Creator Hub
with textures and scale preserved. Useful; not tested here.

Whatever generates it, the triangle budget in 6b still applies. AI generators
routinely emit 100k+ triangle meshes that Studio will reject — plan to decimate.

### 6e. Creator Store

Free and paid models made by other people. Fastest route, and the one that makes
your game look like everyone else's. Fine for a prop you will never see closely,
wrong for anything that carries your game's identity.

**Never insert a Creator Store model without opening it first.** Free models are
a known malware vector — scripts inside them can create backdoors, insert
`require()` calls to remote asset IDs, or hook remotes. Delete every script you
did not write.

### 6f. Choosing

- **Identity assets** (the motel desk, the lobby, anything on the thumbnail) —
  Blender, by hand.
- **Filler props** (mugs, chairs, signage) — PolyHaven or a generator, decimated.
- **Textures** — PolyHaven, or Studio's Material Generator.
- **Runtime-generated content** — `GenerateModelAsync`, if it fits the design.

---

## 7. Atmosphere: lighting and audio

For this game specifically, **atmosphere is the product**. Animal Hospital sits
at #2 on the platform on the strength of unease, not systems.

- **`Lighting.Technology = "Future"`** — real shadows and per-pixel lights. Set
  in `default.project.json` already. Costs performance; worth it here.
- `Atmosphere` instance for depth-fog haze; `ColorCorrection` and `Bloom` for
  grade. Subtle beats dramatic.
- A single flickering `SpotLight` in a corridor does more than ten static ones.
- **Spatial audio**: `Sound` parented to a `BasePart` or `Attachment` gets 3D
  falloff. Tune `RollOffMinDistance` / `RollOffMaxDistance`. Sound that follows
  the player everywhere reads as a menu, not a room.
- `SoundService.RespectFilteringEnabled = true` (set in the project file) so
  client-played sounds do not replicate to everyone.

Silence is a tool. Ambience that never stops stops being heard.

---

## 8. Testing

- **Studio Play** (F5) — server and client in one process. Fastest loop, hides
  replication bugs.
- **Play Here** — spawns at camera position.
- **Test tab → Clients and Servers** — run 2+ real clients against a local
  server. **This is where replication bugs actually appear.** Use it before
  believing any multiplayer feature works.
- Server-only prints go to the **Server** output; client prints to **Client**.
  Set the output filter or you will misread which side broke.

There is no unit test harness in this repo yet. When there is, TestEZ is the
conventional choice.

---

## 9. Traps that cost hours

- **Editing scripts in Studio.** They are destroyed on the next Rojo sync and
  invisible to git. Everything real lives in `src/`.
- **`Players.PlayerRemoving` on shutdown** — unreliable. Use `BindToClose` too.
- **`task.wait()` drift** — returns actual elapsed, not requested.
- **`WaitForChild` without a timeout** — hangs forever silently. Pass a timeout
  and handle nil.
- **Unanchored parts** — physics cost forever. `Anchored = true` by default.
- **RemoteFunction to a client** — can hang the server thread indefinitely.
- **Free models with scripts** — malware vector. Read before inserting.
- **Wildcards in agy path permissions** — crashes with "globs not supported".
  Directory rules are already recursive.
- **`roblox.yml` and `sourcemap.json`** are generated per clone and gitignored.
  If the LSP says `game` is undefined, regenerate rather than edit.

---

## 10. Sources

Everything above traces to one of these, or to something verified on this machine
during setup.

- [Instance streaming](https://create.roblox.com/docs/workspace/streaming) — Roblox docs
- [Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications) — Roblox docs
- [GenerationService](https://create.roblox.com/docs/reference/engine/classes/GenerationService#GenerateModelAsync) — Roblox docs
- [Introducing Roblox Cube](https://about.roblox.com/newsroom/2025/03/introducing-roblox-cube) — Roblox newsroom
- [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) — MadStudioRoblox
- [BlenderMCP](https://github.com/ahujasid/blender-mcp) — ahujasid
- [Rojo](https://rojo.space/docs/v7/) — official docs

Where this document states a number, it came from one of those. Where it states a
judgement — "silence is a tool", "atmosphere is the product" — that is opinion
formed from the market analysis, and you are free to disagree with it.
