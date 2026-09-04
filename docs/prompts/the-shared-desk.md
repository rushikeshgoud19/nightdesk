# Section 3 - The Shared Desk

Mega prompt for Antigravity. Self-contained; paste the block below into a fresh
session.

```bash
cd "$HOME/Desktop/nightdesk" && agy --model gemini-3.1-pro-high
```

Thinking model. This is the architectural section and the one most likely to
break things that currently work.

**Depends on Section 1** having made guest assembly a pure function of a seed,
and on **Section 2** having moved the shift onto a clock. Do not start it early.

---

```
=============================================================
NIGHTDESK — SECTION 3: THE SHARED DESK
=============================================================

You are working on nightdesk, a co-op anomaly-horror game on Roblox.

BEFORE WRITING ANYTHING, READ:

  1. AGENTS.md              -- rules, invariants, traps. All of it.
  2. PROJECT_MEMORY.md
  3. docs/ROBLOX.md
  4. docs/ROADMAP.md        -- you are building SECTION 3

Roblox Studio is open with the place loaded and you have the Roblox_Studio MCP
server available.

This is the architectural section. It is the one most likely to break things
that currently work. Read the whole brief before you start typing.


-------------------------------------------------------------
1. THE PROBLEM
-------------------------------------------------------------

The game is single-player wearing a co-op costume.

Every piece of shift state lives on a per-player profile. State.load(player)
returns a proxy holding `current`, `sanity`, `guestsLeft`, `shiftActive`,
`mistakes`, `hasBrewedCoffee` and `breakerTripped`. Shift.start(player) starts
one player's night. guestArrived:FireClient(player, ...) sends one player their
own guest, which their own client then builds.

So if two people join today, they stand in the same lobby and play two
completely separate games. Different guests, different sanity, different nights,
at the same desk.

The design's social hook -- section 13 -- is two people looking at ONE guest and
disagreeing about him. That is the reason anyone tells a friend about this game,
and it is currently impossible.


-------------------------------------------------------------
2. THE DECISIONS — THESE ARE SETTLED, DO NOT REOPEN
-------------------------------------------------------------

THE SERVER IS THE SESSION.
    Everyone on the server is in one shift. No lobbies, no matchmaking, no
    party codes. Set MaxPlayers to 4. This is the simplest thing that works and
    the design asks for 2-4 players, not for a social layer.

SANITY IS SHARED.
    One motel, one sanity meter. A wrong admission hurts everybody. This is what
    gives the argument stakes -- if your mistake only cost you, nobody would
    care what you thought.

WALLETS AND UPGRADES ARE INDIVIDUAL.
    Every player in the session earns the same payout into their own wallet and
    buys their own upgrades. ProfileStore stays exactly as it is.

    Upgrades then split into two kinds, and you must make this split explicit:

      PERSONAL   -- the tool belongs to its owner and works only for them.
      MOTEL-WIDE -- the fixture belongs to the building, so the session takes
                    the BEST owned by anyone present.

    A well-equipped player visibly helps the crew. That is the intended
    feeling. Categorise every item in Upgrades.list, and report the table.

    >> ONE CONSEQUENCE OF THIS IS A FEATURE, NOT A BUG: tellChance is personal,
    >> so two players looking at the same guest may not both get the hint text.
    >> "I can see something wrong with his eyes" / "I've got nothing" is exactly
    >> the section 13 conversation. Keep the tell text per-player. Do not
    >> average it, do not share it, do not take the best.


-------------------------------------------------------------
3. WHAT YOU ARE BUILDING
-------------------------------------------------------------

TASK 1 — SEPARATE SESSION STATE FROM PROFILE STATE
..............................................................

Right now one proxy table holds both. Split it:

    PROFILE (per player, persisted)   takings, owned, nightsWorked
    SESSION (per server, ephemeral)   current guest, guestsLeft, sanity,
                                      shiftActive, mistakes, hasBrewedCoffee,
                                      breakerTripped, arrivalToken, and the
                                      clock and seed from Section 2

    >>>> READ THIS BEFORE YOU TOUCH State.luau <<<<
    >>
    >> Every other section of this project says "do not touch State.luau". This
    >> one has to. So here is exactly how far you may go.
    >>
    >> YOU MAY: remove the ephemeral fields that move to the session, and the
    >>          dead `tellVisible` field, from the proxy and the Profile type.
    >>
    >> YOU MAY NOT touch any of:
    >>   store:StartSessionAsync   -- these names differ from ProfileService and
    >>   profile.OnSessionEnd      -- from ProfileStore's pre-1.0 releases, and
    >>   profile:Reconcile         -- a wrong one is invisible to selene, to
    >>   profile:EndSession        -- stylua and to rojo build. It only shows up
    >>   profile:AddUserId         -- as a crash on the first PlayerAdded, which
    >>                                then silently kills the whole shift loop.
    >>   The __newindex allowlist (takings / owned / nightsWorked). Getting this
    >>   wrong means writes land in the proxy instead of profile.Data and stop
    >>   persisting -- silently, and it will look like it works.
    >>
    >> Then RE-VERIFY THE ROUND TRIP. See TASK 5. This is not optional and it is
    >> not covered by any test you can run offline.


TASK 2 — ONE GUEST, SEEN BY EVERYONE
..............................................................

The guest at the desk is session state. When one arrives, every player in the
session is told about the same guest at the same moment.

    - guestArrived goes to every player in the session, not to one.
    - Section 1 made guest assembly a pure function of a seed. That is what
      makes this work: every client builds the same face from the same payload.
      If two clients render different faces, the co-op premise is dead.
    - The bell is shared. Anyone can ring it. Everyone hears it.
    - The ledger, the phone, the UV lamp and the intercom stay individually
      operable -- four people should be able to investigate different things at
      once. That is the role split in design section 14, and it needs no classes
      to happen, only shared access.

    >> arrivalToken becomes session-scoped. The invariant is unchanged and still
    >> load-bearing: NEVER MORE THAN ONE GUEST ARRIVAL IN FLIGHT. With four
    >> players able to ring the bell, it matters more than it did with one.


TASK 3 — ANYONE CAN PASS THE VERDICT
..............................................................

One guest, one verdict, whoever stamps first.

    - The server resolves it once. A second stamp landing a frame later must do
      nothing at all, not double-pay and not double-penalise.
    - Everyone sees the outcome, and everyone sees WHO passed it. "Who let him
      in?" is a question the game should be able to answer.
    - Shared sanity moves for everyone. Individual takings move for everyone.

    >> There is exactly one judge:FireServer call in the entire client and that
    >> stays true. Do not add a second path for "the other players".


TASK 4 — JOINING, LEAVING, AND THE MOTEL'S OWN STATE
..............................................................

    - A player joining mid-shift joins the shift in progress and gets a full
      state sync: the clock, the current guest, the sanity, the breaker.
    - A player leaving does not end the night for everyone else.
    - The last player leaving ends the session cleanly.
    - The breaker is the motel's, so it is session state now. In Section 0 it
      was deliberately narrowed to FireClient(player) because state was
      per-player; in a session it correctly goes to everyone again. THAT IS NOT
      UNDOING THE FIX -- the fix was the guard requiring a breaker to actually
      be tripped before it can be reset. KEEP THE GUARD.
    - Starting a night: any player may start it. Do not build a ready-check.


TASK 5 — VERIFY PERSISTENCE, FOR REAL
..............................................................

docs/playtest-findings.md records a ProfileStore round trip proven against place
106512529474987. The place that opens in Studio is 80829108524155, and until 4
September it was running with Studio Access to API Services OFF -- so
ProfileStore was falling back to an in-memory mock and every save appeared to
work while none of them did.

API access is now on. THE ROUND TRIP HAS NEVER BEEN RUN AGAINST THIS PLACE.

You are restructuring the file that owns persistence. So prove it:

    - Write takings, an owned upgrade, and nightsWorked. End the session.
    - Start a new session on the same key. Read all three back.
    - Confirm the values survived and that schemaVersion is intact.
    - Remove any probe keys afterwards.

Report the actual numbers you wrote and read back. Not "it works".


-------------------------------------------------------------
4. DO NOT TOUCH
-------------------------------------------------------------

    - Atmosphere.shakeCamera
      Uses Humanoid.CameraOffset deliberately. Camera.CFrame froze the view.

    - The input bindings
      Every desk key is bound exactly once. A ContextActionService binding
      beside an existing ProximityPrompt makes both fire and cancel.

    - The one judge:FireServer call in src/client.

    - The Anomalies.rollable pool, the UNOBSERVABLE table, and every anomaly id.

    - SanityUpdate stays separate from ShiftUpdate. Coffee is not a verdict.

    - The Loadout remote's ownership gates. Without them the espresso machine
      and the CCTV monitor are placebo purchases.

    - The phone's 101-108 room range check.

    - The ProfileStore API surface inside State.luau. See TASK 1.


-------------------------------------------------------------
5. VERIFY BEFORE FINISHING
-------------------------------------------------------------

STEP 1 — Toolchain:

    rojo build -o nightdesk.rbxl
    selene src/ tools/
    stylua src/ tools/

STEP 2 — Runtime, with TWO clients. This is the whole section.

    Studio: Test > Clients and Servers > 2 players > Start.

    Then confirm, by looking at both windows:

      Q1. Do both clients see the SAME guest -- same face, same hair, same suit,
          same anomaly? Capture both and compare them.
      Q2. Does the bell rung on client A bring the guest up on client B?
      Q3. Does a stamp on client A resolve the guest on client B, and does B see
          who did it?
      Q4. Does a wrong admission drop sanity on BOTH clients?
      Q5. Does a second stamp, immediately after the first, do nothing?

    >> Q1 IS THE SECTION. If the two faces differ, guest assembly is not
    >> actually seeded and nothing else here matters.

STEP 3 — Persistence round trip. TASK 5. Report the numbers.

STEP 4 — Solo must still work.

    Play a full night alone. A game that only works with two people is a
    regression, not a feature.

STEP 5 — COMMIT AND PUSH. git push origin master is part of finishing.


-------------------------------------------------------------
6. REPORT
-------------------------------------------------------------

    1. What moved from profile to session, field by field.
    2. The upgrade categorisation table: every item, personal or motel-wide,
       and why.
    3. Exactly what you changed inside State.luau, line by line, and what you
       deliberately left alone.
    4. The persistence round trip: the values written, the values read back.
    5. Your answers to Q1-Q5, and the two captures for Q1.
    6. Confirmation that a solo night still plays start to finish.
    7. Anything you deliberately left out.

=============================================================
```

---

## Review checklist - for the Claude session that reviews this

| check | why |
|---|---|
| two clients render the same guest, verified by capture | if the faces differ the co-op premise is dead |
| sanity shared, wallets and upgrades individual | the settled decision; ProfileStore must not grow a crew model |
| every upgrade categorised personal vs motel-wide | otherwise "best in session" has no definition |
| `tellChance` still per-player | two players disagreeing about what they can see is the point |
| ProfileStore API surface in `State.luau` untouched | a wrong method name is invisible to lint and build, and kills PlayerAdded |
| `__newindex` allowlist intact (takings / owned / nightsWorked) | writes silently stop persisting otherwise |
| persistence round trip re-run, numbers reported | it has never been proven against place `80829108524155` |
| `arrivalToken` now session-scoped, invariant intact | four bells make double-arrival far likelier than one |
| a second stamp does nothing | double-pay and double-penalty |
| breaker reset still guarded on actually being tripped | broadcasting again is correct; dropping the guard is not |
| exactly one `judge:FireServer` in `src/client` | no second path for "the other players" |
| a solo night still plays start to finish | co-op that breaks single player is a regression |
| `selene` clean, Play pressed, no Lua errors | build and lint cannot see a runtime failure |
| pushed, not just committed | forgotten twice |
