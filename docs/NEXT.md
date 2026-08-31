# The plan from here

Written 28 August 2026, at the point where the game first works end to end.

---

## Where the project actually is

The loop is closed. All of this is verified, not assumed:

- 42 anomalies, every one observable, tiered 60/33/7 subtle → overt
- Every investigation tool has something to find — the ledger has eight
  corruptible fields, the phone answers three ways, the UV light reveals marks
- Shift loop with sanity, an economy, and a between-shift shop
- Upgrades survive logout — ProfileStore round trip proven against the published
  place (`PlaceId=106512529474987`)
- Input works: one verdict path, one binding per key

**What is missing is not a feature. It is that the game does not look like
anything yet.**

---

## Why the art pass is now blocking, not cosmetic

You spent an entire cycle making anomalies subtle. A tier-1 anomaly is a skin
tone 4% off, a blink every 14 seconds instead of 4, a button in the wrong hole.

Those are invisible in the current build — and not because they are badly made.
The lighting is:

```
Ambient              0.03, 0.03, 0.04
OutdoorAmbient       0.02, 0.02, 0.03
Brightness           0.4
ExposureCompensation -0.1
```

Ambient is effectively zero. Nothing is lit except what a PointLight or
SpotLight directly touches, so every surface is either **pitch black or blown
out**. There is no middle range — and the entire game design lives in the middle
range.

**A 4% skin-tone shift cannot register on a surface that is either black or
white.** Fix the light and 25 of your anomalies become playable for the first
time.

## And the materials are one number

```
272 material assignments across 15 types
zero SurfaceAppearance or MaterialVariant instances
```

Stock Roblox materials are the visual signature of an unfinished game. But the
distribution is extremely top-heavy:

| material | assignments | share |
|---|---|---|
| SmoothPlastic | 76 | 28% |
| Metal | 67 | 25% |
| Wood | 40 | 15% |
| Fabric | 40 | 15% |
| Plaster | 12 | 4% |
| Leather | 11 | 4% |
| WoodPlanks | 7 | 3% |
| everything else | 19 | 7% |

**Eight materials cover 95% of every surface in the game.**

And Studio's MCP exposes `generate_material`, which produces a PBR
**MaterialVariant** from a text description. No Blender, no texture authoring, no
uploads — and it applies per material, not per part. Eight calls.

That is the highest leverage available anywhere in this project right now.

---

## Order of work

**1 — The art pass** *(the mega prompt below)*
Materials, then lighting, then verify by looking. One session.

**2 — Re-run the playtest**
`docs/prompts/playtest.md`. The last verdict — *"a dark room where neon blocks
spawn and you are penalised for things you cannot see"* — was measured against a
build where no interaction key worked and clicks fired random verdicts. Both are
fixed. That answer is stale and needs replacing with a real one.

**3 — Co-op**
2–4 players on one desk. The argument over whether a guest is wrong is the social
hook and the reason anyone tells a friend. This is the last thing between the
game and its own design.

**4 — Ship into Halloween**
Roughly nine weeks out. Horror gets about a 3× CCU multiplier and the standing
advice is to launch *before* it so you carry momentum in. If it slips, ship
anyway — do not sit on it for a year waiting for the next October.

---

# The mega prompt

Self-contained. Paste into a fresh session.

```bash
cd $HOME\Desktop\nightdesk
agy --model gemini-3.1-pro-high
```

Thinking model. This is judgement about how a room reads, not typing.

---

