--!strict
--[[
	Config.luau
	-----------
	All the placeholder greybox layout numbers for the base map, in one place
	so proportions can be tuned without hunting through the builder modules.

	Axes: the conveyor line runs along X. Studios line up along Z on the
	"Left" side (negative Z) and "Right" side (positive Z), facing inward
	toward Z = 0. GroundY is the single walkable surface height shared by the
	ground, the conveyor, the stages and every studio floor, so nothing needs
	a step or a jump to reach.
]]

local Config = {}

Config.Map = {
	-- The single flat height (in studs) every walkable surface tops out at.
	GroundY = 0,

	-- Central conveyor walkway.
	ConveyorWidth = 14, -- size along Z
	ConveyorHeight = 1, -- slab thickness
	ConveyorColor = Color3.fromRGB(95, 95, 105),

	-- Entrance/exit stages at each end of the conveyor.
	StageLength = 26, -- size along X
	StageWidth = 30, -- size along Z (a bit wider than the conveyor)
	StageHeight = 1,
	StageColor = Color3.fromRGB(150, 110, 190),

	-- How much bare conveyor sits between the last studio plot and each stage.
	EndMargin = 14,

	-- Studio plots (evenly spaced along X on both sides of the conveyor).
	StudiosPerSide = 9,
	StudioWidth = 16, -- size along X
	StudioDepth = 20, -- size along Z, extending away from the conveyor
	StudioGap = 4, -- gap between neighboring plots along X
	StudioFloorHeight = 1,
	StudioFloorColor = Color3.fromRGB(210, 210, 220),
	StudioWallHeight = 8,
	StudioWallThickness = 1,
	StudioWallColor = Color3.fromRGB(160, 160, 175),
	SlotMarkerColor = Color3.fromRGB(255, 210, 60),

	-- Open lawn beyond the stages/studios so nothing ends in a cliff edge.
	GroundMargin = 20,
	GroundThickness = 2,
	GroundColor = Color3.fromRGB(80, 150, 95),
}

return Config
