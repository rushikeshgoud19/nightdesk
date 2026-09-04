# Nightdesk — the build order

The live plan. Written 4 September 2026, after the art pass landed and the
integrity pass closed. Reordered the same day, when the guest art direction
changed.

The design document this is derived from is `NIGHTDESK_GAME_PLAN_README.md` — 29
sections of design, none of it sequenced. This file sequences it. One section at
a time, each leaving a playable game.

**Division of labour**
- Claude plans each section, writes its mega prompt, reviews the result, fixes bugs.
- Antigravity (`agy`) builds.
- Nothing moves to the next section until the current one passes its acceptance test.

---

## Where the game actually is

Verified against the code on 4 September 2026, not reported:

| system | state |
|---|---|
| Reception loop | Works. Bell → observe → ledger → phone → UV → intercom → stamp |
| Anomaly catalog | 42 tells, 25/14/3 across tiers 1/2/3, all rollable |
| Investigation tools | All five have something to find |
| Sanity | A number with client effects. Does not yet distort perception |
| Economy + shop | Works, persists. 11 items, all of them now real |
| Persistence | API access enabled on `80829108524155` on 4 Sep, but the round trip has **never been run against that place**. Re-verified in Section 3 |
| Room art | Materials + lighting pass landed |
| Guest art | **Direction changed 4 Sep.** Blocky kit, not sculpted anatomy. Not built yet |
| CCTV | Camera positions and a CRT overlay. **Nothing to see on them** |
| Co-op | **Not implemented.** Per-player shifts, client-built guests |
| Consequences | **Not implemented.** A wrong admit is −40 sanity and the guest vanishes |
| Evidence chains | **Not implemented.** One guest = one tell |

---

## The order

Each section names the design-doc sections it discharges.

### ✅ Section 0 — Integrity *(done — Claude)*

Not a feature. The shop was selling three items that did nothing, and the
verdict line was reporting numbers the server had not paid.

Repairs §19, §20.

### Section 1 — The Guest Kit — §5.1, §7, §25 Phase 1

Rebuild the guest as a modular blocky kit with cinematic surface detail: face as
texture, hair as sculpted mesh, clothing as PBR. Reference:
`reference/guest-kit.png`.

**First, for the same reason the lighting pass was first.** The art pass made
the *room* readable. The guests are still untextured blocky forms whose tells
are sub-centimetre geometry nudges, so 18 of the 42 anomalies — every
`visual_face` and `visual_body` entry — cannot be perceived. Scaling difficulty
across a night (Section 2) while the tells are invisible is tuning the wrong
thing.

It also makes Section 3 cheaper: a guest assembled from a seeded choice of parts
is deterministic by construction. The current renderer draws from unseeded
`math.random` in fifteen places.

### Section 2 — The Night — §15, §16, §17

A shift stops being "four guests then done" and becomes 12:00 AM → 6:00 AM.
Phases scale the anomaly rate and the tier mix. A seed makes a night
reproducible.

**Because every later system needs a schedule to happen on.** Motel events need
a clock. Difficulty needs phases. Procedural nights need a seed.

### Section 3 — The Shared Desk — §13, §14

Co-op, 2–4 players. The shift becomes a session rather than a per-player loop:
one guest, seen by everyone, judged by any of them, on shared sanity and shared
takings.

**Early because it is architecture, not content.** Every section after it lands
co-op-native instead of needing its own port. Doing this last would mean porting
six systems instead of one.

Settled 4 September, and not to be reopened: **the server is the session**
(MaxPlayers 4, no lobbies), **sanity is shared**, and **wallets and upgrades are
individual**. Upgrades split into personal tools and motel-wide fixtures, where
the session takes the best owned by anyone present — so a well-equipped player
visibly helps the crew, and your own progress is always your own, which is what
the retention spine depends on. `tellChance` stays personal: two players
disagreeing about what they can even see is the §13 conversation, not a bug.

### Section 4 — Evidence Chains — §6, §7

A guest stops having one tell and starts having a case: clues spread across
visual / document / phone / UV / behaviour, with some channels deliberately
silent.

**The largest fun-delta in the plan, and it adds no new tool** — it makes the
five already built matter.

### Section 5 — The Casebook — §18

The anomaly database. Tells are discovered through play, not handed over.

**Here because** a chain is exactly the thing worth recording, and because it is
cheap and it is half the retention thesis.

### Section 6 — Something Got Inside — §5.5, §5.6, §8, §9, §11

The consequence loop. A wrong admit puts an anomaly *in the motel*. Events fire
on the clock. CCTV and the phone carry the evidence. The culprit is
identifiable.

**This is Nightdesk's identity** per §8 of the design, and it is what finally
gives CCTV something to show.

### Section 7 — Unreliable Sanity — §10

Sanity bands corrupt perception: false tells, misleading CCTV, hallucinated
guests. Real and fake anomalies start to look alike.

**After 4 and 6 because it works by corrupting them.** Before them there is
nothing to corrupt.

### Section 8 — Confront / Defend — §12

The survival verb. Stun, interrupt, buy time, protect a teammate. Never a kill
button.

### Section 9 — Economy & Upgrade Depth — §19, §20

The itemised payout the design specifies, and upgrades that buy *information*.
Where the phone upgrade returns as a real feature rather than a price tag.

### Section 10 — Ship — §21, §23, §27

Pacing pass, a first night that teaches, an audit against §23's avoid-list,
launch.

---

## Schedule reality

Halloween 2026 is about eight weeks out. Ten sections do not fit eight weeks at
a comfortable pace.

**Must ship:** 1, 2, 3, 4, 5, 6, 9.
**Cut first if time runs out:** 8, then 7.

Section 8 is the one the design itself warns against overusing (§12, §23), so it
is the cheapest thing to lose. The standing call stands: if it slips, ship
anyway rather than wait a year for the next October.

---

## Standing invariants

Carried forward from `docs/NEXT.md` and extended by each section. Check these on
every review — this list exists because things on it have been undone before.

| check | why |
|---|---|
| `State.luau` untouched | persistence is verified and fragile |
| no `Camera.CFrame` writes added | that was the frozen-camera bug; shake uses `Humanoid.CameraOffset` |
| exactly one `judge:FireServer` in `src/client` | more than one is the phantom-judgement bug |
| every desk key bound once | a second binding makes both fire and cancel |
| `SanityUpdate` stays separate from `ShiftUpdate` | coffee is not a verdict |
| `Loadout` ownership gates intact | three shop items were placebo without them |
| `sendNext` only ever called after `claimArrival` | otherwise the bell and the post-verdict timer both deliver a guest |
| phone honours rooms 101–108 | the ledger has to be read for the phone to mean anything |
| guests are blocky, surface-detailed, and seed-deterministic | the doctrine in AGENTS.md §2; sculpted anatomy is withdrawn |
| `selene` still at 2 warnings | new dead code is how unimplemented branches hid before |
| Play pressed, `[nightdesk] server initialized` seen | build and lint cannot see a runtime failure |
| pushed, not just committed | forgotten twice |
