# Section 1 — The Night

Mega prompt for Antigravity. Self-contained; paste into a fresh session.

```bash
cd $HOME\Desktop\nightdesk
agy --model gemini-3.1-pro-high
```

Thinking model. This is pacing and feel, not typing.

---

```
You are working on nightdesk, a co-op anomaly-horror game on Roblox. Read
AGENTS.md, PROJECT_MEMORY.md and docs/ROBLOX.md before writing anything. Then
read docs/ROADMAP.md, which is the live plan; you are building Section 1.

Roblox Studio is open with the place loaded and you have the Roblox_Studio MCP
server available. Use it.

THE PROBLEM

A shift is currently a counter. Shift.start sets

    p.guestsLeft = stats.guestsPerShift + nightBonus

and the shift ends when it reaches zero. Guests arrive when the player rings the
bell, or 1.8 seconds after a verdict. Nothing else marks time.

The design calls for a night: 12:00 AM to 6:00 AM, compressed to roughly ten to
fifteen minutes, escalating through phases -- calm, then normal guests, then the
first anomalies, then multiple suspicious guests, then motel incidents, then
major activity, then dawn.

This matters beyond pacing. Three later systems have nowhere to live until the
clock exists:

  - Motel events (Section 5) need a schedule to fire against.
  - Difficulty (Section 16 of the design) needs phases to scale across.
  - Procedural nights (Section 17) need a seed to be reproducible.

Right now ANOMALY_CHANCE is a fixed 0.45 module constant inside
src/shared/Anomalies.luau, and Shift.luau's rng is an unseeded Random.new(). A
night cannot be reproduced, and difficulty cannot vary within one.

TASK 1 -- THE CLOCK

Make the shift run on motel time from 12:00 AM to 6:00 AM.

Target roughly twelve minutes of real time for a full night. Tune it by playing
it, not by arithmetic -- the number that matters is whether a night feels like a
short horror scenario or like an errand.

The clock is the shift's spine, so it belongs on the server and it drives shift
end. Reaching 6:00 AM is surviving the night. Sanity hitting zero still ends it
early and still forfeits the takings.

Put the time on the HUD. It is the player's only sense of how much night is
left, and in a game about dread that readout is doing real work.

TASK 2 -- PHASES

Divide the night into phases and give each one a different character. The design
sketches this in section 15; treat it as intent, not as a spec to transcribe.

Two things must vary by phase:

  - how likely an arriving guest is to be an anomaly
  - which tiers those anomalies are drawn from

The catalog holds 25 tier-1, 14 tier-2 and 3 tier-3 anomalies, and roll()
currently picks uniformly across all of them. A uniform draw means the shape of
the catalog decides difficulty, which is an accident rather than a decision. A
1:00 AM guest and a 5:00 AM guest should not be drawn from the same distribution.

This requires moving the difficulty numbers out of Anomalies and into the caller.
Anomalies.roll should take the anomaly chance and the tier weighting from
whoever calls it. The catalog should describe what anomalies exist; the shift
should decide which ones tonight is made of.

Night number still scales on top of phase -- night 5 at 2:00 AM should be worse
than night 1 at 2:00 AM.

TASK 3 -- ARRIVAL PRESSURE

Guests currently appear only when summoned. With a clock running, that has to
cost something, or the correct strategy is to never ring the bell.

Guests should arrive on the night's schedule and wait. The bell calls the
waiting guest up when the player is ready. A guest left waiting too long leaves,
and a guest who leaves is revenue that walked out -- so thoroughness has a price
and so does dithering.

Get the feel right: the player should sometimes want more time than they have,
and should never feel the game took the decision away from them.

TASK 4 -- THE SEED

Every night gets a seed. Same seed, same night: same guests, same anomalies, same
phase rolls.

Derive it per night, thread it through every roll the night makes, and show it
on the end-of-shift screen. It is how a bug in a specific night becomes
reproducible instead of anecdotal, and later it is how a player says "try seed
40219" to a friend.

Replace the module-level unseeded Random.new() in Shift.luau. If anything else
in the shift path draws from an unseeded source, thread it too -- a seed that
only covers half the night is worse than no seed, because it looks like it works.

DO NOT TOUCH -- all of these are recently fixed and easy to undo by accident

  - src/server/State.luau. Persistence is verified working. Leave it alone.
  - Atmosphere.shakeCamera. It uses Humanoid.CameraOffset deliberately. Writing
    Camera.CFrame instead was a bug that froze the player's view.
  - The input bindings. Every desk key is bound exactly once. Adding a
    ContextActionService binding beside an existing ProximityPrompt makes both
    fire and they cancel.
  - DeskProps.setVerdictHandler. Exactly one judge:FireServer call exists in the
    entire client and it must stay that way.
  - The Anomalies.rollable pool and the UNOBSERVABLE table.

  Newly fixed, and specifically at risk in this section:

  - SanityUpdate is a separate remote from ShiftUpdate on purpose. ShiftUpdate
    means "a guest was judged" and the client renders a verdict line and clears
    the desk prompt when it arrives. Coffee and soda go on SanityUpdate. Do not
    merge them back.
  - The Loadout remote carries hasCCTV and hasCoffee, and the client gates the
    CCTV monitor and the espresso machine on them. Without those gates two shop
    items are placebo. Keep them, and keep firing Loadout at shift start.
  - arrivalToken in Shift.luau. sendNext must never be called without claiming a
    token first, or the bell and the post-verdict timer both deliver a guest and
    the second overwrites the first while the player is looking at them. You are
    changing arrival timing in TASK 3, so this is directly in your path -- if you
    restructure arrivals, the guarantee still has to hold: never more than one
    guest arrival in flight.
  - The phone's 101-108 room range check. Dialling a number outside it reports a
    dead line, which is how the invalid_room_109 ledger tell gets confirmed.

VERIFY BEFORE FINISHING

  rojo build -o nightdesk.rbxl
  selene src/ tools/      (2 warnings expected, both unused params in
                           buildHorrorArchetypes -- do not add more)
  stylua src/ tools/

Then press Play. rojo build and selene cannot see a runtime failure -- both the
white-ambient lighting bug and the MaterialVariant bug built clean and linted
clean. Confirm "[nightdesk] server initialized" still prints and no Lua errors
appear in Output.

Then play a full night, start to finish, and answer honestly:

  - Did twelve minutes feel like a night, or like a chore?
  - Could you tell 2:00 AM from 5:00 AM without reading the clock?
  - Did you ever want more time than you had?

If the answer to the second one is no, the phases are not doing anything yet and
TASK 2 is not done.

Then COMMIT AND PUSH. git push origin master is part of finishing.

REPORT

  - The phase table: name, clock range, anomaly chance, tier weighting.
  - Real seconds per in-game hour, and how you arrived at that number.
  - How a guest arrives, waits, and leaves, and what leaving costs.
  - Where the seed is created and every place it is threaded through.
  - Your honest answers to the three playtest questions above.
  - Anything you deliberately left out.
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
