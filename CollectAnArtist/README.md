# Collect an Artist

Base map layout, generated from code and synced into Roblox Studio with
[Rojo](https://rojo.space) — same approach as the other project in this repo,
kept in its own folder so the two games don't collide.

## Layout

- A central **conveyor line** (`Map.ConveyorLine.Walkway`) running down the
  middle, flush with the rest of the ground — no stairs or jumps needed.
- An **entrance stage** and **exit stage** (`Map.Stages`), one at each end of
  the conveyor. The entrance stage has a `SpawnerSquare` marking where
  artists appear, framed on three sides by a small booth (`BackWall`,
  `LeftWall`, `RightWall`) sitting flush against the square's edges. The
  exit stage is just a bare platform — its despawner lives inside the
  crowd's tunnel instead (see below).
- Placeholder **studio plots** (`Map.Studios.Left` / `Map.Studios.Right`),
  4 per side (8 total, the current cap), spaced well apart from each other
  and from the conveyor, facing inward toward it. Each plot is a floor + 3
  walls (open toward the conveyor) with an `ArtistSlotMarker` to build the
  real artist-slot logic on top of later.
- A stylized static **crowd** (`Map.Crowd`) built like real stadium seating:
  an invisible collision `Barrier`, solid ascending `Risers`, and many rows
  (10 by default) of small, person-scale dark silhouette `Figures` standing
  on top of each riser — height comes from stacking rows, not from oversized
  figures, so it reads as layers of people rather than a few flat panels.
  The ring is a **"C" shape, not a closed loop**: it's completely open
  behind the entrance stage (west end, where artists spawn in — an open
  performance-stage backdrop, no crowd or barrier at all) and pulled in
  tight against the exit stage's platform edge (east end, where artists
  despawn) so there's no walkable space behind the despawner. The two long
  sides (studios) are unchanged, chamfered into the exit wall at their east
  end and left open-ended at their west tip.

  The exit wall has a real stadium **player-tunnel** (`Map.Crowd.Tunnel`)
  built into it: a recessed passage — side walls, a floor, and a `Roof`
  (a handful of ribs approximating a shallow arch, tallest at the center,
  tapering to meet the wall tops) — one consistent solid color throughout,
  no gradient. The doorway is a person-scale archway (`TunnelWidth` x
  `TunnelHeight`, 16x14 by default; `TunnelArchRise`/`TunnelArchSegments`
  control the roof's curve). Rows above `TunnelRows` continue uninterrupted
  on their own, arching over the passage. The mouth-to-back darkening comes
  from separate semi-transparent
  `Haze` cards standing in the passage's open air (`TunnelHazeSteps` of
  them, ramping from `TunnelHazeNearTransparency` to
  `TunnelHazeFarTransparency`) rather than from the walls' own material, so
  looking down the tunnel compounds into a real fade toward darkness;
  a dark `Backdrop` caps the very end. The despawner (`SpawnerSquare`, sized
  via `TunnelDespawnerSize` to fit the doorway) sits inside the passage
  itself (`TunnelDespawnerInset` studs in from the mouth) instead of out on
  the open field. The invisible barrier follows a matching notch shape —
  flush with the rest of the exit wall except across the tunnel's width,
  where it steps back `TunnelBarrierInset` studs into the mouth, so players
  can see a short way in (including the despawner, unreachable) before
  hitting the wall — it's still a purely visual passage, not new walkable
  space beyond that notch. No animation/cheering or day-night
  reaction yet — those are future hooks — but the whole look is
  config-driven via `Config.Map.Crowd` so they're easy to add later.

No spawn logic or gameplay scripts yet — this is purely the greybox layout,
built by `MapBuilder.luau` when the server starts.

## Running it

```bash
# 1. Install the toolchain (from this folder)
aftman install            # or: rokit install

# 2. Start the Rojo server
rojo serve

# 3. In Roblox Studio: open a new baseplate, open the Rojo plugin panel,
#    and click "Connect". The map builds itself as soon as you press Play.
```

### Building it without pressing Play

To see (and edit) the map as permanent parts in Studio's Edit mode, open the
**Command Bar** (View tab → Command Bar) and run:

```lua
require(game.ServerScriptService.Server.MapBuilder).build()
```

This builds the exact same map the server builds at runtime, but as regular
parts that persist in the place and can be selected/moved/inspected without
ever pressing Play. It's safe to re-run after tweaking `Config.luau` — each
call clears out the previous `Map` folder first, so you never end up with
stale duplicates.

## Tuning the layout

All the spacing/size numbers live in
`src/ReplicatedStorage/Shared/Config.luau` (`Config.Map`) — e.g.
`StudiosPerSide`, `StudioWidth`/`StudioDepth`, `StudioGap`,
`StudioConveyorGap`, `ConveyorWidth`, `EndMargin`, the `StageSpawnerSize`/
`StageBooth*` values for each stage's booth, and the `Crowd` sub-table
(row count/spacing/height, figure size, color, transparency, the global
atmosphere haze, and the `Tunnel*` values for the exit tunnel's size, fade
colors and barrier/despawner insets) for the border. The conveyor's length is derived
automatically from the studio count and size, so proportions stay
consistent if you change the plot count. `StudiosPerSide` is capped at 4
(8 total) by an assertion in `Config.luau`.
