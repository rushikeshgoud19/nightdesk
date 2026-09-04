# The Motel - two storeys, dressed

Mega prompt for Antigravity. Self-contained; paste the block below into a fresh
session.

```bash
cd "$HOME/Desktop/nightdesk" && agy --model gemini-3.1-pro-high
```

Carries two repairs from the guest-kit pass as well as the build:
the room's albedo, and the guest PBR surfaces that were swapped for stock
materials and reported as if they were not.

---

```
=============================================================
NIGHTDESK — THE MOTEL: TWO STOREYS, DRESSED
=============================================================

You are working on nightdesk, a co-op anomaly-horror game on Roblox.

BEFORE WRITING ANYTHING, READ:

  1. AGENTS.md              -- all of it, especially section 2 and the traps
  2. PROJECT_MEMORY.md
  3. docs/ROBLOX.md
  4. docs/ROADMAP.md
  5. reference/guest-kit.png -- the fidelity bar. The building must match it.

Roblox Studio is open and you have the Roblox_Studio MCP server. Use it heavily.
`search_asset` and `insert_asset` are the highest-leverage tools in this brief.
Do not model a potted plant by hand that the toolbox already has.


-------------------------------------------------------------
1. TWO THINGS ARE BROKEN. FIX THEM FIRST.
-------------------------------------------------------------

FAULT 1 — THE ROOM IS PAINTED BLACK, AND LIGHT CANNOT FIX THAT
..............................................................

Measured in the running place today:

    Floor        Color = 0.141, 0.125, 0.110    -> RGB(36, 32, 28)
    Ceiling      Color = 0.102, 0.102, 0.110    -> RGB(26, 26, 28)
    WallBack     Color = 0.188, 0.133, 0.094    -> RGB(48, 34, 24)
    CounterTop   Color = 0.243, 0.165, 0.102    -> RGB(62, 42, 26)

Ambient was raised to 0.85 and Brightness to 3 -- roughly six times the shipped
values -- and the room STAYED BLACK. A surface at RGB(26,26,28) reflects almost
nothing no matter how hard you light it. Lifting those part colours 72% toward
white lit the room instantly, with no further change to Lighting.

    >> docs/NEXT.md concluded "fix the light and 25 of your anomalies become
    >> playable" and raised Ambient from 0.03 to 0.12. That was half the
    >> problem. THE PAINT WAS NEVER TOUCHED. The readable middle range this
    >> game's entire design depends on still does not exist.

So: repaint. Every surface needs an albedo that can actually return light at
2am. Dark and moody is a lighting result, not a paint colour -- a real dim room
is mid-grey walls under a weak lamp, not black walls under a strong one.

Judge it by this test, and no other: A GUEST'S FACE ACROSS THE COUNTER MUST SHOW
A 4% SKIN-TONE DIFFERENCE. If it cannot, the room is still wrong.


FAULT 2 — THE GUEST LOST ITS PBR SURFACES AND THE REPORT SAID OTHERWISE
..............................................................

src/shared/Materials.luau, Materials.guest, right now:

    Skin  = surface(Enum.Material.SmoothPlastic)   -- no variant
    Hair  = surface(Enum.Material.SmoothPlastic)   -- no variant
    Suit  = surface(Enum.Material.Fabric)          -- no variant
    Shirt = surface(Enum.Material.Fabric)          -- no variant
    Shoe  = surface(Enum.Material.Leather)         -- no variant

Stock materials with colour tints. The previous session hit purple-and-black
checkerboarding, switched to this, and reported that it "retains the requested
PBR fabric weave and leather sheen". IT DOES NOT. Stock Fabric is precisely what
docs/NEXT.md calls the visual signature of an unfinished Roblox game.

The file even argues against itself. Its own comment on skin reads: "a colour
shift that small has nothing to read against on a flat plastic surface -- it
needs pores and a broken specular to sit on." Correct. Then it assigns flat
plastic.

    >> THE CHECKERBOARD WAS ALMOST CERTAINLY NOT A CAPABILITY ERROR.
    >> BasePart.MaterialVariant is a plain string with no security on it. A
    >> variant applies only when the part's Material EQUALS the variant's
    >> BaseMaterial, and the name matches one declared in MaterialService. Set a
    >> variant whose BaseMaterial is Fabric onto a part whose Material is
    >> SmoothPlastic and you get exactly the fallback you saw.
    >>
    >> Materials.applySurface already sets both, in the right order. So diagnose
    >> the real mismatch -- read the variant back off the part at runtime and
    >> compare it against MaterialService -- rather than routing around it.

Guests need their own variants, not the motel's. A suit is not a sofa. Generate
them, declare them in default.project.json under MaterialService, and name them
in Materials.guest.

DO NOT report a workaround as the feature. If something cannot be made to work,
say so plainly in the report and leave it out.


-------------------------------------------------------------
2. THE BUILD — A MOTEL THAT IS WORTH LOOKING AT
-------------------------------------------------------------

The lobby exists and is decent bones: reception counter, hallway with eight
numbered doors, lounge, vending machine, exterior awning, neon sign, and an
UpperMezzanineFloor and UpperMezzanineRailing that are currently doing nothing.

Make it a real two-storey highway motel, dressed.

THE ONE RULE THAT GOVERNS EVERY DECISION HERE
..............................................................

    THE DESK IS THE CAMERA.

The player stands at reception and barely moves. Design section 23 is explicit:
do not make the player walk. So every square metre of this building is worth
exactly as much as it is visible FROM BEHIND THE COUNTER.

Build outward from that eyeline. Before you place anything, ask whether the
clerk can see it. If not, it is set dressing for the CCTV, or it is waste.


TASK 1 — THE SECOND STOREY, SEEN AND NOT WALKED
..............................................................

The mezzanine is the best thing in the current floor plan and it is empty.

Open the lobby upward. An exterior walkway with a railing, doors along it,
reachable by the stairs that already exist, and -- this is the point -- VISIBLE
FROM THE DESK.

    >> A LANDING YOU CAN SEE FROM RECEPTION IS FREE HORROR. Something standing
    >> at the rail, for two seconds, while the player is reading a ledger, is
    >> worth more than any jumpscare this game could stage. Build the sightline
    >> and later sections will fill it.

Rooms 201-208 upstairs, matching the 101-108 below. The phone already treats
101-108 as the whole motel and reports a dead line outside that range -- if you
add upstairs rooms as real, dialable places, update that range and say so, or
leave them cosmetic and do not.


TASK 2 — DRESS IT, WITH REAL MODELS
..............................................................

Use `search_asset` and `insert_asset` first. The Roblox library is full of good
free props and pulling one in beats generating a worse one every time. Fall back
to `generate_mesh` for anything specific you cannot find.

A 1964 highway motel that has never been renovated. Things a real one has:

    Reception   a switchboard, a key rack with real keys, a guest book, a
                cigarette burn in the counter, a bell, a dead fern, a fan
    Lounge      mismatched chairs, a CRT television on a stand, magazines
                from the wrong decade, a coffee urn, a payphone
    Hallway     an ice machine, a luggage cart, a fire extinguisher, a linen
                trolley, framed prints nobody chose
    Exterior    the neon sign, a soda machine, parking bays, a chain-link
                fence, an overflowing bin, wet asphalt

    >> PROP DENSITY IS WHAT SELLS A PLACE AS REAL AND LIVED IN. An empty room
    >> reads as unfinished; a cluttered one reads as somebody's job.

Everything must sit at the reference's fidelity bar. Blocky forms are fine and
correct -- untextured ones are not.


TASK 3 — GIVE THE CAMERAS SOMETHING TO FRAME
..............................................................

CCTV currently cuts to fixed positions with nothing composed in them. Cameras
are how a later section shows the player what got inside, so each one needs a
subject and a foreground now:

    - the parking lot, with the neon sign and the rain
    - the ground-floor hallway, looking down the row of doors
    - the upstairs walkway
    - the lounge

Then walk each camera and ask: if something moved through this frame, would I
see it? If the answer is no, recompose the shot.


TASK 4 — SURPRISE ME
..............................................................

Two or three ideas of your own that belong in this building and that nobody
asked for. The brief above is the floor, not the ceiling.

The constraints they must respect:

    - Visible from the desk, or visible on a camera. Otherwise nobody sees it.
    - Quiet. Design section 21 is about contrast -- the building should be
      boring and specific most of the time so that a change reads loudly. An
      ice machine that hums is worth more than a cobweb.
    - Nothing supernatural. The building is normal. The GUESTS are wrong. A
      motel that already looks haunted has nothing left to spend.

Tell me what you added and why in the report.


-------------------------------------------------------------
3. DO NOT TOUCH
-------------------------------------------------------------

    - src/server/State.luau. Persistence is fragile and verified.
    - Atmosphere.shakeCamera -- Humanoid.CameraOffset, never Camera.CFrame.
    - The input bindings. Every desk key is bound exactly once.
    - The one judge:FireServer call in src/client.
    - Anomalies.rollable, UNOBSERVABLE, and every anomaly id.
    - SanityUpdate stays separate from ShiftUpdate.
    - The Loadout remote's hasCCTV / hasCoffee gates.
    - arrivalToken: never more than one guest arrival in flight.
    - The clock, the phases and the shift seed. They are new and they work.

    NO BACKUP COPIES IN THE REPO. The last session committed old_guest.luau and
    temp.luau, 200KB of the renderer it had just deleted. AGENTS.md: when
    something is replaced the old path goes in the same change. Git is the
    backup. Scratch scripts stay out of the tree.


-------------------------------------------------------------
4. VERIFY BEFORE FINISHING
-------------------------------------------------------------

STEP 1     rojo build -o nightdesk.rbxl
           selene src/ tools/          (0 warnings now -- keep it there)
           stylua src/ tools/

STEP 2     Press Play. Confirm "[nightdesk] server initialized" prints and no
           Lua errors appear. Build and lint cannot see a runtime failure.

STEP 3     LOOK AT IT, at the SHIPPED lighting values. Not brightened.

           screen_capture with explicit camera_position and look_at_position:

             1. Standing at the desk, facing the guest position (0, 4.8, 1.8)
             2. The lobby wide, showing the mezzanine above
             3. Down the ground-floor hallway
             4. The upstairs walkway from the desk eyeline
             5. A guest's face at conversation distance
             6. Each CCTV camera's framing

           Then answer honestly:

             Q1. Could you see a 4% skin-tone difference in shot 5?
             Q2. Does shot 2 look like a place, or like a room with props in it?
             Q3. From shot 4 -- would you notice a figure at that railing?
             Q4. Does the suit in shot 5 have visible weave, or is it flat?

           >> Q1 AND Q4 ARE THE TWO FAULTS IN SECTION 1. If either answer is no,
           >> that fault is not fixed. Iterate before reporting.

STEP 4     COMMIT AND PUSH. git push origin master is part of finishing.


-------------------------------------------------------------
5. REPORT
-------------------------------------------------------------

    1. The repaint: old and new colour for every major surface class.
    2. The guest variants: each one, its BaseMaterial, and the description you
       wrote. If the checkerboard recurred, what you found the real cause to be.
    3. Every asset you pulled from the toolbox, and everything you generated.
    4. What is upstairs, and whether rooms 201-208 are dialable or cosmetic.
    5. The four camera framings and what each one is composed around.
    6. Your two or three additions, and why they belong.
    7. Honest answers to Q1-Q4, naming which capture each came from.
    8. Anything you deliberately left out. Name it. Do not report a workaround
       as the feature.

=============================================================
```

