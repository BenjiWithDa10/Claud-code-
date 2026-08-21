--!strict
--[[
	Studios.luau
	------------
	Blocks out an evenly-spaced row of placeholder studio plots on each side
	of the conveyor line, facing inward toward it. Each plot is a simple
	3-walled room (open on the conveyor-facing side) with a floor and a
	marker where an artist slot will go later -- just a box to build on top
	of, no logic yet.
]]

local Studios = {}

local function buildPlot(parent: Folder, name: string, center: Vector3, layout: { [string]: any })
	local plot = Instance.new("Folder")
	plot.Name = name
	plot.Parent = parent

	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = Vector3.new(layout.StudioWidth, layout.StudioFloorHeight, layout.StudioDepth)
	floor.CFrame = CFrame.new(center)
	floor.Color = layout.StudioFloorColor
	floor.Material = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = plot

	local floorTopY = center.Y + layout.StudioFloorHeight / 2
	local wallCenterY = floorTopY + layout.StudioWallHeight / 2

	-- Away from the conveyor: +Z for the right side, -Z for the left side.
	local awaySign = center.Z >= 0 and 1 or -1

	local backWall = Instance.new("Part")
	backWall.Name = "BackWall"
	backWall.Anchored = true
	backWall.Size = Vector3.new(layout.StudioWidth, layout.StudioWallHeight, layout.StudioWallThickness)
	backWall.CFrame = CFrame.new(
		center.X,
		wallCenterY,
		center.Z + awaySign * (layout.StudioDepth / 2 - layout.StudioWallThickness / 2)
	)
	backWall.Color = layout.StudioWallColor
	backWall.Material = Enum.Material.SmoothPlastic
	backWall.Parent = plot

	for _, xSign in ipairs({ -1, 1 }) do
		local sideWall = Instance.new("Part")
		sideWall.Name = xSign == -1 and "LeftWall" or "RightWall"
		sideWall.Anchored = true
		sideWall.Size = Vector3.new(layout.StudioWallThickness, layout.StudioWallHeight, layout.StudioDepth)
		sideWall.CFrame = CFrame.new(
			center.X + xSign * (layout.StudioWidth / 2 - layout.StudioWallThickness / 2),
			wallCenterY,
			center.Z
		)
		sideWall.Color = layout.StudioWallColor
		sideWall.Material = Enum.Material.SmoothPlastic
		sideWall.Parent = plot
	end

	-- Placeholder anchor for where an artist slot will be dropped in later.
	local slotMarker = Instance.new("Part")
	slotMarker.Name = "ArtistSlotMarker"
	slotMarker.Anchored = true
	slotMarker.CanCollide = false
	slotMarker.Size = Vector3.new(3, 0.2, 3)
	slotMarker.Color = layout.SlotMarkerColor
	slotMarker.Material = Enum.Material.Neon
	slotMarker.CFrame = CFrame.new(center.X, floorTopY + 0.1, center.Z)
	slotMarker.Parent = plot
end

function Studios.build(folder: Folder, layout: { [string]: any })
	local leftFolder = Instance.new("Folder")
	leftFolder.Name = "Left"
	leftFolder.Parent = folder

	local rightFolder = Instance.new("Folder")
	rightFolder.Name = "Right"
	rightFolder.Parent = folder

	local studioSpan = layout.StudiosPerSide * layout.StudioWidth
		+ (layout.StudiosPerSide - 1) * layout.StudioGap
	local startX = -studioSpan / 2 + layout.StudioWidth / 2
	local step = layout.StudioWidth + layout.StudioGap

	local floorCenterY = layout.GroundY - layout.StudioFloorHeight / 2
	local innerEdge = layout.ConveyorWidth / 2 + layout.StudioConveyorGap
	local leftZ = -(innerEdge + layout.StudioDepth / 2)
	local rightZ = innerEdge + layout.StudioDepth / 2

	for i = 0, layout.StudiosPerSide - 1 do
		local x = startX + i * step
		local plotName = "Plot_" .. (i + 1)

		buildPlot(leftFolder, plotName, Vector3.new(x, floorCenterY, leftZ), layout)
		buildPlot(rightFolder, plotName, Vector3.new(x, floorCenterY, rightZ), layout)
	end
end

return Studios
