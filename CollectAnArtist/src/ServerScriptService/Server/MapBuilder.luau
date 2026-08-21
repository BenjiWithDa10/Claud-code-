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
		│   ├── EntranceStage (a full-width concert-stage complex spanning the
		│   │                  entire west edge -- see EntranceStage.luau)
		│   │   ├── Riser          (the flat elevated performance area, as wide
		│   │   │                   as the map itself)
		│   │   ├── SpawnerSquare  (center-stage spawn mark)
		│   │   ├── Backdrop       (just a Panel -- truss/lights live on Canopy)
		│   │   ├── Canopy         (the tall angled roof)
		│   │   │   ├── Roof          (one wide tilted slab)
		│   │   │   ├── Truss         (Post x N along the back edge, plus
		│   │   │   │                  crisscrossing Brace pairs between them)
		│   │   │   └── Lights        (hanging Light x N along the front edge)
		│   │   ├── Towers         (Left/Right, anchoring both ends of the
		│   │   │                   structure at the map's actual edge)
		│   │   │   └── Tower, Brace x2, SpeakerCabinet, SpeakerHorn (each side)
		│   │   ├── Ramp           (Tread + tapered Apron slices down to the conveyor)
		│   │   └── Speakers       (Left/Right, Cabinet+Horn x N each, flanking the ramp)
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
				├── LeftWall/RightWall/Floor (single solid color, mouth to back)
				├── Roof         (a handful of ribs approximating a shallow arch)
				├── Haze         (semi-transparent cards fading toward the back)
				├── Backdrop     (dark cap at the very back)
				└── SpawnerSquare (the despawner, inside the passage)

	The map's pieces split into two tiers, and two different entry points:

	- Systemic/parametric pieces -- Ground, ConveyorLine, Studios -- are tied
	  directly to Config.Map numbers you might still want to retune, so
	  they're destroyed and rebuilt from scratch every time either entry
	  point below runs.
	- One-off aesthetic pieces -- Stages, Crowd -- are treated as permanent,
	  hand-built content once they exist: built ONCE via Command Bar, then
	  meant to be hand-edited, moved, and detailed directly in Studio and
	  never regenerated except on purpose.

	MapBuilder.buildRuntime() rebuilds only the systemic tier and never
	touches Stages/Crowd at all -- doesn't rebuild them, doesn't even create
	them if they're missing. This is what init.server.luau calls on every
	server start (including every Play session), so pressing Play can never
	wipe or otherwise disturb your manually-placed entrance stage, crowd, or
	tunnel -- whatever's already sitting in Workspace.Map.Stages/Crowd when
	Play starts is exactly what you'll see once it starts running.

	MapBuilder.build() is the manual, Command-Bar-only entry point: it does
	everything buildRuntime() does, PLUS creates Stages/Crowd if they don't
	already exist yet (leaving them alone if they do). Use it once to lay
	down the first code-generated copy of the entrance stage/crowd, or again
	after deliberately deleting one of those folders in Studio to regenerate
	it from scratch:
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

-- Destroys `name` under mapFolder if present, then hands a fresh empty
-- folder of that name back to be filled in -- the "always rebuild" path
-- for systemic/parametric pieces.
local function freshFolder(mapFolder: Folder, name: string): Folder
	local existing = mapFolder:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = mapFolder
	return folder
end

local function getOrCreateMapFolder(): Folder
	local existingMap = Workspace:FindFirstChild("Map")
	if existingMap then
		return existingMap :: Folder
	end

	local mapFolder = Instance.new("Folder")
	mapFolder.Name = "Map"
	mapFolder.Parent = Workspace
	return mapFolder
end

-- Rebuilds only the systemic/parametric tier (Ground, ConveyorLine,
-- Studios) fresh from the current Config -- never touches Stages/Crowd.
function MapBuilder.buildRuntime(): Folder
	local layout = buildLayout()
	local totalX, totalZ = groundFootprint(layout)
	local mapFolder = getOrCreateMapFolder()

	local existingGround = mapFolder:FindFirstChild("Ground")
	if existingGround then
		existingGround:Destroy()
	end
	buildGround(mapFolder, layout, totalX, totalZ)

	local conveyorFolder = freshFolder(mapFolder, "ConveyorLine")
	ConveyorLine.build(conveyorFolder, layout)

	local studiosFolder = freshFolder(mapFolder, "Studios")
	Studios.build(studiosFolder, layout)

	return mapFolder
end

-- Manual, Command-Bar-only: does everything buildRuntime() does, plus lays
-- down Stages/Crowd if (and only if) they don't already exist.
function MapBuilder.build(): Folder
	local layout = buildLayout()
	local totalX, totalZ = groundFootprint(layout)
	local mapFolder = MapBuilder.buildRuntime()

	if not mapFolder:FindFirstChild("Stages") then
		local stagesFolder = Instance.new("Folder")
		stagesFolder.Name = "Stages"
		stagesFolder.Parent = mapFolder
		Stages.build(stagesFolder, layout, totalZ)
	end

	if not mapFolder:FindFirstChild("Crowd") then
		local crowdFolder = Instance.new("Folder")
		crowdFolder.Name = "Crowd"
		crowdFolder.Parent = mapFolder
		Crowd.build(crowdFolder, layout, totalX, totalZ)
	end

	return mapFolder
end

return MapBuilder
