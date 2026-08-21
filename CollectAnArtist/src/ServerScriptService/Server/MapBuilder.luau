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
		├── Ground          (the lawn everything else sits on, dropped below
		│                    every floor so it never z-fights with them)
		├── ConveyorLine
		│   └── Walkway
		├── Stages
		│   ├── EntranceStage (Platform, SpawnerSquare, BackWall, Left/RightWall)
		│   └── ExitStage     (Platform only -- its despawner lives in Crowd.Tunnel)
		├── Studios
		│   ├── Left
		│   │   ├── Plot_1 ... Plot_N
		│   └── Right
		│       ├── Plot_1 ... Plot_N
		└── Crowd          (a "C" shape: open behind the entrance stage, closed
		                    tight behind the exit stage -- see Crowd.luau)
			├── Barrier    (invisible walls; none on the entrance end, notched
			│               around the tunnel mouth on the exit end)
			├── Risers     (solid ascending steps; bottom rows cut for the tunnel)
			├── Figures    (many rows of person-scale dark silhouettes)
			└── Tunnel     (a real recessed passage into the exit wall)
				├── LeftWall/RightWall/Ceiling/Floor (per fade segment, mouth to back)
				├── Backdrop     (dark cap at the very back)
				└── SpawnerSquare (the despawner, inside the passage)

	MapBuilder.build() is idempotent -- calling it again (e.g. repeatedly
	from the Command Bar while tweaking Config values) destroys the previous
	Map folder first, so it never leaves stale/duplicate copies behind. This
	also lets you build a permanent, editable copy of the map straight into
	the place without pressing Play: paste into the Command Bar --
		require(game.ServerScriptService.Server.MapBuilder).build()
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)

local ConveyorLine = require(script.Parent.ConveyorLine)
local Stages = require(script.Parent.Stages)
local Studios = require(script.Parent.Studios)
local Crowd = require(script.Parent.Crowd)

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

-- The ground's full footprint -- also used to place the crowd/barrier ring
-- just outside its edges.
local function groundFootprint(layout: { [string]: any }): (number, number)
	local totalX = layout.ConveyorLength + 2 * layout.StageLength + 2 * layout.GroundMargin
	local totalZ = layout.ConveyorWidth
		+ 2 * layout.StudioConveyorGap
		+ 2 * layout.StudioDepth
		+ 2 * layout.GroundMargin
	return totalX, totalZ
end

local function buildGround(mapFolder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	-- Top face sits GroundDrop below every floor above it, so it's never
	-- coplanar with (and can't z-fight against) the conveyor/stage/studio
	-- floors resting on top of it.
	local topY = layout.GroundY - layout.GroundDrop

	local ground = Instance.new("Part")
	ground.Name = "Ground"
	ground.Anchored = true
	ground.Size = Vector3.new(totalX, layout.GroundThickness, totalZ)
	ground.CFrame = CFrame.new(0, topY - layout.GroundThickness / 2, 0)
	ground.Color = layout.GroundColor
	ground.Material = Enum.Material.SmoothPlastic
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.BottomSurface = Enum.SurfaceType.Smooth
	ground.Parent = mapFolder
end

function MapBuilder.build(): Folder
	local existing = Workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end

	local layout = buildLayout()
	local totalX, totalZ = groundFootprint(layout)

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace

	buildGround(mapFolder, layout, totalX, totalZ)

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

	local crowdFolder = Instance.new("Folder")
	crowdFolder.Name = "Crowd"
	crowdFolder.Parent = mapFolder
	Crowd.build(crowdFolder, layout, totalX, totalZ)

	return mapFolder
end

return MapBuilder
