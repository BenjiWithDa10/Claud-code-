--!strict
--[[
	EntranceStage.luau
	------------------
	Builds a large-scale concert-stage complex spanning the entire west
	(entrance) side of the map, so nothing is visible past or around it:

	- A raised riser (the flat performance area) as wide as the map itself.
	- A center-stage spawner mark and a backdrop screen behind it.
	- A tall angled canopy roof -- not a flat ceiling -- held up by a back
	  truss wall of posts with crisscrossing diagonal bracing.
	- Hanging lights along the canopy's front edge.
	- Two side support towers, each with its own speaker stack, anchoring
	  both ends of the structure right at (and slightly past) the map's
	  actual edge, so there's no gap to see or walk around.
	- The low ramp/walkway down to the conveyor (tapered sides, small
	  flanking speakers) leading out from center-stage, unchanged in spirit
	  from the original simple version.

	Only the entrance stage gets this treatment. The exit stage stays a
	bare platform (see Stages.luau) since its own "performance" happens
	inside the tunnel instead.
]]

local EntranceStage = {}

-- A slab tilted between two (x,y) points at a fixed Z -- shared by the
-- ramp (tread + tapered aprons) and the canopy roof. Local +X (before
-- rotation) points from (x1,y1) to (x2,y2); Size.X becomes the slab's
-- hypotenuse length.
local function buildSlopedSlab(
	folder: Folder,
	name: string,
	x1: number,
	y1: number,
	x2: number,
	y2: number,
	zCenter: number,
	zWidth: number,
	thickness: number,
	color: Color3,
	canCollide: boolean
)
	local run, rise = x2 - x1, y2 - y1
	local hyp = math.sqrt(run * run + rise * rise)
	if hyp < 0.01 then
		return
	end
	local angle = math.atan2(rise, run)

	local slab = Instance.new("Part")
	slab.Name = name
	slab.Anchored = true
	slab.CanCollide = canCollide
	slab.Size = Vector3.new(hyp, thickness, zWidth)
	slab.CFrame = CFrame.new((x1 + x2) / 2, (y1 + y2) / 2, zCenter) * CFrame.Angles(0, 0, angle)
	slab.Color = color
	slab.Material = Enum.Material.SmoothPlastic
	slab.Parent = folder
end

-- A thin diagonal beam between two (y, z) points at a fixed X -- used for
-- the back truss wall's crisscross bracing.
local function buildDiagonalBrace(
	folder: Folder,
	x: number,
	y1: number,
	z1: number,
	y2: number,
	z2: number,
	thickness: number,
	color: Color3
)
	local dy, dz = y2 - y1, z2 - z1
	local hyp = math.sqrt(dy * dy + dz * dz)
	if hyp < 0.01 then
		return
	end
	local angle = math.atan2(dz, dy)

	local brace = Instance.new("Part")
	brace.Name = "Brace"
	brace.Anchored = true
	brace.CanCollide = false
	brace.Size = Vector3.new(thickness, hyp, thickness)
	brace.CFrame = CFrame.new(x, (y1 + y2) / 2, (z1 + z2) / 2) * CFrame.Angles(angle, 0, 0)
	brace.Color = color
	brace.Material = Enum.Material.Metal
	brace.Parent = folder
end

-- Builds the full-width riser (flat elevated performance area, shorter
-- than the full stage footprint -- the rest is the ramp). Returns the
-- riser's own center X, the stage's inner (conveyor-facing) edge X, the
-- outer (back) edge X, and the half-width the whole structure spans.
local function buildRiser(
	stageFolder: Folder,
	centerX: number,
	layout: { [string]: any },
	totalZ: number
): (number, number, number, number)
	local E = layout.EntranceStage
	local outerEdgeX = centerX - layout.StageLength / 2
	local innerEdgeX = centerX + layout.StageLength / 2
	local flatLength = layout.StageLength - E.RampLength
	local flatCenterX = outerEdgeX + flatLength / 2
	local halfSpan = totalZ / 2 + E.SpanOverlap / 2

	local riser = Instance.new("Part")
	riser.Name = "Riser"
	riser.Anchored = true
	riser.Size = Vector3.new(flatLength, E.RiserElevation, halfSpan * 2)
	riser.CFrame = CFrame.new(flatCenterX, layout.GroundY + E.RiserElevation / 2, 0)
	riser.Color = layout.StageColor
	riser.Material = Enum.Material.SmoothPlastic
	riser.TopSurface = Enum.SurfaceType.Smooth
	riser.BottomSurface = Enum.SurfaceType.Smooth
	riser.Parent = stageFolder

	return flatCenterX, innerEdgeX, outerEdgeX, halfSpan
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

