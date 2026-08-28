# Prompt: persistence (agy builds, Claude reviews)

The standing #1 gap. `State.luau` is in-memory, so every upgrade the player buys
evaporates on logout — which kills the entire retention thesis the game is built
on.

Run from the repo root:

```bash
agy --model gemini-3.1-pro-high
```

Use `gemini-3.1-pro-high` or `claude-opus-4-6-thinking`, not a flash model. This
is architecture, and a wrong answer here loses player data rather than looking
slightly off.

---

```
Read AGENTS.md and docs/ROBLOX.md section 4 before writing anything. Section 4
is specifically about persistence and it tells you what not to hand-roll.

TASK: make player progress survive logout.

Right now src/server/State.luau holds profiles in a plain table. When a player
leaves, everything is gone: takings, owned upgrades, nights worked. The shop is
the retention spine of this game and it currently means nothing.

REQUIREMENTS

1. Use ProfileStore (https://github.com/MadStudioRoblox/ProfileStore) via Wally.
   Add it to wally.toml, run `wally install`, and wire the Packages folder into
   default.project.json so Rojo serves it. Do NOT hand-roll DataStore access.
   Session locking, retry logic and autosave are exactly the three things a naive
   implementation gets wrong, and ProfileStore already does all three.

2. Persist only what should survive a session:
   - takings
   - owned (the upgrade set)
   - nightsWorked
   Do NOT persist live shift state. sanity, current, guestsLeft, tellVisible,
   shiftActive, shiftStartTakings, hasBrewedCoffee and breakerTripped are
   per-shift and must reset on load. A player who logs out mid-shift should come
   back between shifts, not mid-guest.

3. Add a schemaVersion field to the saved profile from the very first commit,
   and a migration path that reads it. Migrating data you never versioned is
   genuinely painful and you cannot retrofit it later.

4. game:BindToClose is mandatory. Players.PlayerRemoving does not fire reliably
   on server shutdown; without BindToClose you lose the last session of every
   player on every restart. This is stated in docs/ROBLOX.md and it is not
   optional.

5. Keep State.luau's public interface the same shape: load / get / release.
   Shift.luau and Shop.luau both depend on it and neither should need editing.
   If you must change the interface, change the callers in the same commit -- do
   not leave a shim.

DO NOT TOUCH

- Anything in src/client/. This is a server-side data change.
- The server-authority pattern. The server still decides every verdict and every
  payout; nothing about persistence changes who is allowed to compute what.
- BuildLobby.luau, IntroUI.luau, Theme.luau, DeskUI.luau, ShopUI.luau. They were
  just rebuilt and they work. Leave them alone.
- Do not add a compatibility layer for the old in-memory path. Replace it.

VERIFY BEFORE YOU FINISH

- rojo build -o nightdesk.rbxl
- selene src/ tools/
- stylua src/ tools/
- Test in Studio with the Roblox_Studio MCP: start a playtest, buy an upgrade,
  stop the playtest, start it again, and confirm the upgrade is still owned.
  DataStores do not work in Studio unless "Enable Studio Access to API Services"
  is on in Game Settings -> Security. If it is off, say so plainly rather than
  reporting a pass you did not observe.

THEN COMMIT AND PUSH. Last time you committed without pushing and the work sat
invisible on one machine. `git push origin master` is part of finishing.

REPORT
- What you changed and why.
- Whether the save/load round trip actually ran in Studio, or whether API
  services blocked it.
- Anything you deliberately left out.
```

---

## Review checklist (Claude, after agy finishes)

| check | why |
|---|---|
| `BindToClose` present and actually saves | without it, every server restart loses the last session |
| live shift fields reset on load | otherwise a mid-shift logout returns you mid-guest with a stale guest |
| `schemaVersion` written on every save | you cannot add versioning to data that already exists |
| `State.load/get/release` shape unchanged | Shift and Shop both depend on it |
| no client files touched | persistence is server-only; client edits mean scope creep |
| old in-memory path deleted, not wrapped | repo rule: replace, do not layer |
| `Packages/` gitignored, `wally.lock` committed | lockfile is source, installed packages are not |
| pushed, not just committed | agy has forgotten this before |
