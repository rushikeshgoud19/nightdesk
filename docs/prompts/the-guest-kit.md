# Section 1 - The Guest Kit

Mega prompt for Antigravity. Self-contained; paste the block below into a fresh
session.

```bash
cd "$HOME/Desktop/nightdesk" && agy --model gemini-3.1-pro-high
```

Thinking model. This is judgement about how a face reads, not typing.

**Reference:** `reference/guest-kit.png`. The agent must open it.

---

```
=============================================================
NIGHTDESK — SECTION 1: THE GUEST KIT
=============================================================

You are working on nightdesk, a co-op anomaly-horror game on Roblox.

BEFORE WRITING ANYTHING:

  1. LOOK AT  reference/guest-kit.png   <-- this is the target. Open it.
  2. READ     AGENTS.md                 -- section 2 is the guest doctrine
  3. READ     PROJECT_MEMORY.md
  4. READ     docs/ROBLOX.md            -- engine constraints, especially the
                                           MaterialVariant trap
  5. READ     docs/ROADMAP.md           -- you are building SECTION 1

Roblox Studio is open with the place loaded and you have the Roblox_Studio MCP
server available. Use it heavily. It is the whole leverage of this section.


-------------------------------------------------------------
1. THE PROBLEM
-------------------------------------------------------------

The room got an art pass. The guests did not.

src/client/GuestRenderer.luau is ~2,500 lines building sculpted anatomical
humans out of parts -- Cheekbone_L, Cheekbone_R, nose bridge, eyelids, finger
phalanges. It fights the engine, it reads as uncanny rather than frightening,
and it makes every visual anomaly a geometry problem.

THE CONSEQUENCE IS NOT COSMETIC. The catalog has 42 anomalies. 18 of them are
visual_face or visual_body. Their tells are things like:

    asymmetric_face   "left eye sits 3 millimetres lower than the right"
    dilated_pupils    "pupils 15% wider than normal for this lighting"
    dark_sclera       "whites of the eyes 10% darker than natural"
    colorless_skin    "flat grey, like the warmth was lifted out"

Expressed as sub-centimetre nudges to hand-built part geometry, at conversation
distance, in a dark room. THEY CANNOT BE PERCEIVED. Eighteen anomalies are
currently unplayable -- not badly made, literally unable to be seen.

This is the same shape of problem the lighting pass solved for the room, and it
has the same fix: change the surface, not the anatomy.


-------------------------------------------------------------
2. THE DIRECTION — READ THE REFERENCE
-------------------------------------------------------------

reference/guest-kit.png is a character turnaround: front, back, side, portrait,
and the kit broken into separate pieces along the bottom row.

WHAT IT ESTABLISHES:

    - BLOCKY SILHOUETTE. Classic Roblox avatar proportions. Rectangular torso,
      block limbs, rounded-cube head. NO sculpted anatomy. NO fingers.

    - THE FACE IS A TEXTURE, NOT GEOMETRY. Two black ovals for eyes, a drawn
      mouth. On the reference guest, blood runs from the eyes and the corners of
      a carved smile -- but that is one anomaly's face, not the base face.

    - THE HAIR IS A SCULPTED MESH and it is the highest-detail thing on the
      model. Layered, with a specular sheen. It is doing most of the work of
      making a block read as a person.

    - THE CLOTHING IS PBR SURFACE. Visible twill weave in the black suit,
      leather sheen on the shoes, brushed metal on the belt buckle, matte cream
      on the shirt.

    - THE PALETTE IS MUTED. Black suit, cream shirt, warm beige skin, dark brown
      hair. Nothing saturated. Nothing neon.

    - IT IS PRESENTED AS A KIT. Hair, head, torso, legs, all separable. That is
      not incidental -- it is the architecture you are building.

BLOCKY WAS NEVER THE FLAW. UNTEXTURED WAS. The playtest verdict on the old
guests was "neon blocks". The fix is the texture and the hair, not the anatomy.


-------------------------------------------------------------
3. WHAT YOU ARE BUILDING
-------------------------------------------------------------

TASK 1 — THE BASE KIT
..............................................................

One modular, blocky guest that matches the reference.

    - Blocky rig. Match the reference's proportions.
    - Head with a FACE TEXTURE applied to the front face. Neutral, human,
      unremarkable -- this is the innocent guest, and most guests are innocent.
    - Hair as a sculpted mesh accessory. Use the Studio MCP `generate_mesh`.
    - Suit, shirt, shoes, belt as PBR surfaces. Use `generate_material` and
      `generate_texture`.

    >> MATERIALVARIANT TRAP, from AGENTS.md: MaterialVariants CANNOT be created
    >> at runtime -- BaseMaterial carries Plugin security and a game Script
    >> writing it raises "lacking capability Plugin". They are declared in
    >> default.project.json under MaterialService and reach the place via Rojo.
    >> BasePart.MaterialVariant is a plain string and IS writable at runtime.
    >> Follow the pattern already in src/shared/Materials.luau.

    The base guest must look like it belongs in the reference image. Judge that
    by capturing it and looking, not by reasoning about it.


TASK 2 — THE KIT AS A SYSTEM
..............................................................

Guests must vary. A motel where eight identical men check in is not a motel.

Build the kit so a guest is ASSEMBLED FROM A SEEDED CHOICE OF PARTS:

    hair mesh  x  face texture  x  suit variant  x  skin tone  x  build

    >> ASSEMBLY MUST BE A PURE FUNCTION OF THE SEED. Same seed in, same guest
    >> out, on every client. This is not decoration -- Section 3 is co-op, where
    >> two players stand at one desk and must see the SAME face. The renderer
    >> you are replacing draws from unseeded math.random in fifteen places,
    >> which is exactly why it cannot survive co-op.
    >>
    >> No unseeded math.random or Random.new() anywhere in guest construction.
    >> Idle animation jitter may stay unseeded. The BUILD may not.

Enough variety that a night of eight guests does not feel like one man in eight
suits. You choose the counts; report them.


TASK 3 — ANOMALIES AS SURFACE, NOT SHAPE
..............................................................

This is the part that unblocks eighteen anomalies. Map the tiers:

    TIER 1 (subtle, 25 in the catalog)  -->  FACE TEXTURE VARIANTS + COLOUR TINT

        asymmetric_face   a face texture with one eye lower
        dilated_pupils    a face texture with larger pupils
        dark_sclera       a face texture with greyed whites
        no_blinking       the blink texture swap simply never happens
        subtle_smile      a face texture with a fixed faint curl
        colorless_skin    desaturated tint on the skin-coloured parts

        Pixel-exact, authorable, and VISIBLE at conversation distance. That is
        the entire point of moving the face into texture space.

    TIER 2 (noticeable, 14)  -->  SWAPPED ACCESSORIES, MATERIALS, AND CHANGES
                                  BETWEEN OBSERVATIONS

        wet clothing      a darkened wet material variant + drip particles
        clothing changes  swap a variant while the player is not looking

    TIER 3 (overt, 3)  -->  GEOMETRY DISTORTION OF THE BLOCKY PARTS

        This is where you deform, and blocky deformation is genuinely nastier
        than sculpted deformation. A head block whose lower half drops 25cm into
        a toothed void is worse than an anatomically modelled jaw.

Then build THE SIX ARCHETYPES in this language. They are specified in AGENTS.md
section 2 -- Flayed Mimic, Mandela Alternate, Broken Cervical, Cavernous Hollow,
Drowned Drifter, Void Silhouette.

    >> The Flayed Mimic's suture marks must be UV-ONLY -- invisible under normal
    >> light, revealed by the UV lamp. That is its tell and the UV tool exists.


TASK 4 — DELETE THE OLD RENDERER
..............................................................

AGENTS.md: "No compatibility layers. When something is replaced, the old path is
deleted in the same change."

The sculpted anatomy in GuestRenderer.luau goes. Not behind a flag, not kept as
a fallback, not left as dead branches. There are no live players to protect.

Keep what still applies -- the arrival and departure choreography, the idle
behaviour timings, and the anomaly ids, which the server sends and the whole
catalog depends on.

    >> DO NOT CHANGE THE ANOMALY IDS OR THE WIRE PAYLOAD SHAPE. The server sends
    >> anomalyId and horrorType; the client renders them. That contract stays.
    >> You are changing HOW a tell is drawn, not WHAT the tells are.


-------------------------------------------------------------
4. DO NOT TOUCH
-------------------------------------------------------------

    - src/server/State.luau
      Persistence is verified working. Leave it alone.

    - Atmosphere.shakeCamera
      Uses Humanoid.CameraOffset deliberately. Writing Camera.CFrame instead was
      a bug that froze the player's view.

    - The input bindings
      Every desk key is bound exactly once. Adding a ContextActionService
      binding beside an existing ProximityPrompt makes both fire and cancel.

    - DeskProps.setVerdictHandler
      Exactly one judge:FireServer call exists in the entire client. Keep it
      that way. GuestRenderer.depart is called from DeskUI.send -- keep that
      call site intact.

    - The Anomalies.rollable pool, the UNOBSERVABLE table, and every anomaly id.

    - SanityUpdate must stay separate from ShiftUpdate.
      The Loadout remote's hasCCTV / hasCoffee gates must stay.
      arrivalToken must stay: never more than one guest arrival in flight.
      The phone's 101-108 room range check must stay.


-------------------------------------------------------------
5. VERIFY BEFORE FINISHING
-------------------------------------------------------------

STEP 1 — Toolchain:

    rojo build -o nightdesk.rbxl
    selene src/ tools/     (2 warnings expected, both unused params in
                            buildHorrorArchetypes -- if you delete that
                            function, expect 0 and say so)
    stylua src/ tools/

STEP 2 — Runtime. NOT OPTIONAL.

    rojo build and selene CANNOT see a runtime failure. The white-ambient
    lighting bug and the MaterialVariant bug both built clean and linted clean.

    Press Play. Confirm "[nightdesk] server initialized" prints and no Lua
    errors appear in Output.

STEP 3 — LOOK AT IT. This is the acceptance test and it is the step most likely
to be skipped.

    Use `screen_capture` with explicit camera_position and look_at_position:

      1. A guest's face at conversation distance across the counter
      2. The same guest full body, standing at the desk
      3. Two different guests side by side
      4. A tier-1 face anomaly next to the innocent face it is a variant of

    Then answer, honestly, from the captures:

      Q1. Does shot 1 look like reference/guest-kit.png, or like a block with a
          picture on it?
      Q2. In shot 3, do they read as two different people?
      Q3. IN SHOT 4, CAN YOU TELL WHICH ONE IS THE ANOMALY?

    >> Q3 IS THE WHOLE SECTION. If you cannot tell, tier 1 is still invisible
    >> and nothing has been fixed. Iterate before you report.

STEP 4 — COMMIT AND PUSH.

    git push origin master is part of finishing. It has been forgotten twice.


-------------------------------------------------------------
6. REPORT
-------------------------------------------------------------

    1. The kit: how many hair meshes, face textures, suit variants, skin tones,
       and how many distinct guests that yields.
    2. Every material and texture you generated, with the description you wrote
       for it.
    3. How a guest is assembled from a seed, and your evidence that the same
       seed produces the same guest twice.
    4. Which of the 18 visual anomalies are now perceivable, and which are not
       yet, named individually. Do not round up.
    5. Line count of GuestRenderer.luau before and after.
    6. Your honest answers to Q1, Q2 and Q3, and which capture each is from.
    7. Anything you deliberately left out.

=============================================================
```

