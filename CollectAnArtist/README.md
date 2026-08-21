# Collect an Artist

Base map layout, generated from code and synced into Roblox Studio with
[Rojo](https://rojo.space) — same approach as the other project in this repo,
kept in its own folder so the two games don't collide.

## Layout

- A central **conveyor line** (`Map.ConveyorLine.Walkway`) running down the
  middle, flush with the rest of the ground — no stairs or jumps needed.
- An **entrance stage** and **exit stage** (`Map.Stages`), one at each end of
  the conveyor. Each has a `SpawnerSquare` marking where artists appear/
  despawn, framed on three sides by a small booth (`BackWall`, `LeftWall`,
  `RightWall`) sitting flush against the square's edges.
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
  end and left open-ended at their west tip. The exit wall also has a
  stadium **player-tunnel** cut into its bottom rows, centered on the
  despawner: those rows leave a gap instead of solid risers/figures there,
  capped by a dark recessed `Tunnel.Backdrop` a few rows back, while the
  rows above continue uninterrupted and arch over the opening — it reads as
  a tunnel mouth artists "leave through" when they despawn, without a fully
  modeled interior. The invisible barrier is untouched by the tunnel — it's
  a purely visual cut, not new walkable space. No animation/cheering or
  day-night reaction yet — those are future hooks — but the whole look is
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
(row count/spacing/height, figure size, color, transparency, and the
global atmosphere haze) for the border. The conveyor's length is derived
automatically from the studio count and size, so proportions stay
consistent if you change the plot count. `StudiosPerSide` is capped at 4
(8 total) by an assertion in `Config.luau`.
