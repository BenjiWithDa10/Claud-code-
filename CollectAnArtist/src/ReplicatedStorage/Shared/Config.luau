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
	-- Kept fairly narrow so the crowd (which starts right at this edge)
	-- reads as close and looming rather than a distant backdrop.
	GroundMargin = 45,
	GroundThickness = 2,
	GroundColor = Color3.fromRGB(80, 150, 95),

	-- A stylized static crowd ringing the outside of the ground as the
	-- world's border: an invisible collision barrier right at the map's
	-- edge, plus tiered rows of simple dark silhouettes stepping outward
	-- and rising higher behind it (a "packed stadium crowd" read, not a
	-- flat wall). Not animated and not tied to lighting yet -- those are
	-- future hooks (a legendary-artist cheer event, a night flashlight
	-- effect) -- but every knob needed to drive them later lives here.
	Crowd = {
		Seed = 20260821,

		-- Invisible wall stopping players right at the map's edge, in front
		-- of the crowd. The crowd itself never collides with anything.
		-- Deliberately absent on the entrance (west) end -- see
		-- ExitWallBuffer below for how the shape is controlled.
		BarrierHeight = 40,
		BarrierThickness = 2,
		BarrierEmbed = 10, -- extra height buried below ground so it can't be slipped under

		-- The crowd ring is a "C" shape, not a full loop: it's open at the
		-- entrance stage's end (west, behind where artists spawn in -- an
		-- open performance-stage backdrop, not something to wall off) and
		-- pulled in tight against the exit stage's end (east, behind the
		-- despawner) so there's zero walkable space back there. Flush
		-- against the platform edge (0), not offset from it.
		ExitWallBuffer = 0, -- clearance beyond the exit stage's platform edge before the wall/crowd starts

		-- How much each straight edge is trimmed back at its corners and
		-- replaced by a diagonal fill, so the crowd wraps around each
		-- corner instead of meeting the next edge at a hard right angle.
		CornerChamfer = 35,

		-- Stadium risers: solid ascending steps behind the barrier. Each row
		-- of figures stands on top of its own riser -- total height comes
		-- from stacking many modest steps, not from oversized figures, so
		-- it reads as tiered seating rather than a few flat panels.
		RowCount = 10,
		RowDepth = 5, -- outward depth of each riser step (how far back each row sits)
		RowRise = 7, -- height gain per riser step
		RiserColor = Color3.fromRGB(55, 55, 62), -- neutral stand structure, distinct from the figures

		-- Individual figure silhouettes: person-scale, packed tight along
		-- each row's tread, with a bit of height variation so they don't
		-- all look cloned.
		FigureMinWidth = 2,
		FigureMaxWidth = 3.5,
		FigureDepth = 1.2,
		FigureGap = 0.3, -- small gap so the row still reads as densely packed
		PersonHeight = 6, -- average individual figure height
		PersonHeightJitter = 1.5, -- +/- random variation per figure
		HeadHeightFraction = 0.25,
		HeadWidthFraction = 0.55,
		MaxYawJitter = 10, -- degrees, so the row isn't perfectly uniform

		-- Dark, desaturated, slightly see-through so figures stay a soft
		-- backdrop instead of popping into focus.
		ColorDark = Color3.fromRGB(16, 16, 20),
		ColorLight = Color3.fromRGB(42, 42, 52),
		Transparency = 0.15,

		-- A light global haze that thickens the world's overall depth cues
		-- (not targeted at the crowd specifically) to fake a soft-focus,
		-- atmospheric edge without a real blur shader.
		EnableAtmosphere = true,
		AtmosphereColor = Color3.fromRGB(150, 150, 165),
		AtmosphereDecay = Color3.fromRGB(35, 35, 45),
		AtmosphereDensity = 0.3,
		AtmosphereHaze = 1.6,
		AtmosphereGlare = 0,
	},
}

Config.Map.StudiosTotal = Config.Map.StudiosPerSide * 2
assert(Config.Map.StudiosTotal <= 8, "Studios total must not exceed the 8-studio cap")

return Config
