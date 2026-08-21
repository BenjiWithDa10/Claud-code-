--!strict
--[[
	Config.luau
	-----------
	All the placeholder greybox layout numbers for the base map, in one place
	so proportions can be tuned without hunting through the builder modules.

	Axes: the conveyor line runs along X. Studios line up along Z on the
	"Left" side (negative Z) and "Right" side (positive Z), facing inward
	toward Z = 0. GroundY is the walkable surface height shared by the
	conveyor, the stages and every studio floor, so nothing needs a step or
	a jump to reach any of them. The ground/grass plane sits GroundDrop studs
	below that -- just enough that its top face is never coplanar with a
	floor above it (which is what was causing the grass to z-fight/poke
	through the studio floors), while still reading as one continuous level.
]]

local Config = {}

Config.Map = {
	-- The flat height (in studs) the conveyor, stages and studio floors top out at.
	GroundY = 0,
	-- How far below GroundY the grass plane's top sits, to keep it clear of
	-- every floor above it (fixes the ground/floor z-fighting).
	GroundDrop = 0.5,

	-- Central conveyor walkway.
	ConveyorWidth = 28, -- size along Z
	ConveyorHeight = 1, -- slab thickness
	ConveyorColor = Color3.fromRGB(95, 95, 105),

	-- Entrance/exit stages at each end of the conveyor.
	StageLength = 50, -- size along X
	StageWidth = 70, -- size along Z (a bit wider than the conveyor)
	StageHeight = 1,
	StageColor = Color3.fromRGB(150, 110, 190),

	-- The marked square on each stage where artists spawn in/despawn, and
	-- the small 3-sided booth framing it (back + 2 short side walls,
	-- flush against the square's edges -- no gap).
	StageSpawnerSize = 18,
	StageSpawnerMargin = 6, -- gap between the platform's outer edge and the square
	StageBoothWallHeight = 12,
	StageBoothWallThickness = 2,
	StageBoothColor = Color3.fromRGB(110, 80, 145),

	-- How much bare conveyor sits between the last studio plot and each stage.
	EndMargin = 60,

	-- Studio plots (evenly spaced along X on both sides of the conveyor).
	-- Total studio count is always StudiosPerSide * 2 -- capped at 8 (4/side).
	StudiosPerSide = 4,
	StudioWidth = 32, -- size along X
	StudioDepth = 48, -- size along Z, extending away from the conveyor
	StudioGap = 40, -- gap between neighboring plots along X
	StudioConveyorGap = 30, -- open breathing room between the conveyor edge and the studio row
	StudioFloorHeight = 2,
	StudioFloorColor = Color3.fromRGB(210, 210, 220),
	StudioWallHeight = 18,
	StudioWallThickness = 2,
	StudioWallColor = Color3.fromRGB(160, 160, 175),
	SlotMarkerColor = Color3.fromRGB(255, 210, 60),

	-- Open lawn beyond the stages/studios so nothing ends in a cliff edge.
	GroundMargin = 80,
	GroundThickness = 2,
	GroundColor = Color3.fromRGB(80, 150, 95),

	-- Mountains ringing the outside of the ground as a natural world border.
	Mountains = {
		Seed = 20240521,
		Depth = 60, -- how thick the mountain wall is, along the ring
		MinWidth = 60,
		MaxWidth = 140,
		OverlapFactor = 0.7, -- <1 so neighboring mountains overlap and hide seams
		MinHeight = 80,
		MaxHeight = 220,
		SnowHeight = 160, -- peaks taller than this get a lighter "snow cap" color
		BaseEmbed = 60, -- extra height buried below ground so there's never a gap underneath
		Color = Color3.fromRGB(90, 80, 75),
		SnowColor = Color3.fromRGB(215, 215, 220),
	},
}

Config.Map.StudiosTotal = Config.Map.StudiosPerSide * 2
assert(Config.Map.StudiosTotal <= 8, "Studios total must not exceed the 8-studio cap")

return Config
