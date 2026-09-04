# Project Memory: Nightdesk (Highway Motel Anomaly Horror)

This file persists the complete architectural state, horror systems, mob meshes, and engineering invariants across all development sessions and terminals.

---

## 1. Project Overview & Setting
* **Title:** Nightdesk
* **Genre:** Co-op Highway Motel Anomaly Horror
* **Engine:** Roblox Luau + Rojo + Future Technology Lighting
* **Setting:** Crestview Highway Motel, Pacific Northwest Highway 9, 2:00 AM heavy rainstorm
* **Core Loop:**
  1. Stand behind reception desk in First-Person FPS mode (`WASD` walk + 360° mouse look + center crosshair).
  2. Inspect arriving cinematic human guests using physical investigation tools (Bell, Ledger Clipboard, Rotary Phone, UV Blacklight, Intercom Mic).
  3. Adjudicate verdicts with physical Admit `[Z]` and Refuse `[X]` stamps.
  4. Perform motel facility chores (brewing espresso for Sanity, resetting tripped hallway breakers during blackouts, vending sodas).
  5. Spend takings in the between-shift Motel Renovation & Security Shop.

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

## 3. Directory Map
```
nightdesk/
├── AGENTS.md                     <-- Auto-loaded agent rules & memory (Always active)
├── PROJECT_MEMORY.md             <-- Standalone persistent reference
├── default.project.json          <-- Rojo place configuration
├── README.md                     <-- Start here if you are new to the repo
├── docs/ROBLOX.md                <-- Roblox technical constraints & facts
├── docs/PIPELINE.md              <-- Toolchain wiring; what is verified vs broken
├── docs/PROMPT.md                <-- Copy-paste session starters
├── src/
│   ├── shared/
│   │   ├── Anomalies.luau        <-- 42 anomaly definitions & roll tables
│   │   ├── Remotes.luau          <-- Authoritative RemoteEvent declarations
│   │   ├── Upgrades.luau         <-- Shop upgrade items, prices, & multipliers
│   │   └── Types.luau            <-- Shared type declarations
│   ├── server/
│   │   ├── init.server.luau      <-- Server bootstrapper & session lifecycle
│   │   ├── BuildLobby.luau       <-- 3D motel architecture generator
│   │   ├── Shift.luau            <-- 5-night shift loop, verdicts, breaker logic
│   │   ├── Shop.luau             <-- Takings economy & purchase verification
│   │   └── State.luau            <-- Player profile state container
│   └── client/
│       ├── init.client.luau      <-- First-Person FPS setup & crosshair
│       ├── Viewmodel.luau        <-- Animated clerk suit arms & tool poses
│       ├── GuestRenderer.luau    <-- Sculpted anatomical human mobs & 6 horror archetypes
│       ├── DeskProps.luau        <-- ProximityPrompts & click interactions
│       ├── DeskCamera.luau       <-- [F] Document zoom & [C] CCTV monitor
│       ├── DeskUI.luau           <-- Top HUD & [G] Intercom interrogation modal
│       ├── ShopUI.luau           <-- Between-shift renovation shop interface
│       ├── Atmosphere.luau       <-- 2:00 AM fog, rain audio, dynamic footsteps
│       └── Theme.luau            <-- Retro CRT palettes & fonts
└── tools/
    ├── blender_export.py         <-- Roblox-ready FBX export (handles scale/transform/budget)
    └── models/
        ├── keyrack.py            <-- Procedural key rack asset builder
        └── deskbell.py           <-- Procedural bell asset builder
```

---

## 4. Subagent Roster & Roles
* **`world_architecture_agent`**: Builds motel geometry, reception desk, hallways, lighting fixtures, and rain emitters.
* **`character_horror_mesh_agent`**: Builds the blocky guest kit -- hair meshes, face textures, suit material variants, and the per-tier anomaly variants of each.
* **`gameplay_systems_agent`**: Maintains interaction tools, server-authoritative economy, remotes, and shift progression.
* **`psychoacoustic_audio_agent`**: Engineers spatial 3D soundscapes, rain on glass, electrical hums, and footsteps.
* **`horror_qa_judge`**: Executes live Roblox Studio visual audits using `visual-playtest-qa`.

---

## 5. Non-Negotiable Rules
1. **Never edit scripts inside Roblox Studio.** All code lives in `src/` and reaches Studio via Rojo.
2. **Server owns verdicts and economy.** Client only renders tells and sends intent.
3. **Format with `stylua src/ tools/` and lint with `selene src/ tools/`.**