```
You are working on nightdesk, a co-op anomaly-horror game on Roblox. Read
AGENTS.md and docs/ROBLOX.md before writing anything.

Roblox Studio is open with the place loaded and you have the Roblox_Studio MCP
server available. Use it.

THE PROBLEM

The game mechanically works: 42 anomalies, a shift loop, a shop, persistence.
But it does not look like anything, and that is now blocking the design rather
than merely unattractive.

The anomalies were deliberately made subtle. A tier-1 tell is a skin tone 4%
off, a blink every 14 seconds instead of 4, one button in the wrong hole. Those
require a readable middle range of light to be perceivable at all.

Currently Ambient is 0.03 and Brightness is 0.4, so nothing is lit except what a
PointLight directly touches. Every surface is either pitch black or blown out.
There is no middle range, so 25 subtle anomalies are invisible — not badly made,
literally unable to be seen.

Fixing this makes most of the game playable for the first time.

TASK 1 — MATERIALS

The project has 272 material assignments and zero MaterialVariant or
SurfaceAppearance instances. Stock Roblox materials are why it reads as
unfinished. The distribution is top-heavy:

  SmoothPlastic 76 | Metal 67 | Wood 40 | Fabric 40
  Plaster 12 | Leather 11 | WoodPlanks 7 | Concrete 1

Eight materials cover 95% of every surface.

Use the Roblox_Studio MCP tool `generate_material` for each. It takes a
baseMaterial, a materialDescription and a materialPattern, and returns a
MaterialVariant name. Set BOTH the Material and MaterialVariant properties on
the parts that use it.

Write descriptions that belong to this specific building — a rain-soaked highway
motel at 2am that has been running since the seventies. Not "wood": worn oak
reception counter, decades of elbow polish, water rings near the edge. Not
"fabric": stained brown-orange lobby carpet, traffic paths worn through to the
backing.

Do not touch geometry. That is the whole point of MaterialVariant — the same
part reads completely differently.

TASK 2 — LIGHTING

The room needs a floor of ambient light so that surfaces not directly lit are
still readable. Dark, not black.

Raise Ambient and OutdoorAmbient until you can make out wall texture, floor
detail and a guest's face across the counter without a light pointed at them.
Then check ExposureCompensation and any Bloom instance in src/client/Atmosphere
— if props still glow while the room stays dark, bloom intensity is too high or
its threshold too low.

The target is a readable, oppressive 2am, not a dark room with glowing objects.
Keep Technology = Future.

TASK 3 — VERIFY BY LOOKING, NOT BY REASONING

This is not optional and it is the part most likely to be skipped.

Use `screen_capture` with explicit camera_position and look_at_position to frame
these shots, and actually look at each one:

  1. Standing at the desk, facing the guest position (0, 4.8, 1.8)
  2. The reception counter close up
  3. Down the hallway
  4. A guest's face at conversation distance

For shot 4, ask yourself the only question that matters: could you see a 4%
skin-tone difference here? If not, the lighting is still wrong and TASK 2 is not
done. Iterate. Do not report success off a capture you did not examine.

DO NOT TOUCH — these were all just fixed and are easy to undo by accident

- src/server/State.luau. Persistence is verified working; leave it alone.
- Atmosphere.shakeCamera. It uses Humanoid.CameraOffset deliberately. Writing
  Camera.CFrame instead was a bug that froze the player's view.
- The input bindings. Every desk key is bound exactly once now. Adding a
  ContextActionService binding beside an existing ProximityPrompt makes both fire
  and they cancel — that bug made F and Q appear completely dead.
- DeskProps.setVerdictHandler. There is exactly one judge:FireServer call in the
  entire client and it must stay that way. slamStamp firing the remote directly
  let any mouse click pass judgement on a guest.
- The Anomalies.rollable pool and the UNOBSERVABLE table.

VERIFY BEFORE FINISHING
  rojo build -o nightdesk.rbxl
  selene src/ tools/      (2 warnings expected, both unused params in
                           buildHorrorArchetypes -- do not add more)
  stylua src/ tools/

Then COMMIT AND PUSH. git push origin master is part of finishing.

REPORT
- The eight materials, with the description you wrote for each.
- The lighting values before and after.
- Which capture shows a guest's face, and your honest answer on whether a 4%
  skin-tone shift would be visible in it.
- Anything you deliberately left out.
```

---

## Review checklist for the next Claude session

| check | why |
|---|---|
| `MaterialVariant` set, not just `Material` | generating a variant and not applying it changes nothing |
| geometry untouched | the leverage is materials-without-remodelling; a geometry diff means it missed the point |
| `Ambient` actually raised | this is the fix; a bloom tweak alone does not create a middle range |
| a face capture exists and was examined | the 4% question is the acceptance test |
| `State.luau` untouched | persistence is newly verified and fragile |
| no `Camera.CFrame` writes added | that was the frozen-camera bug |
| exactly one `judge:FireServer` in `src/client` | more than one means the phantom-judgement bug is back |
| every desk key bound once | a second binding on a key makes both fire and cancel |
| selene still at 2 warnings | new dead code is how unimplemented branches hid before |
| pushed, not just committed | forgotten twice |
