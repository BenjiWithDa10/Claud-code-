--!strict
--[[
	EntranceStage.luau
	------------------
	Builds the full "concert stage" complex at the entrance end of the map:
	a raised stage riser with the spawner centered on it (like a
	performer's mark), a low ramp/walkway sloping down from the riser to
	the conveyor's ground level -- with its own sides tapering down to the
	ground rather than a vertical drop -- a simple backdrop + lighting
	truss behind the spawn point, and speaker stacks flanking the ramp.

	Only the entrance stage gets this treatment. The exit stage stays a
	bare platform (see Stages.luau) since its own "performance" happens
	inside the tunnel instead.
]]

local EntranceStage = {}

-- Builds the flat elevated performance area (shorter than the full stage
-- footprint -- the rest is the ramp). Returns the riser's own center X and
-- the stage's inner (conveyor-facing) edge X.
local function buildRiser(stageFolder: Folder, centerX: number, layout: { [string]: any }): (number, number)
	local E = layout.EntranceStage
	local outerEdgeX = centerX - layout.StageLength / 2
	local innerEdgeX = centerX + layout.StageLength / 2
	local flatLength = layout.StageLength - E.RampLength
	local flatCenterX = outerEdgeX + flatLength / 2

	local riser = Instance.new("Part")
	riser.Name = "Riser"
	riser.Anchored = true
	riser.Size = Vector3.new(flatLength, E.RiserElevation, layout.StageWidth)
	riser.CFrame = CFrame.new(flatCenterX, layout.GroundY + E.RiserElevation / 2, 0)
	riser.Color = layout.StageColor
	riser.Material = Enum.Material.SmoothPlastic
	riser.TopSurface = Enum.SurfaceType.Smooth
	riser.BottomSurface = Enum.SurfaceType.Smooth
	riser.Parent = stageFolder

	return flatCenterX, innerEdgeX
end

local function buildSpawner(stageFolder: Folder, flatCenterX: number, layout: { [string]: any })
	local E = layout.EntranceStage

	local spawner = Instance.new("Part")
	spawner.Name = "SpawnerSquare"
	spawner.Anchored = true
	spawner.CanCollide = false
	spawner.Size = Vector3.new(layout.StageSpawnerSize, 0.2, layout.StageSpawnerSize)
	spawner.Color = layout.SlotMarkerColor
	spawner.Material = Enum.Material.Neon
	spawner.CFrame = CFrame.new(flatCenterX, layout.GroundY + E.RiserElevation + 0.1, 0)
	spawner.Parent = stageFolder
end

-- ----------------------------------------------------------------------------
-- Ramp: one slab helper reused for the main tread and every tapered side
-- slice -- each is just a rotated box climbing from 0 height at rampEndX
-- up to riseHeight at rampStartX.
-- ----------------------------------------------------------------------------

local function buildRampSlab(
	folder: Folder,
	name: string,
	rampStartX: number,
	rampEndX: number,
	riseHeight: number,
	zCenter: number,
	zWidth: number,
	thickness: number,
	groundY: number,
	color: Color3
)
	local run = rampEndX - rampStartX
	if run <= 0 or riseHeight <= 0 then
		return
	end

	local hyp = math.sqrt(run * run + riseHeight * riseHeight)
	local angle = -math.atan2(riseHeight, run)

	local slab = Instance.new("Part")
	slab.Name = name
	slab.Anchored = true
	slab.CanCollide = true
	slab.Size = Vector3.new(hyp, thickness, zWidth)
	slab.CFrame = CFrame.new((rampStartX + rampEndX) / 2, groundY + riseHeight / 2, zCenter)
		* CFrame.Angles(0, 0, angle)
	slab.Color = color
	slab.Material = Enum.Material.SmoothPlastic
	slab.Parent = folder
end

local function buildRamp(stageFolder: Folder, innerEdgeX: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local rampFolder = Instance.new("Folder")
	rampFolder.Name = "Ramp"
	rampFolder.Parent = stageFolder

	local rampStartX = innerEdgeX - E.RampLength
	local rampEndX = innerEdgeX

	buildRampSlab(
		rampFolder,
		"Tread",
		rampStartX,
		rampEndX,
		E.RiserElevation,
		0,
		E.RampWidth,
		E.RampThickness,
		layout.GroundY,
		layout.StageColor
	)

	-- Side aprons: a few stepped slices per side, each shorter than the
	-- last, tapering the ramp's edges down to the ground instead of a
	-- vertical drop.
	local sliceWidth = E.RampSideTaperWidth / E.RampSideTaperSegments
	for _, sign in ipairs({ -1, 1 }) do
		for slice = 0, E.RampSideTaperSegments - 1 do
			local scale = 1 - (slice + 1) / (E.RampSideTaperSegments + 1)
			local z = sign * (E.RampWidth / 2 + slice * sliceWidth + sliceWidth / 2)

			buildRampSlab(
				rampFolder,
				"Apron",
				rampStartX,
				rampEndX,
				E.RiserElevation * scale,
				z,
				sliceWidth,
				E.RampThickness,
				layout.GroundY,
				layout.StageColor
			)
		end
	end
end

-- ----------------------------------------------------------------------------
-- Backdrop + lighting truss, behind the spawn mark at the back of the stage.
-- ----------------------------------------------------------------------------

local function buildBackdrop(stageFolder: Folder, outerEdgeX: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local backdropFolder = Instance.new("Folder")
	backdropFolder.Name = "Backdrop"
	backdropFolder.Parent = stageFolder

	local stageTopY = layout.GroundY + E.RiserElevation

	local panel = Instance.new("Part")
	panel.Name = "Panel"
	panel.Anchored = true
	panel.Size = Vector3.new(E.BackdropThickness, E.BackdropHeight, E.BackdropWidth)
	panel.CFrame = CFrame.new(outerEdgeX + E.BackdropThickness / 2, stageTopY + E.BackdropHeight / 2, 0)
	panel.Color = E.BackdropColor
	panel.Material = Enum.Material.SmoothPlastic
	panel.Parent = backdropFolder

	-- A simple lighting truss: two posts and a beam spanning between them.
	local postX = outerEdgeX + 1 + E.TrussPostThickness / 2
	for _, sign in ipairs({ -1, 1 }) do
		local post = Instance.new("Part")
		post.Name = "TrussPost"
		post.Anchored = true
		post.Size = Vector3.new(E.TrussPostThickness, E.TrussHeight, E.TrussPostThickness)
		post.CFrame = CFrame.new(postX, stageTopY + E.TrussHeight / 2, sign * (E.BackdropWidth / 2 - 2))
		post.Color = E.TrussColor
		post.Material = Enum.Material.Metal
		post.Parent = backdropFolder
	end

	local beam = Instance.new("Part")
	beam.Name = "TrussBeam"
	beam.Anchored = true
	beam.Size = Vector3.new(E.TrussBeamThickness, E.TrussBeamThickness, E.BackdropWidth - 4)
	beam.CFrame = CFrame.new(postX, stageTopY + E.TrussHeight - E.TrussBeamThickness / 2, 0)
	beam.Color = E.TrussColor
	beam.Material = Enum.Material.Metal
	beam.Parent = backdropFolder

	-- A handful of small stage lights hanging off the beam.
	local lightSpan = E.BackdropWidth - 6
	for i = 0, E.LightCount - 1 do
		local t = if E.LightCount > 1 then i / (E.LightCount - 1) else 0.5
		local z = -lightSpan / 2 + t * lightSpan

		local light = Instance.new("Part")
		light.Name = "Light"
		light.Anchored = true
		light.CanCollide = false
		light.Shape = Enum.PartType.Ball
		light.Size = Vector3.new(E.LightSize, E.LightSize, E.LightSize)
		light.CFrame = CFrame.new(postX, stageTopY + E.TrussHeight - E.TrussBeamThickness - E.LightSize / 2, z)
		light.Color = E.LightColor
		light.Material = Enum.Material.Neon
		light.Parent = backdropFolder
	end
end

-- ----------------------------------------------------------------------------
-- Speakers flanking the ramp/walkway, evenly spaced on both sides.
-- ----------------------------------------------------------------------------

local function buildSpeakers(stageFolder: Folder, innerEdgeX: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local speakersFolder = Instance.new("Folder")
	speakersFolder.Name = "Speakers"
	speakersFolder.Parent = stageFolder

	local rampStartX = innerEdgeX - E.RampLength
	local z0 = E.RampWidth / 2 + E.RampSideTaperWidth + E.SpeakerInset

	for _, sign in ipairs({ -1, 1 }) do
		local sideFolder = Instance.new("Folder")
		sideFolder.Name = if sign == -1 then "Left" else "Right"
		sideFolder.Parent = speakersFolder

		for i = 0, E.SpeakerCount - 1 do
			local t = if E.SpeakerCount > 1 then i / (E.SpeakerCount - 1) else 0.5
			local x = rampStartX + t * E.RampLength
			local z = sign * z0

			local cabinet = Instance.new("Part")
			cabinet.Name = "Cabinet"
			cabinet.Anchored = true
			cabinet.Size = Vector3.new(E.SpeakerDepth, E.SpeakerCabinetHeight, E.SpeakerWidth)
			cabinet.CFrame = CFrame.new(x, layout.GroundY + E.SpeakerCabinetHeight / 2, z)
			cabinet.Color = E.SpeakerColor
			cabinet.Material = Enum.Material.SmoothPlastic
			cabinet.Parent = sideFolder

			local horn = Instance.new("Part")
			horn.Name = "Horn"
			horn.Anchored = true
			horn.Size = Vector3.new(E.SpeakerDepth * 0.7, E.SpeakerHornHeight, E.SpeakerWidth * 0.7)
			horn.CFrame = CFrame.new(x, layout.GroundY + E.SpeakerCabinetHeight + E.SpeakerHornHeight / 2, z)
			horn.Color = E.SpeakerColor
			horn.Material = Enum.Material.SmoothPlastic
			horn.Parent = sideFolder
		end
	end
end

function EntranceStage.build(stagesFolder: Folder, centerX: number, layout: { [string]: any })
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "EntranceStage"
	stageFolder.Parent = stagesFolder

	local flatCenterX, innerEdgeX = buildRiser(stageFolder, centerX, layout)
	local outerEdgeX = centerX - layout.StageLength / 2

	buildSpawner(stageFolder, flatCenterX, layout)
	buildBackdrop(stageFolder, outerEdgeX, layout)
	buildRamp(stageFolder, innerEdgeX, layout)
	buildSpeakers(stageFolder, innerEdgeX, layout)
end

return EntranceStage
