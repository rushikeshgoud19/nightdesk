# Prompt: make the anomalies almost invisible

The single most important change the game needs. Everything else is polish on a
loop that currently has no tension.

```bash
agy --model gemini-3.1-pro-high
```

Use a thinking model. This is design judgement, not typing.

---

## The finding this is based on

Exit 8 — the game that created this genre — works because its environment is
*photorealistically mundane*, and its anomalies are things like **a stain on the
ceiling** or **a doorknob in the centre of a door**. Reviewers single out the
"wonky ceiling lights" for their *economy of terror*. The photorealism is not
decoration: it is load-bearing, because a departure from perfect ordinariness is
only frightening when the ordinary is convincing.

nightdesk currently does the opposite. Its six archetypes are:

| archetype | what it does |
|---|---|
| Flayed Mimic | glowing UV crimson suture stitches |
| Mandela Alternate | jaw dislocated ~25cm into an ear-to-ear void, 16 razor teeth |
| Broken Cervical | 85° lateral head snap, exposed vertebrae |
| Cavernous Hollow | pitch-black eye sockets, glowing red embers, streaming tears |
| Drowned Drifter | swollen grey-cyan flesh, seaweed, dripping particles |
| Void Silhouette | 100% light-absorbing black figure, electric cyan eyes |

Every one of these is identifiable in under half a second from across the lobby.
None of them is a *judgement call*. The game's core promise — you are not sure,
and being wrong costs you — cannot happen when the answer is a screaming void
with 16 teeth.

**The test an anomaly must pass: a careful player should sometimes miss it.**

---

```
Read docs/ROBLOX.md before writing anything. Read src/client/GuestRenderer.luau
and src/shared/Anomalies.luau fully before changing either.

CONTEXT
Exit 8 built this genre on photorealism plus tiny deviations -- a stain on a
ceiling, a doorknob in the wrong place. The horror comes from doubting yourself.

This game's six guest archetypes are all instantly identifiable: a jaw
dislocated 25cm, an 85-degree head snap, glowing eyes, a pure black silhouette.
None of them is a judgement call. That kills the entire loop, because the player
is never uncertain, and uncertainty is the product.

TASK: rebuild the anomaly presentation around subtlety.

1. TIER THE ANOMALIES. Not every anomaly should be equally hard, but the
   distribution is currently inverted. Target roughly:
   - 60% SUBTLE      -- a careful player can miss these. One property is wrong.
   - 30% NOTICEABLE  -- findable if you actually look at the guest.
   - 10% OVERT       -- the existing monsters. Keep two of the six at most, and
                        make them rare, so they land when they do appear.

2. WHAT A SUBTLE ANOMALY LOOKS LIKE. One changed property on an otherwise
   normal guest. Examples of the right magnitude:
   - skin tone 4% off from the others in the same lighting
   - blinks once every 14 seconds instead of every 4
   - stands 3 studs from the counter when everyone else stands at 2
   - one shirt button done up wrong
   - head tracks the player half a second late
   - casts no shadow, or a shadow at the wrong angle
   - perfectly symmetrical face -- real faces are not
   - never shifts weight while idle
   Not: extra limbs, voids, glowing anything, particle effects.

3. SAME CONSTRUCTION, DIFFERENT VALUE. A normal guest and a subtle anomaly must
   be built by the SAME code path, differing only in a value. If anomalies get
   built by a special branch that adds parts, players learn to spot the seam
   rather than the tell. Refactor so that a guest is a table of properties and
   an anomaly is that table with one field altered.

4. KEEP THE TELL AND THE VISUAL IN SYNC. src/shared/Anomalies.luau holds 42
   written tells. Every visual anomaly must correspond to a tell the player can
   actually observe, and every tell must have a visual. If a tell says "they left
   wet footprints", there must be wet footprints. Report any tell you cannot
   render and any visual with no matching tell -- do not quietly drop either.

5. THE UPGRADE TREE ALREADY DEPENDS ON THIS. Upgrades buy tell VISIBILITY
   (src/shared/Upgrades.luau, Upgrades.stats -> tellChance). That mechanic is
   meaningless while every anomaly is obvious. Subtle anomalies are what make the
   corridor lights and the lobby camera worth buying.

CONSTRAINTS
- Server still decides what is an anomaly and what it pays. The client renders.
  Never move that judgement to the client.
- Do not touch src/server/State.luau. Persistence was just fixed and is fragile.
- Do not touch Atmosphere.shakeCamera. The camera bug was just fixed; it uses
  Humanoid.CameraOffset deliberately and must not go back to writing Camera.CFrame.
- Leave the game playable. rojo build, selene src/ tools/, stylua src/ tools/.
- Commit AND push.

REPORT
- The new tier distribution, with a one-line description of each anomaly and
  which tier it is in.
- Which of the six existing archetypes you kept, and which you cut.
- Any tell in Anomalies.luau you could not render.
- Honestly: would YOU be able to miss the subtle ones?
```

---

## Phase two, after this lands: the visual foundation

Do not run this at the same time. It is a separate pass and mixing them makes
both unreviewable.

The project currently contains **zero** `SurfaceAppearance` instances and 154
built-in `Enum.Material` assignments. Stock Roblox materials are the visual
signature of an unfinished game — and per the Exit 8 finding, a convincing
ordinary is what makes a subtle anomaly frightening. PBR is not decoration here,
it is the thing that makes tier-1 anomalies possible.

The leverage is that `SurfaceAppearance` changes how a surface reads **without
touching geometry** — the same part becomes worn linoleum, brushed steel or
water-stained plaster from four texture maps. No remodelling required.

Highest-value surfaces first: the counter top, the floor, the walls behind the
desk, and guest skin.

---

## Review checklist (Claude, after agy finishes)

| check | why |
|---|---|
| normal and subtle guests share one code path | a separate branch becomes a visual seam players learn |
| no `Camera.CFrame` writes reintroduced | that was the stuck-camera bug |
| `State.luau` untouched | persistence is newly fixed and fragile |
| every tell has a visual, every visual has a tell | otherwise upgrades reveal nothing |
| server still decides anomaly status | the whole economy rests on it |
| tier distribution actually matches the claim | count them, do not trust the summary |
| pushed, not just committed | agy has forgotten twice |