---

## Review checklist - for the Claude session that reviews this

| check | why |
|---|---|
| room surfaces repainted, not just relit | RGB(26,26,28) walls cannot return light at any brightness |
| a 4% skin-tone shift is visible in a face capture at shipped lighting | the acceptance test the whole anomaly design rests on |
| guests carry their own MaterialVariants | stock Fabric + tint is what NEXT.md calls the signature of an unfinished game |
| the checkerboard's real cause diagnosed, not routed around | `MaterialVariant` has no security; a BaseMaterial mismatch explains it |
| the mezzanine is visible from behind the counter | a landing you can see from reception is where later horror gets staged |
| rooms 201-208 either dialable *and* in the phone's range, or cosmetic | the phone reports a dead line outside 101-108 |
| every CCTV camera has a composed subject and foreground | Section 6 needs them to show a figure moving |
| props pulled from the toolbox where possible | generating what already exists for free is wasted effort |
| the building is normal; only the guests are wrong | a motel that already looks haunted has nothing left to spend |
| no backup copies or scratch scripts committed | `old_guest.luau` and `temp.luau` were 200KB of exactly that |
| clock, phases and shift seed untouched | new and working |
| `State.luau` untouched | persistence is fragile |
| `selene` at 0 warnings | it is at 0 now; that is the new baseline |
| Play pressed, `[nightdesk] server initialized` seen | build and lint cannot see a runtime failure |
| pushed, not just committed | forgotten twice |
