--!strict
--[[
	Stages.luau
	-----------
	Builds the exit stage -- a bare flat platform (same flush ground height
	as everything else) at the east end of the conveyor. Its despawner
	lives inside the player-tunnel built into the crowd structure instead
	(see Crowd.luau), not on the platform itself.

	The entrance stage, at the west end, is a full concert-stage complex
	instead of a plain platform -- see EntranceStage.luau.
]]

local EntranceStage = require(script.Parent.EntranceStage)

local Stages = {}

local function buildPlatform(folder: Folder, name: string, centerX: number, layout: { [string]: any })
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = name
	stageFolder.Parent = folder

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.Size = Vector3.new(layout.StageLength, layout.StageHeight, layout.StageWidth)
	platform.CFrame = CFrame.new(centerX, layout.GroundY - layout.StageHeight / 2, 0)
	platform.Color = layout.StageColor
	platform.Material = Enum.Material.SmoothPlastic
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = stageFolder
end

function Stages.build(folder: Folder, layout: { [string]: any }, totalZ: number)
	local halfConveyor = layout.ConveyorLength / 2

	EntranceStage.build(folder, -halfConveyor - layout.StageLength / 2, layout, totalZ)
	buildPlatform(folder, "ExitStage", halfConveyor + layout.StageLength / 2, layout)
end

return Stages
