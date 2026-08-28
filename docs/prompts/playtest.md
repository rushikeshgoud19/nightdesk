# Prompt: first real playtest (observe only)

Nobody has played this. Everything so far is verified to *run* — nothing is
verified to be *good*. This prompt sends agy in to look, and deliberately forbids
fixing, so the findings can be reviewed before anyone starts changing code.

```bash
agy --model gemini-3.7-flash-high
```

Flash is fine here — it is observation and reporting, not architecture.

---

```
Use the Roblox_Studio MCP server and the visual-playtest-qa skill in
.agents/skills/. Roblox Studio is open with the nightdesk place.

This is an OBSERVE-ONLY task. Do not edit a single file. Do not fix anything you
find. Your job is to look carefully and report honestly.

BEFORE YOU START
Confirm the place actually contains the game: Workspace should have Spawn and
Lobby, ServerScriptService should have Server. If the Explorer looks like an
empty template, say so and stop -- the Rojo plugin is not connected and nothing
below will mean anything.

RUN IT
Start a playtest. Then walk these beats, capturing the screen at each one:

1. THE INTRO
   - Capture the moment it appears.
   - Time it. How many seconds from black to the punch-in prompt being pressable?
   - Read the teletype text. Does it explain what the job is, or does it assume
     you already know?
   - Is anything cut off, overlapping, or off-screen?

2. THE SPAWN
   - Punch in. Capture immediately after.
   - Are you behind the reception counter, facing it? Or somewhere else?
   - Is there a visible fall, jolt, or teleport as you land?
   - Look down. Is there a floor under you, or did you spawn over a void?
   - Look around. Is the default grey baseplate visible anywhere, including at
     the horizon past the lobby walls?

3. THE LOBBY
   - Turn a slow 360 and capture four angles.
   - Anything floating, clipping through a wall, z-fighting, or intersecting?
   - Can you read the room, or is it too dark to tell what anything is?
   - Walk to the hallway and the lounge. Do they connect properly, or is there a
     gap you can fall through?

4. THE HUD
   - Capture it. Can you read the sanity bar, the takings, and the night number
     at a glance without squinting?
   - Does anything overlap anything else?
   - Is the control hint legible?

5. A FULL GUEST
   - Ring the bell [E]. Does a guest actually arrive?
   - Capture the guest. Does it read as a person, or as a pile of parts?
   - Inspect the ledger [F], try the intercom [G], try the UV light [Q].
     Which of these actually do something visible, and which do nothing?
   - Stamp a verdict [Z] or [X]. Does the game respond?

6. THE CONSOLE
   - Read the full console output. Report every error and warning verbatim,
     including ones that look harmless.

7. THE SHOP
   - Finish the night if you can. Does the shop open?
   - Capture it. Are prices, names and lock reasons readable?

REPORT
Split your findings into three lists, worst first inside each:

  BROKEN   - it does not work, or it errors
  UGLY     - it works but looks wrong, unreadable, or unfinished
  MISSING  - a beat that felt like it needed something and had nothing

For each item say which capture shows it. If you could not reach a beat, say
which one and why -- do not skip it silently.

Then answer one question in your own words, honestly:
  Is this fun yet, or is it a set of systems that run?

Do not soften it. A flattering report is worth nothing here.
```

---

## Note on persistence testing

Do not ask agy to verify the save/load round trip yet. The open place reports
`PlaceId=0` — it is an unpublished local file, so DataStores cannot work and
ProfileStore silently falls back to an in-memory mock. Every test would pass for
the wrong reason.

To make persistence testable, a human has to:

1. **File → Publish to Roblox As…** — this mints a real PlaceId
2. **Game Settings → Security → Enable Studio Access to API Services**

Only then is "buy an upgrade, restart, still owned?" a real test.