---

## Review checklist - for the Claude session that reviews this

| check | why |
|---|---|
| guests are blocky, matching the reference proportions | sculpted anatomy is withdrawn doctrine |
| the face is a texture, not built geometry | this is what makes tier-1 tells authorable and visible |
| hair is a real sculpted mesh | it is doing most of the work of making a block read as a person |
| suit/shoes/belt carry PBR surface detail | untextured was the flaw, not blocky |
| MaterialVariants declared in `default.project.json`, not created at runtime | runtime creation raises "lacking capability Plugin" |
| guest assembly is a pure function of the seed | Section 3 co-op needs two clients to build the same face |
| no unseeded `math.random` in guest *construction* | idle jitter may be unseeded; the build may not |
| a tier-1 face anomaly is distinguishable in a side-by-side capture | this is the acceptance test for the whole section |
| Flayed Mimic sutures are UV-only | it is the tell, and the UV tool exists to find it |
| anomaly ids and the wire payload shape unchanged | the server sends them and the catalog depends on them |
| old sculpted-anatomy path deleted, not flagged off | no compatibility layers |
| `GuestRenderer.depart` still called from `DeskUI.send` | that is the one verdict path |
| `State.luau` untouched | persistence is verified and fragile |
| Play pressed, `[nightdesk] server initialized` seen | build and lint cannot see a runtime failure |
| pushed, not just committed | forgotten twice |
