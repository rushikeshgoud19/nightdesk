# nightdesk — instructions for agents

A co-op anomaly-horror game on Roblox. You work the night desk of a highway motel
and decide which guests are real. Between shifts you spend the takings on the
motel itself.

> **MANDATORY SESSION BOOTSTRAP**: At the start of every new session or terminal,
> you MUST immediately read and honor `PROJECT_MEMORY.md` and `docs/ROBLOX.md` to
> maintain absolute architectural continuity.

---

## Master Architecture & Memory State

### 1. Architectural Layout
```
src/
├── shared/                       -- ReplicatedStorage.Shared
│   ├── Anomalies.luau            -- 42 anomaly catalog & roll logic
│   ├── Remotes.luau              -- Single wire authority for all RemoteEvents
│   ├── Upgrades.luau             -- Motel shop upgrade definitions & prices
│   └── Types.luau                -- Shared strict type signatures
├── server/                       -- ServerScriptService.Server (AUTHORITY)
│   ├── init.server.luau          -- Bootstrapper & session lifecycle
│   ├── BuildLobby.luau           -- Server-built 3D motel architecture, lighting, & props
│   ├── Shift.luau                -- Shift loop, 5-night scaling, verdicts, breaker/coffee events
│   ├── Shop.luau                 -- Takings economy, upgrade purchases, and inventory
│   └── State.luau                -- In-memory & DataStore player profile state
└── client/                       -- StarterPlayerScripts.Client (RENDERING & INPUT ONLY)
    ├── init.client.luau          -- First-person FPS camera, WASD controls, & crosshair
    ├── Viewmodel.luau            -- First-person clerk suit arms, sway, bell reach, stamp slams
    ├── GuestRenderer.luau        -- Sculpted anatomical human mobs & 6 horror archetypes
    ├── DeskProps.luau            -- ProximityPrompts & click interactions on all desk props
    ├── DeskCamera.luau           -- [F] Document inspect modal & [C] multi-channel CCTV monitor
    ├── DeskUI.luau               -- Top HUD, [G] intercom questioning modal, dialogue subtitles
    ├── ShopUI.luau               -- Retro between-shift motel renovation & security upgrade shop
    ├── Atmosphere.luau           -- Volumetric 2:00 AM fog, rain particles, lighting, & footsteps
    └── Theme.luau                -- Vintage CRT palette & typography styling
```

---

## 2. Guest Visual Doctrine -- Blocky Silhouette, Cinematic Surface

Reference: `reference/guest-kit.png`. Look at it before touching a guest.

Guests are **classic Roblox avatar proportions rendered at high fidelity**. The
silhouette is blocky and native to the platform. Everything that sells them is
*surface*, not anatomy.

> **This supersedes the previous doctrine, as of 4 September 2026.** The project
> used to specify sculpted anatomical humans -- zygomatic cheekbones, mandible
> jawlines, layered iris discs, proximal and distal phalanges -- and
> `GuestRenderer.luau` implemented roughly 2,500 lines of it. That direction is
> withdrawn. It fought the engine, it read as uncanny rather than frightening,
> and it turned every visual anomaly into a geometry problem.

### What a guest is made of

| layer | rule |
|---|---|
| Rig | Blocky. Rectangular torso, block limbs, rounded-cube head. No sculpted anatomy, no fingers. |
| Face | A **texture on the head**, not geometry. Simple black eyes, drawn mouth. |
| Hair | A sculpted mesh accessory, and the highest-detail thing on the model. |
| Clothing | PBR surface. Visible fabric weave on the suit, leather sheen on shoes, metal on the buckle. |
| Palette | Muted. Black suit, cream shirt, warm skin, dark hair. |

### Why this is an upgrade, not a compromise

- **It is what a high-quality Roblox game looks like.** Blocky was never the
  flaw; *untextured* was. The playtest complaint was "neon blocks" -- the fix is
  the texture, not the anatomy.
- **Every tier-1 anomaly becomes a texture swap** instead of a 0.03-stud
  geometry nudge. Pixel-exact, trivially authorable, and actually visible at
  conversation distance.
- **A guest assembled from a seeded choice of parts is deterministic by
  construction**, which is exactly what Section 2 co-op needs. The old renderer
  drew from unseeded `math.random` in fifteen places.

### How anomalies are expressed

| tier | mechanism |
|---|---|
| 1 — subtle | Face texture variants and colour tints |
| 2 — noticeable | Swapped accessories and materials, changes between observations |
| 3 — overt | Geometry distortion of the blocky parts themselves |

### The 6 core archetypes, in this visual language

