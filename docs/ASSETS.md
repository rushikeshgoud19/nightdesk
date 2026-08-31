# Getting a generated mesh into nightdesk

Verified end to end on this machine, 2026-08-31: a 97,792-triangle GLB went
through the two scripts below and came out as a 10,000-triangle FBX that Roblox
accepts through either import path.

`docs/ROBLOX.md` §6 compares every asset route and is the place to decide *which*
route to use. This file is only the mechanics of the generator route once you
have decided.

---

## 1. Decide whether a generator is right for the asset

From `docs/ROBLOX.md` §6f, unchanged:

- **Identity assets** — the desk, the lobby, anything on the thumbnail — Blender,
  by hand. A generated motel desk makes the game look like everyone else's.
- **Filler props** — mugs, chairs, signage, a statue nobody walks up to —
  generator is fine, and much faster.

nightdesk builds the whole lobby from code today (`src/server/BuildLobby.luau`,
284 parts). A generated mesh is an *addition* to that, not a replacement, and it
needs an asset ID baked into the source before it exists for anyone else.

## 2. Generate

[Tripo3D](https://studio.tripo3d.ai/) takes text or an image and returns a mesh.
Meshy, Rodin and Hunyuan are equivalent for this purpose; the BlenderMCP addon
already installed here exposes Rodin and Hunyuan directly (`N` → **BlenderMCP**
tab, each source has its own checkbox and is off by default).

Download **GLB**. It carries geometry and textures in one file, and
`tools/mesh_prep.py` reads it directly.

**Check the licence before anything ships.** "Free to download" is not "free to
publish in a monetised experience". This applies to Tripo3D's output tiers and to
anything off Sketchfab.

## 3. Prepare and export

Generators routinely emit 100k+ triangles. Roblox refuses anything over 21,000
outright, so the mesh has to come down first.

```bash
blender --background --python tools/mesh_prep.py -- --in downloads/statue.glb --export
```

That does, in order: import → bake transforms → decimate to budget → smart-project
UVs if the generator supplied none → export a Roblox-ready FBX into `assets/`.

Drop `--export` to stop after preparing, and open the result in Blender to look
at it before committing to the shape.

Useful flags:

| Flag | Meaning |
|---|---|
| `--budget N` | triangle target after decimation (default 10,000; refuses above 21,000) |
| `--out DIR` | export directory (default `assets`) |
| `--keep-scene` | do not clear the scene first |

The numbers are not arbitrary and are defined once, in `tools/blender_export.py`:

- **21,000** triangles — Roblox's hard cap on a single MeshPart import
- **10,000** — the Asset Manager batch limit, and therefore the default target,
  so an asset works through either import path
- **1024×1024** textures — anything larger is downsampled anyway;
  `mesh_prep.py` warns when it sees one

`tools/blender_export.py` owns the three FBX traps (100× scale, unapplied
transforms, budget reporting). `mesh_prep.py` calls into it rather than
re-implementing them, so there is one exporter and one set of numbers.

## 4. Import into Studio and get the asset ID

Studio → **Avatar** tab → **3D Importer**, or drag the `.fbx` into the viewport.

Then publish the MeshPart to get an ID: right-click it → **Save to Roblox**. That
ID is what source code references. Without it, the mesh exists only on your
machine and nobody else's checkout can see it.

**Read every script inside anything you did not generate yourself** before it
touches the place. Free models are a known malware vector — see `docs/ROBLOX.md`
§6e.

## 5. Reference it from code

Asset IDs belong in source, next to the code that uses them, the same way the
MaterialVariant IDs live in `default.project.json`. A mesh dragged into Studio
and left there is invisible to git and gone on the next Rojo sync.

`assets/*.fbx` and `*.glb` are gitignored — they are intermediates on the way to
an asset ID. The `.blend` source, if there is one, belongs in git.

---

## What is not solved here

- **No automated Roblox upload.** Step 4 is manual. Roblox's Open Cloud has an
  assets API that could close this; it has not been tried in this repo, so do not
  assume it works.
- **Decimation is `COLLAPSE` at a flat ratio.** Good enough for props. For
  anything with a silhouette that matters, decimate by hand in Blender and pass
  `--budget` high enough that the script leaves it alone.
