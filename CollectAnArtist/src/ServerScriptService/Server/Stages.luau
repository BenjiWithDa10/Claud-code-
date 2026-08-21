--!strict
--[[
	Stages.luau
	-----------
	Builds the entrance and exit stages, one at each end of the conveyor
	line. Each stage is a flat platform (same flush ground height as
	everything else) with a marked "SpawnerSquare" showing exactly where
	artists will appear/despawn, framed on three sides by a small booth --
	its back wall and two short side walls sit flush against the square's
	edges, no gap.
]]

local Stages = {}

local function buildStage(
	folder: Folder,
	name: string,
	centerX: number,
	outwardSign: number,
	layout: { [string]: any }
)
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

	-- The spawner square, inset from the platform's outward edge.
	local squareSize = layout.StageSpawnerSize
	local outerEdgeX = centerX + outwardSign * (layout.StageLength / 2)
	local spawnerX = outerEdgeX - outwardSign * (squareSize / 2 + layout.StageSpawnerMargin)

	local spawner = Instance.new("Part")
	spawner.Name = "SpawnerSquare"
	spawner.Anchored = true
	spawner.CanCollide = false
	spawner.Size = Vector3.new(squareSize, 0.2, squareSize)
	spawner.Color = layout.SlotMarkerColor
	spawner.Material = Enum.Material.Neon
	spawner.CFrame = CFrame.new(spawnerX, layout.GroundY + 0.1, 0)
	spawner.Parent = stageFolder

	-- Booth: a back wall flush against the square's outward edge, plus two
	-- short side walls flush against its left/right edges. Open toward the
	-- conveyor (inward), same convention as the studio rooms.
	local wallHeight = layout.StageBoothWallHeight
	local wallThickness = layout.StageBoothWallThickness
	local wallCenterY = layout.GroundY + wallHeight / 2

	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Anchored = true
	backWall.Size = Vector3.new(wallThickness, wallHeight, squareSize)
	backWall.CFrame = CFrame.new(
		spawnerX + outwardSign * (squareSize / 2 + wallThickness / 2),
		wallCenterY,
		0
	)
	backWall.Color = layout.StageBoothColor
	backWall.Material = Enum.Material.SmoothPlastic
	backWall.Parent = stageFolder

	for _, zSign in ipairs({ -1, 1 }) do
		local sideWall = Instance.new("Part")
		sideWall.Name = zSign == -1 and "LeftWall" or "RightWall"
		sideWall.Anchored = true
		sideWall.Size = Vector3.new(squareSize, wallHeight, wallThickness)
		sideWall.CFrame = CFrame.new(
			spawnerX,
			wallCenterY,
			zSign * (squareSize / 2 + wallThickness / 2)
		)
		sideWall.Color = layout.StageBoothColor
		sideWall.Material = Enum.Material.SmoothPlastic
		sideWall.Parent = stageFolder
	end
end

function Stages.build(folder: Folder, layout: { [string]: any })
	local halfConveyor = layout.ConveyorLength / 2

	buildStage(folder, "EntranceStage", -halfConveyor - layout.StageLength / 2, -1, layout)
	buildStage(folder, "ExitStage", halfConveyor + layout.StageLength / 2, 1, layout)
end

return Stages
