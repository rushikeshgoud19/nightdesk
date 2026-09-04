# Section 2 — The Night

Mega prompt for Antigravity. Self-contained; paste the block below into a fresh
session.

```bash
cd "$HOME/Desktop/nightdesk"
agy --model gemini-3.1-pro-high
```

Thinking model. This is pacing and feel, not typing.

---

```
=============================================================
NIGHTDESK — SECTION 2: THE NIGHT
=============================================================

You are working on nightdesk, a co-op anomaly-horror game on Roblox.

BEFORE WRITING ANYTHING, READ:
  1. AGENTS.md              -- rules, invariants, non-negotiables
  2. PROJECT_MEMORY.md      -- architecture and systems state
  3. docs/ROBLOX.md         -- Roblox technical constraints
  4. docs/ROADMAP.md        -- the live build order. You are building SECTION 2.

Roblox Studio is open with the place loaded and you have the Roblox_Studio MCP
server available. Use it.


-------------------------------------------------------------
1. THE PROBLEM
-------------------------------------------------------------

A shift is currently a counter, not a night.

    Shift.start sets:  p.guestsLeft = stats.guestsPerShift + nightBonus
    The shift ends when that hits zero.

Guests arrive when the player rings the bell, or 1.8 seconds after a verdict.
Nothing else marks time. There is no clock, no escalation, no dawn.

The design calls for a night: 12:00 AM to 6:00 AM, compressed to roughly ten to
fifteen minutes, escalating through phases -- calm, then normal guests, then the
first anomalies, then multiple suspicious guests, then motel incidents, then
major activity, then dawn.

This matters well beyond pacing. THREE LATER SYSTEMS HAVE NOWHERE TO LIVE UNTIL
THE CLOCK EXISTS:

    - Motel events (Section 6) need a schedule to fire against.
    - Difficulty scaling needs phases to scale across.
    - Procedural nights need a seed to be reproducible.

Two specific blockers in the code today:

    - ANOMALY_CHANCE is a fixed 0.45 module constant inside
      src/shared/Anomalies.luau. Difficulty cannot vary within a night.
    - Shift.luau's rng is an unseeded Random.new(). A night cannot be reproduced.


-------------------------------------------------------------
2. WHAT YOU ARE BUILDING
-------------------------------------------------------------

TASK 1 — THE CLOCK
..............................................................

Make the shift run on motel time, 12:00 AM to 6:00 AM.

    - Target roughly TWELVE MINUTES of real time for a full night.
    - Tune it by PLAYING it, not by arithmetic. The number that matters is
      whether a night feels like a short horror scenario or like an errand.
    - The clock is the shift's spine, so it lives on the SERVER and it drives
      shift end. Reaching 6:00 AM is surviving the night.
    - Sanity hitting zero still ends the night early and still forfeits takings.
    - PUT THE TIME ON THE HUD. It is the player's only sense of how much night
      is left, and in a game about dread that readout is doing real work.


TASK 2 — PHASES
..............................................................

Divide the night into phases and give each one a different character. The design
sketches this; treat it as intent, not as a spec to transcribe.

TWO THINGS MUST VARY BY PHASE:

    (a) how likely an arriving guest is to be an anomaly
    (b) which TIERS those anomalies are drawn from

Why this needs real work: the catalog holds 25 tier-1, 14 tier-2 and 3 tier-3
anomalies, and roll() currently picks UNIFORMLY across all of them. A uniform
draw means the SHAPE OF THE CATALOG decides difficulty -- which is an accident,
not a decision. A 1:00 AM guest and a 5:00 AM guest must not be drawn from the
same distribution.

This requires moving the difficulty numbers OUT of Anomalies and INTO the caller:

    - Anomalies.roll should take the anomaly chance and the tier weighting
      from whoever calls it.
    - The catalog describes WHAT ANOMALIES EXIST.
    - The shift decides WHICH ONES TONIGHT IS MADE OF.

Night number still scales ON TOP OF phase. Night 5 at 2:00 AM should be worse
than night 1 at 2:00 AM.


TASK 3 — ARRIVAL PRESSURE
..............................................................

Guests currently appear only when summoned. With a clock running, that has to
cost something -- otherwise the optimal strategy is to never ring the bell.

    - Guests arrive on the night's schedule and WAIT.
    - The bell calls the waiting guest up when the player is ready.
    - A guest left waiting too long LEAVES.
    - A guest who leaves is revenue that walked out.

So thoroughness has a price, and so does dithering.

Get the feel right: the player should sometimes want more time than they have,
and should NEVER feel the game took the decision away from them.


TASK 4 — THE SEED
..............................................................

Every night gets a seed. Same seed, same night: same guests, same anomalies,
same phase rolls.

    - Derive it per night.
    - Thread it through EVERY roll the night makes.
    - Show it on the end-of-shift screen.

It is how a bug in a specific night becomes reproducible instead of anecdotal,
and later it is how a player says "try seed 40219" to a friend.

Replace the module-level unseeded Random.new() in Shift.luau. If anything else
in the shift path draws from an unseeded source, THREAD IT TOO. A seed that only
covers half the night is worse than no seed, because it looks like it works.


-------------------------------------------------------------
3. DO NOT TOUCH
-------------------------------------------------------------

All of these are recently fixed and easy to undo by accident.

LONG-STANDING:

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
      that way.

    - Anomalies.rollable pool and the UNOBSERVABLE table.

NEWLY FIXED, AND SPECIFICALLY AT RISK IN THIS SECTION:

    - SanityUpdate is a SEPARATE remote from ShiftUpdate, on purpose.
      ShiftUpdate means "a guest was judged" -- the client renders a verdict
      line and clears the desk prompt when it arrives. Coffee and soda go on
      SanityUpdate. DO NOT MERGE THEM BACK.

    - The Loadout remote carries hasCCTV and hasCoffee, and the client gates the
      CCTV monitor and the espresso machine on them. Without those gates two
      shop items are placebo. Keep them, and KEEP FIRING LOADOUT AT SHIFT START.

    - arrivalToken in Shift.luau.
      sendNext must NEVER be called without claiming a token first, or the bell
      and the post-verdict timer both deliver a guest and the second overwrites
      the first while the player is looking at them.
      >> YOU ARE CHANGING ARRIVAL TIMING IN TASK 3, SO THIS IS DIRECTLY IN YOUR
      >> PATH. If you restructure arrivals, the guarantee still has to hold:
      >> NEVER MORE THAN ONE GUEST ARRIVAL IN FLIGHT.

    - The phone's 101-108 room range check.
      Dialling a number outside it reports a dead line. That is how the
      invalid_room_109 ledger tell gets confirmed.


-------------------------------------------------------------
4. VERIFY BEFORE FINISHING
-------------------------------------------------------------

STEP 1 — Toolchain:

    rojo build -o nightdesk.rbxl
    selene src/ tools/     (2 warnings expected, both unused params in
                            buildHorrorArchetypes -- do not add more)
    stylua src/ tools/

STEP 2 — Runtime. THIS IS NOT OPTIONAL.

    rojo build and selene CANNOT see a runtime failure. Both the white-ambient
    lighting bug and the MaterialVariant bug built clean and linted clean.

    Press Play. Confirm "[nightdesk] server initialized" still prints, and that
    no Lua errors appear in Output.

STEP 3 — Play a full night, start to finish, and answer honestly:

    Q1. Did twelve minutes feel like a night, or like a chore?
    Q2. Could you tell 2:00 AM from 5:00 AM WITHOUT reading the clock?
    Q3. Did you ever want more time than you had?

    >> If Q2 is "no", the phases are not doing anything yet and TASK 2 IS NOT
    >> DONE. Iterate before you report.

STEP 4 — COMMIT AND PUSH.

    git push origin master is part of finishing. It has been forgotten twice.


-------------------------------------------------------------
5. REPORT
-------------------------------------------------------------

    1. The phase table: name, clock range, anomaly chance, tier weighting.
    2. Real seconds per in-game hour, and how you arrived at that number.
    3. How a guest arrives, waits, and leaves -- and what leaving costs.
    4. Where the seed is created, and EVERY place it is threaded through.
    5. Your honest answers to Q1, Q2 and Q3 above.
    6. Anything you deliberately left out.

=============================================================
```

---

## Review checklist — for the Claude session that reviews this

| check | why |
|---|---|
| shift ends on the clock reaching 6:00 AM, not on a guest counter | otherwise the clock is decoration over the old system |
| `ANOMALY_CHANCE` no longer a fixed constant in `Anomalies.luau` | difficulty must be the caller's decision, not the catalog's |
| tier weighting differs between an early and a late phase | a uniform draw means phases changed nothing |
| night number still scales on top of phase | night 5 at 2 AM must beat night 1 at 2 AM |
| one seed, threaded everywhere the night rolls | a partial seed looks reproducible and is not |
| seed shown on the results screen | it is useless for debugging if it is not readable |
| never more than one guest arrival in flight | the `arrivalToken` guarantee, restated under new timing |
| `SanityUpdate` still separate from `ShiftUpdate` | coffee is not a verdict |
| `Loadout` still fired at shift start, gates intact | two shop items go placebo the moment it is dropped |
| `State.luau` untouched | persistence is verified and fragile |
| `selene` still at 2 warnings | new dead code is how unimplemented branches hid before |
| Play pressed, `[nightdesk] server initialized` seen | build and lint cannot see a runtime failure |
| pushed, not just committed | forgotten twice |
