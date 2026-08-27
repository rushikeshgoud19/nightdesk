# nightdesk — instructions for agents

A co-op anomaly-horror game on Roblox. You work the night desk of a highway motel
and decide which guests are real. Between shifts you spend the takings on the
motel itself.

## Non-negotiables

**Never edit game logic inside Roblox Studio.** Studio is a viewer and a test
harness here, nothing else. Every script lives in `src/` and reaches Studio
through Rojo. Anything typed into Studio's script editor is destroyed on the next
sync and is invisible to git. If a change needs to happen, it happens in a file.

**The server owns every decision that costs or pays money.** The client renders
what it is told and sends back intent. It never computes a score, a payout, a
fine, or a verdict. Assume the player has full control of their client, because
some of them will.

**Be honest about what the client can see.** The player must perceive the tell to
play, so the tell crosses the wire. Do not write comments claiming otherwise. The
boundary that holds is the verdict and the economy, not the tell.

**Layers, not scaffolding.** Every change leaves the game playable. Do not land a
half-finished system behind a flag and plan to finish it later. If the shape is
not known yet, say so before committing the repo to a direction.

**No compatibility layers.** When something is replaced, the old path is deleted
in the same change. There are no live players to keep working yet, so there is no
excuse for a fallback.

## Layout

```
src/shared/    ReplicatedStorage.Shared  -- types, anomaly table, remote declarations
src/server/    ServerScriptService.Server -- authority: guests, verdicts, economy
src/client/    StarterPlayerScripts.Client -- rendering and input only
```

`src/shared/Remotes.luau` is the only file that creates a RemoteEvent. If you need
a new one, declare it there so the whole client/server wire surface stays readable
in one screen.

## Content

`src/shared/Anomalies.luau` holds the anomaly table. The launch target is 40+
entries — a shift that can be memorised in three nights does not retain anyone.
Every entry needs a `tell` the player can actually observe at the desk. If it is
not observable, it is not an anomaly.

## Commands

```bash
rojo serve                      # sync to Studio, leave running
stylua src/                     # format
selene src/                     # lint
rojo build -o nightdesk.rbxl    # standalone place file
```

## Traps

- `roblox.yml` and `sourcemap.json` are generated and gitignored. If the LSP
  starts claiming `game` is undefined, regenerate them rather than editing them.
- Roblox `task.wait()` returns actual elapsed time, not the requested time. Never
  accumulate it as if it were exact.
- `Players.PlayerRemoving` does not fire reliably on server shutdown. Anything
  that must persist needs `game:BindToClose` as well, once saving exists.
