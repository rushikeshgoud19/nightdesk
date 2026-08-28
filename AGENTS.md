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

## 2. Cinematic Horror Mobs & Custom Humanoid Mesh Architecture

Guests are **high-fidelity sculpted anatomical human mob models** (NOT blocky default avatars):
* **Facial Geometry**: Chiseled zygomatic cheekbones, defined mandible jawline, sculpted nose bridge/nostrils, and anatomical ear helixes.
* **Eyes & Lids**: Multi-layer eye meshes with depth-layered iris discs (hazel, blue, amber, green) and asynchronous eyelid blinking cycles.
* **Executive Tailored Attire**: 3D V-neck collared shirts, tailored notch lapels, silk neckties with 3D Windsor knots, gold tie bars, triple horn buttons, leather belt with brass buckle, and polished oxford dress shoes.
* **Articulated Hands & Briefcase**: 5-finger articulation with proximal/distal phalanges and knuckles holding an executive leather briefcase.
* **The 6 Core Cinematic Horror Mob Archetypes**:
  1. *The Flayed Mimic*: Desaturated skin, smooth fingerprint spirals, and glowing UV crimson suture neck stitches.
  2. *The Mandela Alternate*: Subcutaneous jaw dislocation stretching ~25cm downward into an ear-to-ear void with 16 razor teeth.
  3. *The Broken Cervical*: 85° lateral head snap with exposed cervical vertebrae bones and violent micro-spasms.
  4. *The Cavernous Hollow*: Pitch-black orbital eye void sockets with glowing red embers and streaming dark tears.
  5. *The Drowned Drifter*: Waterlogged swollen grey-cyan flesh, seaweed strands, dripping water particles, and wet floor puddles.
  6. *The Void Silhouette*: 100% light-absorbing pitch-black 3D silhouette with piercing electric cyan eyes and void smoke aura.

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