1. *The Flayed Mimic* — desaturated skin tint, UV-only crimson suture texture across the neck seam.
2. *The Mandela Alternate* — the head block's lower half dropped and stretched into a dark void with teeth.
3. *The Broken Cervical* — head block rotated 85° laterally on the neck joint, with micro-spasm jitter.
4. *The Cavernous Hollow* — face texture with black orbital voids, ember glow, dark streaks running down.
5. *The Drowned Drifter* — darkened wet material variant on every clothing part, drip particles, floor puddle.
6. *The Void Silhouette* — every part black and light-absorbing, cyan eyes on the face texture only.
---

## 3. Core Systems & Control Scheme

| Control | Action | System Description |
| :--- | :--- | :--- |
| **`W / A / S / D`** | Free FPS Walk | Atmospheric walkspeed (13 studs/s) behind desk, in office, & through lobby. |
| **`Mouse`** | 360° Look | Centered crosshair reticle for aiming at physical props and guests. |
| **`[E]` / Click** | Service Bell | Depresses bell plunger, chimes audio, and animates viewmodel arm reach. |
| **`[F]` / Click** | Inspect Ledger | Opens high-contrast 2D/3D registration document modal with two-hand lift. |
| **`[G]`** | Intercom Mic | Opens 3-question interrogation dialogue menu (*purpose, license plate, mirror*). |
| **`[T]` / Click** | Rotary Phone | Dials assigned room to check occupancy/vacancy (whispers on anomalies). |
| **`[Q]`** | UV Blacklight | Toggles purple UV flashlight revealing occult marks vs genuine Crestview seals. |
| **`[C]`** | CCTV Monitor | Cycles through security camera feeds (*Highway Parking Lot, Hallway, Lounge*). |
| **`[Z]` / Click** | ADMIT Stamp | Slams green admit stamp down onto desk; fires server verdict. |
| **`[X]` / Click** | REFUSE Stamp | Slams red refuse stamp down onto desk; fires server verdict. |
| **`[E]` (Office)** | Coffee Maker | Brews fresh espresso to restore **+25% Sanity** once per shift. |
| **`[E]` (Hallway)**| Breaker Box | Resets hallway electrical fuse box during blackout events. |
| **`[E]` (Lounge)** | Vending Machine| Spends **$5** takings for cold soda (+10% Sanity). |

---

## Non-negotiables

**Never edit game logic inside Roblox Studio.** Studio is a viewer and a test
harness here, nothing else. Every script lives in `src/` and reaches Studio
through Rojo. Anything typed into Studio's script editor is destroyed on the next
sync and is invisible to git. If a change needs to happen, it happens in a file.

**The server owns every decision that costs or pays money.** The client renders
what it is told and sends back intent. It never computes a score, a payout, a
fine, or a verdict. Assume the player has full control of their client, because
some of them will.

**Be honest about what the client can see.** The player must perceive the tell to
play, so the tell crosses the wire. Do not write comments claiming otherwise. The
boundary that holds is the verdict and the economy, not the tell.

**Layers, not scaffolding.** Every change leaves the game playable. Do not land a
half-finished system behind a flag and plan to finish it later. If the shape is
not known yet, say so before committing the repo to a direction.

**No compatibility layers.** When something is replaced, the old path is deleted
in the same change. There are no live players to keep working yet, so there is no
excuse for a fallback.

---

## Commands

```bash
rojo serve                      # sync to Studio, leave running
stylua src/ tools/              # format code
selene src/ tools/              # lint code
rojo build -o nightdesk.rbxl    # standalone place file
```

---

## Traps & Invariants
- `roblox.yml` and `sourcemap.json` are generated and gitignored. If LSP claims `game` is undefined, regenerate them rather than editing.
- Roblox `task.wait()` returns actual elapsed time, not requested time. Never accumulate as exact.
- `Players.PlayerRemoving` does not fire reliably on server shutdown. BindToClose is required for persistence.
- Lobby architecture is constructed server-authoritatively on boot via `src/server/BuildLobby.luau`.
- **MaterialVariants cannot be created at runtime.** `MaterialVariant.BaseMaterial`
  carries Plugin security, so a game `Script` that writes it raises "lacking
  capability Plugin". They are declared in `default.project.json` under
  `MaterialService` and reach the place through Rojo. `src/shared/Materials.luau`
  only names them. `BasePart.MaterialVariant` is a plain string and *is* writable
  at runtime -- it is only the variant object that is restricted.
- **`rojo build` and `selene` cannot see a runtime failure.** Both the white-ambient
  lighting bug and the material bug above built clean, linted clean and warned
  about nothing; the lighting one was only visible on screen and the material one
  only in the Output window. After a change to lighting, materials, or anything
  else the project file owns, read the value back out of the built place and
  press Play to confirm `[nightdesk] server initialized` still prints.
