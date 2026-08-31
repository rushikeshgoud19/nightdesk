<!-- markdownlint-disable MD033 -->
# nightdesk

Co-op anomaly horror on Roblox. You work the night desk of the Crestview Highway
Motel at 2am in a rainstorm. Guests arrive. Some of them are not guests. You
decide who gets a room, and between shifts you spend the takings on the motel.

Built in first person: you stand behind the counter, walk around the lobby, and
work the job with physical tools — a bell, a ledger, a rotary phone, a UV
blacklight, an intercom, and two rubber stamps.

**This repo is also a working agent pipeline** — Rojo + Blender + Antigravity +
the Roblox Studio MCP, all wired together and documented. If you only want that
part, delete `src/` and keep the rest.

---

## Start here (new contributor)

Everything is pinned, so you get the same versions as everyone else.

### 1. Toolchain

```powershell
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

```bash
rokit install
selene generate-roblox-std
rojo plugin install
```

That installs Rojo 7.7.0, Wally 0.3.2, Selene 0.31.0 and StyLua 2.5.2 from
`rokit.toml`, generates Selene's Roblox standard library (gitignored, per-clone),
and installs the Rojo Studio plugin.

### 2. Run it

```bash
rojo serve
```

Open Roblox Studio → any place → Rojo plugin → **Connect** → press Play.

You spawn behind the reception counter in first person. The lobby builds itself
on the server at boot.

### 3. The agent (optional, but it's the point)

```powershell
irm https://antigravity.google/cli/install.ps1 | iex
```

Open a **new terminal** afterwards — `agy` adds itself to PATH and the old shell
won't see it. Then from the repo root:

```bash
agy
```

`AGENTS.md` loads automatically and carries the architecture and the rules.
`CLAUDE.md` is a one-line import of it, so Claude Code gets the same brief.

Read **[docs/PIPELINE.md](docs/PIPELINE.md)** before your first agy session —
there are two permission quirks that will otherwise waste an hour.

---

## Controls

| Key | Action |
|---|---|
| `W A S D` + mouse | Walk and look, first person |
| `E` / click | Ring the service bell |
| `F` / click | Inspect the registration ledger |
| `G` | Intercom — ask the guest one of three questions |
| `T` / click | Rotary phone — call the assigned room |
| `Q` | UV blacklight — reveals marks on documents |
| `C` | Cycle the CCTV monitor |
| `Z` / click | **ADMIT** stamp |
| `X` / click | **REFUSE** stamp |
| `E` (office) | Coffee maker — restores sanity, once per shift |
| `E` (hallway) | Reset the breaker during a blackout |
| `E` (lounge) | Vending machine — $5 for a soda |

---

## How it fits together

```
src/shared/    → ReplicatedStorage.Shared      types, 42 anomalies, remote declarations, shop catalogue
src/server/    → ServerScriptService.Server    AUTHORITY: shifts, verdicts, economy, lobby construction
src/client/    → StarterPlayerScripts.Client   RENDERING AND INPUT ONLY
tools/         Blender asset scripts (the script is the source, not the .blend)
docs/          the reference material — read ROBLOX.md before writing Roblox code
```

**The one rule everything else follows:** the server decides every verdict and
every payout. The client renders what it is told and sends intent. Assume every
client is hostile, because some will be.

The lobby is **built by the server at boot** (`src/server/BuildLobby.luau`), not
stored as files. That is why `Workspace` looks almost empty in the project config.

---

## Daily commands

```bash
rojo serve                      # sync to Studio, leave running
stylua src/ tools/              # format
selene src/ tools/              # lint
rojo build -o nightdesk.rbxl    # standalone place file
```

Both linters pass clean on `main`. Keep it that way.

---

## Where the project is

**Working now:**

- **Persistence.** ProfileStore, session-locked, `BindToClose` wired. Verified by
  round trip against the published place: buy an upgrade, log out, log back in,
  still owned.
- First-person clerk with full desk interaction — bell, ledger, phone, UV light,
  intercom, CCTV, admit/refuse stamps
- 42 anomalies, 6 sculpted horror archetypes for guests
- Shift loop with sanity: wrong calls drain it, hitting zero ends the night and
  forfeits the takings, surviving above 50 pays a bonus
- Between-shift shop. Upgrades buy **information** — without them most anomalies
  show you nothing. That is the retention spine, not a bolt-on
- Server-built lobby, atmosphere, rain, footsteps
- Facility chores: coffee for sanity, breaker resets during blackouts, vending

**Not done, roughly in order:**

1. **The art pass.** The project has zero `SurfaceAppearance` instances against
   154 stock material assignments, which is why guests read as blocky avatars and
   the lighting blooms out. This is not cosmetic any more: a 4% skin-tone
   anomaly cannot register when every surface is either black or blown out.
2. **Co-op.** The design is 2–4 players on one desk; the argument over whether a
   guest is wrong is the social hook. Currently single-player.
3. **A real playtest.** Nobody has sat down and judged whether the loop is
   actually fun. Everything above is verified to *run*, not to be *good*.

---

## Why this game

Not taste — a market read, written up in `docs/`. Anomaly horror was still
expanding when this started (roughly 4,000 → 286,000 peak CCU across seven games,
Dec 2023 → May 2026), the genre differentiates by **workplace setting** rather
than mechanic, and motels were unclaimed. The upgrade tree exists to fix horror's
weak day-8-to-28 retention, which is what Roblox's discovery algorithm started
weighting hardest in June 2026.

If a change would ship the anomaly loop without the progression layer, that is
the thing to push back on.

---

## Docs

| File | What it's for |
|---|---|
| [AGENTS.md](AGENTS.md) | Architecture and rules. Auto-loaded by `agy` and Claude Code. |
| [PROJECT_MEMORY.md](PROJECT_MEMORY.md) | Deep narrative state — setting, horror archetypes, subagent roster. |
| [docs/ROBLOX.md](docs/ROBLOX.md) | Platform reference. Limits, asset routes, traps. Read before writing Roblox code. |
| [docs/PIPELINE.md](docs/PIPELINE.md) | How Rojo, Blender, Studio MCP and agy fit — and what's verified vs broken. |
| [docs/PROMPT.md](docs/PROMPT.md) | Copy-paste session starters. |
| [docs/NEXT.md](docs/NEXT.md) | **Start here if you are picking this up.** The plan from here and the prompt for the next session. |
| [docs/playtest-findings.md](docs/playtest-findings.md) | What the first real playtest found, verified rather than reported. |

## Licence

MIT. Take the pipeline, ignore the game.