local function buildBackdrop(stageFolder: Folder, outerEdgeX: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local stageTopY = layout.GroundY + E.RiserElevation

	local panel = Instance.new("Part")
	panel.Name = "Panel"
	panel.Anchored = true
	panel.Size = Vector3.new(E.BackdropThickness, E.BackdropHeight, E.BackdropWidth)
	panel.CFrame = CFrame.new(outerEdgeX + E.BackdropThickness / 2, stageTopY + E.BackdropHeight / 2, 0)
	panel.Color = E.BackdropColor
	panel.Material = Enum.Material.SmoothPlastic
	panel.Parent = stageFolder
end

-- ----------------------------------------------------------------------------
-- Canopy: a tall angled roof spanning between the two side towers, plus
-- the back truss wall (posts + crisscross bracing) holding up its back
-- edge, plus hanging lights along its front edge.
-- ----------------------------------------------------------------------------

local function buildCanopy(stageFolder: Folder, outerEdgeX: number, halfSpan: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local canopyFolder = Instance.new("Folder")
	canopyFolder.Name = "Canopy"
	canopyFolder.Parent = stageFolder

	local stageTopY = layout.GroundY + E.RiserElevation
	local backX = outerEdgeX
	local frontX = outerEdgeX + E.CanopyDepth
	local backY = stageTopY + E.CanopyBackHeight
	local frontY = stageTopY + E.CanopyFrontHeight
	local roofHalfWidth = halfSpan - E.TowerWidth

	-- The roof panel itself: one wide slab tilted from the tall back edge
	-- down to the lower front edge.
	buildSlopedSlab(
		canopyFolder,
		"Roof",
		backX,
		backY,
		frontX,
		frontY,
		0,
		roofHalfWidth * 2,
		E.CanopyThickness,
		E.CanopyColor,
		false
	)

	-- Back truss wall: posts spanning the roof's full width, with
	-- crisscrossing diagonal braces between each adjacent pair.
	local trussFolder = Instance.new("Folder")
	trussFolder.Name = "Truss"
	trussFolder.Parent = canopyFolder

	local postCount = math.max(2, E.TrussPostCount)
	local postXs = {}
	for i = 0, postCount - 1 do
		local z = -roofHalfWidth + (i / (postCount - 1)) * (roofHalfWidth * 2)
		postXs[i + 1] = z

		local post = Instance.new("Part")
		post.Name = "Post"
		post.Anchored = true
		post.Size = Vector3.new(E.TrussPostThickness, E.CanopyBackHeight, E.TrussPostThickness)
		post.CFrame = CFrame.new(backX, stageTopY + E.CanopyBackHeight / 2, z)
		post.Color = E.TrussColor
		post.Material = Enum.Material.Metal
		post.Parent = trussFolder
	end

	for i = 1, postCount - 1 do
		local zA, zB = postXs[i], postXs[i + 1]
		buildDiagonalBrace(trussFolder, backX, stageTopY, zA, backY, zB, E.TrussBraceThickness, E.TrussColor)
		buildDiagonalBrace(trussFolder, backX, backY, zA, stageTopY, zB, E.TrussBraceThickness, E.TrussColor)
	end

	-- Hanging lights along the canopy's front edge.
	local lightsFolder = Instance.new("Folder")
	lightsFolder.Name = "Lights"
	lightsFolder.Parent = canopyFolder

	local lightCount = math.max(1, E.LightCount)
	for i = 0, lightCount - 1 do
		local t = if lightCount > 1 then i / (lightCount - 1) else 0.5
		local z = -roofHalfWidth + t * (roofHalfWidth * 2)

		local light = Instance.new("Part")
		light.Name = "Light"
		light.Anchored = true
		light.CanCollide = false
		light.Shape = Enum.PartType.Ball
		light.Size = Vector3.new(E.LightSize, E.LightSize, E.LightSize)
		light.CFrame = CFrame.new(frontX, frontY - E.LightSize, z)
		light.Color = E.LightColor
		light.Material = Enum.Material.Neon
		light.Parent = lightsFolder
	end
end

-- ----------------------------------------------------------------------------
-- Side support towers anchoring both ends of the structure, each with its
-- own speaker stack. Their outer faces reach the map's actual edge (plus
-- SpanOverlap), so there's nothing to see or walk around past them.
-- ----------------------------------------------------------------------------

local function buildTowers(stageFolder: Folder, flatCenterX: number, halfSpan: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local towersFolder = Instance.new("Folder")
	towersFolder.Name = "Towers"
	towersFolder.Parent = stageFolder

	local stageTopY = layout.GroundY + E.RiserElevation
	local towerHeight = E.CanopyBackHeight

	for _, sign in ipairs({ -1, 1 }) do
		local sideFolder = Instance.new("Folder")
		sideFolder.Name = if sign == -1 then "Left" else "Right"
		sideFolder.Parent = towersFolder

		local z = sign * (halfSpan - E.TowerWidth / 2)

		local tower = Instance.new("Part")
		tower.Name = "Tower"
		tower.Anchored = true
		tower.Size = Vector3.new(E.TowerDepth, towerHeight, E.TowerWidth)
		tower.CFrame = CFrame.new(flatCenterX, stageTopY + towerHeight / 2, z)
		tower.Color = E.TowerColor
		tower.Material = Enum.Material.SmoothPlastic
		tower.Parent = sideFolder

		-- A simple crisscross brace standing just outside the tower's front
		-- face (offset by its own half-thickness so it isn't embedded
		-- inside the tower's solid core and stays visible).
		local faceX = flatCenterX - E.TowerDepth / 2 - E.TrussBraceThickness / 2
		buildDiagonalBrace(sideFolder, faceX, stageTopY, z - E.TowerWidth / 3, stageTopY + towerHeight, z + E.TowerWidth / 3, E.TrussBraceThickness, E.TowerColor)
		buildDiagonalBrace(sideFolder, faceX, stageTopY + towerHeight, z - E.TowerWidth / 3, stageTopY, z + E.TowerWidth / 3, E.TrussBraceThickness, E.TowerColor)

		-- A big speaker stack at the tower's base, resting on top of the
		-- (full-width) riser the tower itself stands on.
		local cabinet = Instance.new("Part")
		cabinet.Name = "SpeakerCabinet"
		cabinet.Anchored = true
		cabinet.Size = Vector3.new(E.TowerSpeakerDepth, E.TowerSpeakerCabinetHeight, E.TowerSpeakerWidth)
		cabinet.CFrame = CFrame.new(
			flatCenterX,
			stageTopY + E.TowerSpeakerCabinetHeight / 2,
			z
		)
		cabinet.Color = E.TowerSpeakerColor
		cabinet.Material = Enum.Material.SmoothPlastic
		cabinet.Parent = sideFolder

		local horn = Instance.new("Part")
		horn.Name = "SpeakerHorn"
		horn.Anchored = true
		horn.Size = Vector3.new(E.TowerSpeakerDepth * 0.7, E.TowerSpeakerHornHeight, E.TowerSpeakerWidth * 0.7)
		horn.CFrame = CFrame.new(
			flatCenterX,
			stageTopY + E.TowerSpeakerCabinetHeight + E.TowerSpeakerHornHeight / 2,
			z
		)
		horn.Color = E.TowerSpeakerColor
		horn.Material = Enum.Material.SmoothPlastic
		horn.Parent = sideFolder
	end
end

-- ----------------------------------------------------------------------------
-- Ramp down to the conveyor: a main tread plus tapered side aprons.
-- ----------------------------------------------------------------------------

local function buildRamp(stageFolder: Folder, innerEdgeX: number, layout: { [string]: any })
	local E = layout.EntranceStage
	local rampFolder = Instance.new("Folder")
	rampFolder.Name = "Ramp"
	rampFolder.Parent = stageFolder

	local rampStartX = innerEdgeX - E.RampLength
	local rampEndX = innerEdgeX
	local topY = layout.GroundY + E.RiserElevation
	local bottomY = layout.GroundY

	buildSlopedSlab(
		rampFolder,
		"Tread",
		rampStartX,
		topY,
		rampEndX,
		bottomY,
		0,
		E.RampWidth,
		E.RampThickness,
		layout.StageColor,
		true
	)

	-- Side aprons: a few stepped slices per side, each shorter than the
	-- last, tapering the ramp's edges down to the ground instead of a
	-- vertical drop.
	local sliceWidth = E.RampSideTaperWidth / E.RampSideTaperSegments
	for _, sign in ipairs({ -1, 1 }) do
		for slice = 0, E.RampSideTaperSegments - 1 do
			local scale = 1 - (slice + 1) / (E.RampSideTaperSegments + 1)
			local z = sign * (E.RampWidth / 2 + slice * sliceWidth + sliceWidth / 2)

			buildSlopedSlab(
				rampFolder,
				"Apron",
				rampStartX,
				layout.GroundY + E.RiserElevation * scale,
				rampEndX,
				bottomY,
				z,
				sliceWidth,
				E.RampThickness,
				layout.StageColor,
				true
			)
		end
	end
end

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

function EntranceStage.build(stagesFolder: Folder, centerX: number, layout: { [string]: any }, totalZ: number)
	local stageFolder = Instance.new("Folder")
	stageFolder.Name = "EntranceStage"
	stageFolder.Parent = stagesFolder

	local flatCenterX, innerEdgeX, outerEdgeX, halfSpan = buildRiser(stageFolder, centerX, layout, totalZ)

	buildSpawner(stageFolder, flatCenterX, layout)
	buildBackdrop(stageFolder, outerEdgeX, layout)
	buildCanopy(stageFolder, outerEdgeX, halfSpan, layout)
	buildTowers(stageFolder, flatCenterX, halfSpan, layout)
	buildRamp(stageFolder, innerEdgeX, layout)
	buildSpeakers(stageFolder, innerEdgeX, layout)
end

return EntranceStage
