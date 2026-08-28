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

## 2. Cinematic Horror Mobs & Anatomical Mesh Pipeline

Guests are **sculpted anatomical human mob models** (NOT blocky avatars):
* **Facial Anatomy**: Chiseled zygomatic cheekbones, defined mandible jawline, sculpted nose bridge/nostrils, and anatomical ear helixes.
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
* **`character_horror_mesh_agent`**: Generates sculpted anatomical human mobs, tailored suits, hair meshes, and analog horror tells.
* **`gameplay_systems_agent`**: Maintains interaction tools, server-authoritative economy, remotes, and shift progression.
* **`psychoacoustic_audio_agent`**: Engineers spatial 3D soundscapes, rain on glass, electrical hums, and footsteps.
* **`horror_qa_judge`**: Executes live Roblox Studio visual audits using `visual-playtest-qa`.

---

## 5. Non-Negotiable Rules
1. **Never edit scripts inside Roblox Studio.** All code lives in `src/` and reaches Studio via Rojo.
2. **Server owns verdicts and economy.** Client only renders tells and sends intent.
3. **Format with `stylua src/ tools/` and lint with `selene src/ tools/`.**
