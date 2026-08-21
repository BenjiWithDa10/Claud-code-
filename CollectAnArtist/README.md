# Collect an Artist

Base map layout, generated from code and synced into Roblox Studio with
[Rojo](https://rojo.space) — same approach as the other project in this repo,
kept in its own folder so the two games don't collide.

## Layout

- A central **conveyor line** (`Map.ConveyorLine.Walkway`) running down the
  middle, flush with the rest of the ground — no stairs or jumps needed.
- An **entrance stage** and **exit stage** (`Map.Stages`), one at each end of
  the conveyor.
- Placeholder **studio plots** (`Map.Studios.Left` / `Map.Studios.Right`),
  4 per side (8 total, the current cap), spaced well apart from each other
  and from the conveyor, facing inward toward it. Each plot is a floor + 3
  walls (open toward the conveyor) with an `ArtistSlotMarker` to build the
  real artist-slot logic on top of later.
- A ring of blocky **mountains** (`Map.Mountains`) around the outside of the
  ground, so the map reads as having a natural edge instead of just an
  invisible wall.

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

## Tuning the layout

All the spacing/size numbers live in
`src/ReplicatedStorage/Shared/Config.luau` (`Config.Map`) — e.g.
`StudiosPerSide`, `StudioWidth`/`StudioDepth`, `StudioGap`,
`StudioConveyorGap`, `ConveyorWidth`, `EndMargin`, and the `Mountains`
sub-table for the border wall. The conveyor's length is derived
automatically from the studio count and size, so proportions stay
consistent if you change the plot count. `StudiosPerSide` is capped at 4
(8 total) by an assertion in `Config.luau`.
