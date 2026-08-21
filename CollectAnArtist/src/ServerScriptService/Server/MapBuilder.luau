--!strict
--[[
	MapBuilder.luau
	---------------
	Assembles the whole base map: a lawn to stand on, the central conveyor
	line, the entrance/exit stages at each end, and the studio plots lining
	both sides. Everything is generated at runtime from these numbers, so
	the layout lives in code and syncs cleanly through Rojo -- no binary
	place file to hand-edit.

	Resulting hierarchy under Workspace:
		Map
		├── Ground          (the lawn everything else sits on)
		├── ConveyorLine
		│   └── Walkway
		├── Stages
		│   ├── EntranceStage
		│   └── ExitStage
		└── Studios
			├── Left
			│   ├── Plot_1 ... Plot_N
			└── Right
				├── Plot_1 ... Plot_N
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)

local ConveyorLine = require(script.Parent.ConveyorLine)
local Stages = require(script.Parent.Stages)
local Studios = require(script.Parent.Studios)

local MapBuilder = {}

-- Merge the static config with the layout numbers that depend on it (the
-- conveyor's length is derived from how many studio plots need to fit
-- alongside it, so proportions stay consistent if the plot count changes).
local function buildLayout(): { [string]: any }
	local M = Config.Map

	local layout = table.clone(M)

	local studioSpan = M.StudiosPerSide * M.StudioWidth + (M.StudiosPerSide - 1) * M.StudioGap
	layout.ConveyorLength = studioSpan + 2 * M.EndMargin

	return layout
end

local function buildGround(mapFolder: Folder, layout: { [string]: any })
	local totalX = layout.ConveyorLength + 2 * layout.StageLength + 2 * layout.GroundMargin
	local totalZ = layout.ConveyorWidth + 2 * layout.StudioDepth + 2 * layout.GroundMargin

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(totalX, layout.GroundThickness, totalZ)
	ground.CFrame = CFrame.new(0, layout.GroundY - layout.GroundThickness / 2, 0)
	ground.Color = layout.GroundColor
	ground.Material = Enum.Material.SmoothPlastic
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = mapFolder
end

function MapBuilder.build(): Folder
	local layout = buildLayout()

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace

	buildGround(mapFolder, layout)

	local conveyorFolder = Instance.new("Folder")
	conveyorFolder.Name = "ConveyorLine"
	conveyorFolder.Parent = mapFolder
	ConveyorLine.build(conveyorFolder, layout)

	local stagesFolder = Instance.new("Folder")
	stagesFolder.Name = "Stages"
	stagesFolder.Parent = mapFolder
	Stages.build(stagesFolder, layout)

	local studiosFolder = Instance.new("Folder")
	studiosFolder.Name = "Studios"
	studiosFolder.Parent = mapFolder
	Studios.build(studiosFolder, layout)

	return mapFolder
end

return MapBuilder
