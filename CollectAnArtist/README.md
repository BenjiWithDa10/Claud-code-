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
  9 per side, evenly spaced, facing inward toward the conveyor. Each plot is
  a floor + 3 walls (open toward the conveyor) with an `ArtistSlotMarker` to
  build the real artist-slot logic on top of later.

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
`StudiosPerSide`, `StudioWidth`/`StudioDepth`, `ConveyorWidth`, `EndMargin`.
The conveyor's length is derived automatically from the studio count and
size, so proportions stay consistent if you change the plot count.
