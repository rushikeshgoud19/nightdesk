# Session kickoff prompts

Copy-paste starters. They exist so a session begins with the agent oriented
instead of guessing, and so two different agents start from the same place.

`AGENTS.md` is read automatically by `agy` and (via `CLAUDE.md`) by Claude Code.
These prompts add the *task*, not the rules.

---

## Starting a build session

```
Read docs/ROBLOX.md before writing anything — it holds the platform facts, the
asset limits, and the traps, so you do not have to guess at them.

State: week 1 is done and runs. A guest walks to the desk, you admit or refuse,
the server scores it. src/ is lint-clean and formatted.

Next: the shift timer and guest queue (week 2 of the plan in README.md).
- A shift is a fixed length with a queue of guests, not one guest forever.
- Sanity drains on a wrong call and is visible to the player.
- The shift ends, banks the takings, and starts the next one.

Constraints, non-negotiable:
- The server decides every verdict and every payout. The client sends intent only.
- No game logic inside Studio's script editor. Everything lives in src/.
- Replace, do not layer. If you supersede something, delete the old path in the
  same change.
- Leave the game playable at every commit.

When done: run `stylua src/` and `selene src/`, and tell me what you changed and
what you deliberately left out.
```

---

## Starting an asset session

```
Read docs/ROBLOX.md section 6 before generating or exporting anything.

I need <asset description> for the motel.

Route:
- Identity assets (desk, lobby, anything on the thumbnail): model in Blender.
- Filler props: PolyHaven first (CC0, no licence risk), then decimate.
- Always export with tools/blender_export.py, never Blender's export menu — it
  handles the 0.01 scale factor, applies transforms on a duplicate, and checks
  the triangle budget.

Budget: 10,000 triangles, 1024x1024 textures. Over budget means Studio rejects
the import, so check before you export, not after.

Tell me the triangle count of what you made.
```

---

## Reviewing someone else's change

```
Review the working tree against docs/ROBLOX.md and AGENTS.md.

Look specifically for:
- Any payout, score, or state change decided on the client.
- RemoteEvent handlers that do not validate argument type before using them.
- WaitForChild without a timeout.
- Unanchored parts.
- Comments claiming a security property the code does not actually have.

Report findings worst-first. Do not fix anything yet.
```

---

## A note on which model

`agy models` lists what is available. Rough split that has held up:

- `gemini-3.7-flash-high` — bulk work, anomaly table entries, refactors
- `gemini-3.1-pro-high` / `claude-opus-4-6-thinking` — architecture, the
  server-authority code, anything where a wrong answer is expensive
- `claude-sonnet-4-6` — reviews

Run `agy` interactively. `agy -p` cannot ask for tool permissions, so it silently
denies them and produces nothing.
