# Playtest findings — first run against a working loop

A QA subagent played the game and filed a report. Every claim in it was then
checked against the code before anything was changed. Two were real and traced
to one shared root cause, one was wrong, one could not be reproduced from the
geometry, and the rest are honest visual debt.

This document records what was verified, not what was claimed.

---

## Fixed

### 1. Every desk key was bound twice

**Reported as:** "Pressing [F], [G] and [Q] produces absolutely no visible effect."

**Actually:** the keys were bound, twice each, and the two bindings cancelled.

`addPrompt` creates a `ProximityPrompt` with `KeyboardKeyCode` set. Separately,
`ContextActionService:BindAction` bound the *same key* to the *same handler* and
returned `Enum.ContextActionResult.Pass` — which explicitly does **not** consume
the input. So both fired on every press.

| key | what happened |
|---|---|
| `Q` | UV lamp toggled on, then straight back off |
| `F` | ledger opened, then instantly closed |
| `E` | bell rang twice — hidden by the server's 0.25s throttle |
| `T` | phone called twice — hidden by the server's 1.0s throttle |
| `Z` / `X` | three handlers fired: two stamp animations and one verdict |

`E` and `T` looked fine only because the server throttles them. `Q` and `F` are
pure toggles with no throttle, so they read as completely dead.

**Fixed:** eight duplicate `ContextActionService` bindings removed across
`DeskProps`, `DeskUI` and `DeskCamera`. ProximityPrompts now own world
interaction — and unlike an invisible key binding, they show the player what the
key does.

### 2. Any click could pass judgement

**Reported as:** "The game mysteriously admitted a guest without any explicit
input."

**Actually:** worse than a timeout bug. `slamStamp` called `judge:FireServer(admit)`
**directly**, bypassing `DeskUI.send` and its `awaiting` guard. And `addClick`
puts a `ClickDetector` with a 14-stud activation range on the stamp handles.

In first person with a locked centre crosshair, **any mouse click aimed near a
stamp fired a verdict** — with no check that a guest was even at the desk.

It also skipped everything `DeskUI.send` does afterwards: `setPrompt(false)`,
`GuestRenderer.depart()`, `DeskProps.clearLedger()`. So a stamped verdict left
the verdict bar up, the guest standing there, and the previous guest's details
still on the ledger.

**Fixed:** `DeskUI` now injects a guarded verdict handler into `DeskProps` — the
same dependency-injection pattern `Shift` uses for its shift-end handler on the
server, since `DeskUI` already requires `DeskProps` and the reverse would be a
cycle. Both `slamStamp` paths route through it, including the fallback branch
that was firing the remote directly too.

There is now exactly one `judge:FireServer` call in the entire client.

---

## Wrong

### "You spawn on the wrong side of the counter"

Checked. `SpawnLocation` was at `[0, 3.5, 7.5]`; the counter props sit at
`z ≈ 4.6`; guests walk to `DESK_POS = (0, 4.80, 1.80)`. The player spawns behind
the counter with the guest on the far side — which is correct.

Nudged the spawn to `[0, 3.5, 7.2]` so it matches the client's `PivotTo` exactly
and there is no corrective teleport at all, but that is tidying, not a fix.

---

## Could not reproduce

### "SANITY label overlaps the takings amount"

The geometry does not support it. `takingsBadge` occupies x 195–325;
`sanityContainer` is centre-anchored at `(0.5, -125)` with width 250, so on a
1920-wide screen it occupies x 811–1061. No overlap at any common resolution.

A separate HUD collision *was* real and was fixed earlier — the CRT watermark
was drawn at `(24, 20)` inside the HUD frame at `(24, 12)`. That is likely what
was seen, on a build from before that fix.

If it reappears, capture it with the window size noted.

---

## Real, not yet fixed

These are visual debt, not defects. They need an art pass, not a bug fix.

1. **Guests read as blocky avatars with neon outlines**, not the sculpted models
   the design calls for. This is the largest gap between the game as designed and
   the game as it plays.
2. **Lighting and bloom are blown out** — room geometry reads pitch black while
   props glow. Contrast is destroyed, which directly undermines subtle anomalies:
   a 4% skin-tone shift cannot register when everything is either black or
   blooming.
3. **Viewmodel arms are untextured grey blocks** with no animation on bell,
   ledger or stamp actions.
4. **Lobby architecture is thin** — no visible hallway, lounge, vending machine,
   or exterior rain and fog.

All four have the same underlying cause: **the project contains zero
`SurfaceAppearance` instances** against 154 stock `Enum.Material` assignments.
Stock materials are the visual signature of an unfinished Roblox game, and PBR
changes how a surface reads without touching geometry.

That is the phase-two pass, and it is now the highest-value work remaining.

---

## Console

```
[nightdesk] server initialized with master motel lobby
DataStoreService: StudioAccessToApisNotAllowed: Cannot write to DataStore from studio
[profilestore]: Roblox API services unavailable - data will not be saved
[nightdesk] first-person FPS client fully initialized
[nightdesk] clerk punched in - night shift active
```

No runtime Lua errors.

The DataStore warning above was from an unpublished local file. **That has since
been resolved and persistence is now verified working** — see below.

---

## The verdict question

The subagent was asked whether the game is fun yet. It said no — *"a dark room
where neon blocks spawn and you are penalised for things you cannot see or
interact with."*

That was a fair description **of a build where none of the interaction keys
worked and clicks fired random verdicts**. Both of those are now fixed. The
judgement was accurate about what it played; it is no longer accurate about what
exists.

It is worth re-running the playtest now, because that answer was measured against
a game you could not actually operate.


---

## Persistence: verified working

Previously blocked because the open place reported `PlaceId=0` — an unpublished
local file, where DataStores cannot work and ProfileStore silently falls back to
an in-memory mock, so every test passed for the wrong reason.

The place is now published (`PlaceId=106512529474987`) and **Studio Access to API
Services** is enabled. Both were needed; neither alone is sufficient.

Tested directly against the running engine:

**DataStore reachability**

```
WROTE 1787950932 | READ BACK 1787950932 | match=true
```

**Full ProfileStore round trip** — the actual path the game uses:

```
session 1: takings=777, owned.lights=true, nightsWorked=3, then EndSession
session 2: same key
read back: takings=777  lights=true  nights=3  schema=1
```

All four fields survived, the session lock released cleanly enough for a second
session to acquire it, and `schemaVersion` persisted. Probe keys were removed
afterwards.

**An upgrade bought now survives logout.** The retention spine — the entire
reason this game has a shop rather than just an anomaly loop — is real for the
first time.

### Correction, 4 September 2026

That verification was **place-specific, and it did not carry**. The place that
opens in Studio as "Anamoli" is `80829108524155`, not `106512529474987`, and it
was running with Studio Access to API Services **off**:

```
DataStoreService: StudioAccessToApisNotAllowed
[profilestore]: Roblox API services unavailable - data will not be saved
```

Which is the same failure mode as before, for the same reason: ProfileStore
falls back to an in-memory mock and every test passes for the wrong reason.

Enabled on the Anamoli place on 4 September. **Persistence has not been
re-verified end to end against that place** -- the round trip above was run
somewhere else. Re-run it before trusting a saved upgrade again.
