--!strict
--[[
	Crowd.luau
	----------
	Rings the outside of the ground with a stylized, static crowd built like
	actual stadium seating: an invisible collision barrier sits right at the
	map's edge, and just beyond it, a stack of solid ascending "risers"
	carries many rows of small, person-scale silhouettes upward. Height
	comes from stacking many modest rows, not from oversized figures -- that
	way it reads as layers of people rather than a few flat panels.

	The ring is a "C" shape, not a closed loop:
	- The entrance stage's end (west, -X, where artists spawn in) is left
	  completely open -- no crowd, no barrier. It reads as the open
	  performance-stage/backstage direction rather than a walled-off edge.
	- The exit stage's end (east, +X, where artists despawn) is pulled in
	  tight against the stage's own platform edge instead of sitting out at
	  the far ground edge, so there's no walkable space behind the
	  despawner.
	- The long sides (north/south, where the studios are) are unchanged,
	  running the full ground edge -- open-ended at their west tip (nothing
	  to blend into) and chamfered into the exit wall at their east end.

	The exit wall also has a real player-tunnel built into it: a recessed
	passage (side walls, a shallow arched roof, and a floor, all one solid
	color, no gradient) that cuts through the bottom TunnelRows rows of
	risers/figures. Rows above TunnelRows continue uninterrupted, arching
	over the passage on their own. The darkening toward the back comes from
	separate semi-transparent haze cards standing in the passage's open air
	(see buildTunnelHaze), not from the walls' own material, so it reads as
	a real fade into depth rather than a color-graded wall. The invisible
	barrier follows the same notch shape -- flush with the rest of the exit
	wall except across the tunnel's width, where it steps back
	TunnelBarrierInset studs so players can see (not walk) a short way in.

	The barrier is the only thing players can actually collide with here --
	every riser, figure and tunnel part is CanCollide = false, purely visual.

	Deliberately unfinished on purpose: no animation/cheering (that's tied
	to a future legendary-artist spawn event) and no day/night reaction
	(a future phone-flashlight effect at night). Both are just config hooks
	away once that gameplay exists, which is why every knob lives in
	Config.Map.Crowd instead of being hardcoded here.
]]

local Lighting = game:GetService("Lighting")

local Crowd = {}

-- Where the exit (east) wall/crowd sits: right behind the exit stage's own
-- platform, not out at the far ground edge.
local function exitWallX(layout: { [string]: any }): number
	local halfConveyor = layout.ConveyorLength / 2
	return halfConveyor + layout.StageLength + layout.Crowd.ExitWallBuffer
end

-- The tunnel's mouth X, total depth (how many rows it's cut through), and
-- half-width.
local function tunnelGeometry(layout: { [string]: any }): (number, number, number)
	local C = layout.Crowd
	return exitWallX(layout), C.TunnelRows * C.RowDepth, C.TunnelWidth / 2
end

-- The North/NE-chamfer/SE-chamfer/South segments of a row's outline -- the
-- part of the "C" shape that never changes. No segment at all on the west
-- (entrance) end -- that end is open.
local function nonExitSegments(halfX: number, halfZ: number, exitX: number, chamfer: number): { { Vector3 } }
	local nearExitX = exitX - chamfer
	local nearZ = halfZ - chamfer

	return {
		{ Vector3.new(-halfX, 0, halfZ), Vector3.new(nearExitX, 0, halfZ) }, -- North
		{ Vector3.new(nearExitX, 0, halfZ), Vector3.new(exitX, 0, nearZ) }, -- NE chamfer
		{ Vector3.new(exitX, 0, -nearZ), Vector3.new(nearExitX, 0, -halfZ) }, -- SE chamfer
		{ Vector3.new(nearExitX, 0, -halfZ), Vector3.new(-halfX, 0, -halfZ) }, -- South
	}
end

-- The East (exit) wall segment(s) for one row. The bottom TunnelRows rows
-- leave a gap centered on the despawner instead of a solid piece, so the
-- tunnel opening reads as a real hole in the structure; rows above that
-- get the normal single full-width segment, arching over the opening.
local function exitWallSegments(halfZ: number, exitX: number, chamfer: number, row: number, layout: { [string]: any }): { { Vector3 } }
	local C = layout.Crowd
	local nearZ = halfZ - chamfer

	if row < C.TunnelRows then
		local halfTunnel = C.TunnelWidth / 2
		return {
			{ Vector3.new(exitX, 0, nearZ), Vector3.new(exitX, 0, halfTunnel) },
			{ Vector3.new(exitX, 0, -halfTunnel), Vector3.new(exitX, 0, -nearZ) },
		}
	end

	return { { Vector3.new(exitX, 0, nearZ), Vector3.new(exitX, 0, -nearZ) } }
end

-- ----------------------------------------------------------------------------
-- Invisible barrier: no wall at all on the entrance (west) end. On the
-- east end, flush with the exit wall everywhere except a notch across the
-- tunnel's width, recessed TunnelBarrierInset studs into the mouth.
-- ----------------------------------------------------------------------------

local function buildBarrierWall(
	folder: Folder,
	axis: string,
	fixedCoord: number,
	freeMin: number,
	freeMax: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local groundTopY = layout.GroundY - layout.GroundDrop
	local bottomY = groundTopY - C.BarrierEmbed
	local topY = groundTopY + C.BarrierHeight
	local sizeY = topY - bottomY
	local centerY = (bottomY + topY) / 2
	local length = freeMax - freeMin
	local center = (freeMin + freeMax) / 2

	local wall = Instance.new("Part")
	wall.Name = "Barrier"
	wall.Anchored = true
	wall.CanCollide = true
	wall.Transparency = 1
	wall.Material = Enum.Material.SmoothPlastic

	if axis == "X" then
		wall.Size = Vector3.new(length, sizeY, C.BarrierThickness)
		wall.CFrame = CFrame.new(center, centerY, fixedCoord)
	else
		wall.Size = Vector3.new(C.BarrierThickness, sizeY, length)
		wall.CFrame = CFrame.new(fixedCoord, centerY, center)
	end

	wall.Parent = folder
end

local function buildBarrier(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	local barrierFolder = Instance.new("Folder")
	barrierFolder.Name = "Barrier"
	barrierFolder.Parent = folder

	local C = layout.Crowd
	local halfX = totalX / 2
	local halfZ = totalZ / 2
	local exitX, _, halfTunnel = tunnelGeometry(layout)
	local innerX = exitX + C.TunnelBarrierInset
	-- Extend past corners so the walls overlap and never leave a collision gap.
	local corner = C.BarrierThickness * 2

	-- North & South: open at the west (entrance) tip, closed against the exit wall.
	buildBarrierWall(barrierFolder, "X", halfZ, -halfX - corner, exitX + corner, layout)
	buildBarrierWall(barrierFolder, "X", -halfZ, -halfX - corner, exitX + corner, layout)

	-- Exit wall at the mouth, on either side of the tunnel opening.
	buildBarrierWall(barrierFolder, "Z", exitX, -halfZ - corner, -halfTunnel, layout)
	buildBarrierWall(barrierFolder, "Z", exitX, halfTunnel, halfZ + corner, layout)
	-- The notch's own side walls, connecting the mouth plane back to the recessed wall.
	buildBarrierWall(barrierFolder, "X", -halfTunnel, exitX - corner, innerX + corner, layout)
	buildBarrierWall(barrierFolder, "X", halfTunnel, exitX - corner, innerX + corner, layout)
	-- The recessed wall itself, a short way inside the tunnel mouth.
	buildBarrierWall(barrierFolder, "Z", innerX, -halfTunnel - corner, halfTunnel + corner, layout)
	-- No west wall -- the entrance end is deliberately left open.
end

-- ----------------------------------------------------------------------------
-- Risers -- solid ascending steps each row of figures stands on. Built
-- from the same ring outline as the figures, so the riser mass itself
-- follows the same open-west/tight-east shape and corner chamfers.
-- ----------------------------------------------------------------------------

local function buildRiserSegment(folder: Folder, pointA: Vector3, pointB: Vector3, bottomY: number, topY: number, layout: { [string]: any })
	local C = layout.Crowd
	local delta = pointB - pointA
	local length = delta.Magnitude
	if length < 0.01 then
		return
	end
	local tangent = delta / length
	local yaw = math.atan2(-tangent.Z, tangent.X)
	local mid = (pointA + pointB) / 2
	local sizeY = topY - bottomY
	local centerY = (bottomY + topY) / 2

	local riser = Instance.new("Part")
	riser.Name = "Riser"
	riser.Anchored = true
	riser.CanCollide = false
	riser.Material = Enum.Material.SmoothPlastic
	riser.Color = C.RiserColor
	riser.Size = Vector3.new(length, sizeY, C.RowDepth)
	riser.CFrame = CFrame.new(mid.X, centerY, mid.Z) * CFrame.Angles(0, yaw, 0)
	riser.Parent = folder
end

-- Row 0 stands directly on the ground -- no riser needed under it. Every
-- row after that gets a solid step up to its own tread height.
local function buildRisers(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	local risersFolder = Instance.new("Folder")
	risersFolder.Name = "Risers"
	risersFolder.Parent = folder

	local C = layout.Crowd
	local halfX = totalX / 2
	local halfZ = totalZ / 2
	local exitX = exitWallX(layout)
	local groundTopY = layout.GroundY - layout.GroundDrop

	for row = 1, C.RowCount - 1 do
		local reach = row * C.RowDepth + C.RowDepth / 2
		local topY = groundTopY + row * C.RowRise
		local rowHalfX, rowHalfZ, rowExitX = halfX + reach, halfZ + reach, exitX + reach

		for _, seg in ipairs(nonExitSegments(rowHalfX, rowHalfZ, rowExitX, C.CornerChamfer)) do
			buildRiserSegment(risersFolder, seg[1], seg[2], groundTopY, topY, layout)
		end
		for _, seg in ipairs(exitWallSegments(rowHalfZ, rowExitX, C.CornerChamfer, row, layout)) do
			buildRiserSegment(risersFolder, seg[1], seg[2], groundTopY, topY, layout)
		end
	end
end

-- ----------------------------------------------------------------------------
-- Crowd silhouettes -- person-scale, standing on each row's tread. Placed
-- by walking along a segment's length so straight edges and diagonal
-- corner fills use the exact same code (just a different tangent).
-- ----------------------------------------------------------------------------

local function buildFigure(folder: Folder, rng: Random, pos: Vector3, tangent: Vector3, width: number, layout: { [string]: any })
	local C = layout.Crowd
	local height = math.max(1, C.PersonHeight + rng:NextNumber(-C.PersonHeightJitter, C.PersonHeightJitter))
	local torsoHeight = height * (1 - C.HeadHeightFraction)
	local headHeight = height * C.HeadHeightFraction
	local headWidth = width * C.HeadWidthFraction

	local color = C.ColorDark:Lerp(C.ColorLight, rng:NextNumber())
	local jitter = math.rad(rng:NextNumber(-C.MaxYawJitter, C.MaxYawJitter))
	local yaw = math.atan2(-tangent.Z, tangent.X) + jitter

	local base = CFrame.new(pos) * CFrame.Angles(0, yaw, 0)
	local torsoSize = Vector3.new(width, torsoHeight, C.FigureDepth)
	local headSize = Vector3.new(headWidth, headHeight, C.FigureDepth * 0.8)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Anchored = true
	torso.CanCollide = false
	torso.Material = Enum.Material.SmoothPlastic
	torso.Color = color
	torso.Transparency = C.Transparency
	torso.Size = torsoSize
	torso.CFrame = base * CFrame.new(0, torsoHeight / 2, 0)
	torso.Parent = folder

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.CanCollide = false
	head.Material = Enum.Material.SmoothPlastic
	head.Color = color
	head.Transparency = C.Transparency
	head.Size = headSize
	head.CFrame = base * CFrame.new(0, torsoHeight + headHeight / 2, 0)
	head.Parent = folder
end

local function buildFigureSegment(
	folder: Folder,
	rng: Random,
	pointA: Vector3,
	pointB: Vector3,
	standY: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local delta = pointB - pointA
	local length = delta.Magnitude
	if length < 0.01 then
		return
	end
	local tangent = delta / length

	local travelled = 0
	while travelled < length do
		local width = rng:NextNumber(C.FigureMinWidth, C.FigureMaxWidth)
		local center = travelled + width / 2
		-- Check the figure's far edge, not just its center -- otherwise a
		-- figure near the end of a segment can have its body overshoot
		-- past the segment's true endpoint (e.g. into the tunnel's clear
		-- width on the flanking exit-wall segments).
		if center + width / 2 > length then
			break
		end

		local flat = pointA + tangent * center
		buildFigure(folder, rng, Vector3.new(flat.X, standY, flat.Z), tangent, width, layout)

		travelled += width + C.FigureGap
	end
end

local function buildFigures(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	local C = layout.Crowd
	local rng = Random.new(C.Seed)

	local figuresFolder = Instance.new("Folder")
	figuresFolder.Name = "Figures"
	figuresFolder.Parent = folder

	local halfX = totalX / 2
	local halfZ = totalZ / 2
	local exitX = exitWallX(layout)
	local groundTopY = layout.GroundY - layout.GroundDrop

	for row = 0, C.RowCount - 1 do
		local reach = row * C.RowDepth + C.RowDepth / 2
		local standY = groundTopY + row * C.RowRise
		local rowHalfX, rowHalfZ, rowExitX = halfX + reach, halfZ + reach, exitX + reach

		for _, seg in ipairs(nonExitSegments(rowHalfX, rowHalfZ, rowExitX, C.CornerChamfer)) do
			buildFigureSegment(figuresFolder, rng, seg[1], seg[2], standY, layout)
		end
		for _, seg in ipairs(exitWallSegments(rowHalfZ, rowExitX, C.CornerChamfer, row, layout)) do
			buildFigureSegment(figuresFolder, rng, seg[1], seg[2], standY, layout)
		end
	end
end

-- ----------------------------------------------------------------------------
-- Tunnel -- a real recessed passage leading into the crowd structure: a
-- person-scale doorway (side walls + floor, one consistent solid color,
-- no gradient) with nothing built above it -- the ordinary crowd rows
-- arching over past TunnelRows are what's visible there. The darkening
-- comes from separate haze cards standing in the passage's open air, not
-- from the walls' own material, with the despawner sitting inside it.
-- ----------------------------------------------------------------------------

local function buildTunnelStructure(
	folder: Folder,
	exitX: number,
	depth: number,
	halfTunnel: number,
	floorY: number,
	doorHeight: number,
	thickness: number,
	color: Color3
)
	local centerX = exitX + depth / 2

	local function part(name: string, size: Vector3, cframe: CFrame)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = color
		p.Size = size
		p.CFrame = cframe
		p.Parent = folder
	end

	part(
		"LeftWall",
		Vector3.new(depth, doorHeight, thickness),
		CFrame.new(centerX, floorY + doorHeight / 2, -halfTunnel - thickness / 2)
	)
	part(
		"RightWall",
		Vector3.new(depth, doorHeight, thickness),
		CFrame.new(centerX, floorY + doorHeight / 2, halfTunnel + thickness / 2)
	)
	part("Floor", Vector3.new(depth, thickness, halfTunnel * 2), CFrame.new(centerX, floorY - thickness / 2, 0))
end

-- A shallow arched roof: a row of ribs, each spanning the passage's full
-- depth like the walls do, tallest at the center and tapering down (via a
-- parabolic profile) to meet the wall tops at the edges -- a gentle curve
-- approximated by a handful of flat segments, not a single flat slab.
local function buildTunnelRoof(
	folder: Folder,
	exitX: number,
	depth: number,
	halfTunnel: number,
	floorY: number,
	doorHeight: number,
	thickness: number,
	color: Color3,
	archRise: number,
	segments: number
)
	local centerX = exitX + depth / 2
	local halfSpan = halfTunnel + thickness
	local sliceWidth = (halfSpan * 2) / segments
	local minRibHeight = thickness * 0.5

	for i = 0, segments - 1 do
		local z = -halfSpan + (i + 0.5) * sliceWidth
		local u = z / halfSpan
		local ribHeight = math.max(minRibHeight, archRise * (1 - u * u))

		local rib = Instance.new("Part")
		rib.Name = "Roof"
		rib.Anchored = true
		rib.CanCollide = false
		rib.Material = Enum.Material.SmoothPlastic
		rib.Color = color
		rib.Size = Vector3.new(depth, ribHeight, sliceWidth)
		rib.CFrame = CFrame.new(centerX, floorY + doorHeight + ribHeight / 2, z)
		rib.Parent = folder
	end
end

-- A handful of thin, increasingly opaque cards standing across the
-- passage's clear cross-section -- looking down the tunnel, the view
-- passes through several of these in a row, compounding into a genuine
-- fade toward darkness instead of a single flat-colored surface.
local function buildTunnelHaze(
	folder: Folder,
	exitX: number,
	depth: number,
	halfTunnel: number,
	floorY: number,
	doorHeight: number,
	archRise: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local steps = math.max(1, C.TunnelHazeSteps)
	local cardHeight = doorHeight + archRise -- tall enough to cover the arch's peak too

	local hazeFolder = Instance.new("Folder")
	hazeFolder.Name = "Haze"
	hazeFolder.Parent = folder

	for i = 1, steps do
		local t = steps > 1 and (i - 1) / (steps - 1) or 1
		local x = exitX + (i / (steps + 1)) * depth

		local card = Instance.new("Part")
		card.Name = "HazeCard"
		card.Anchored = true
		card.CanCollide = false
		card.Material = Enum.Material.SmoothPlastic
		card.Color = C.TunnelColor
		card.Transparency = C.TunnelHazeNearTransparency
			+ (C.TunnelHazeFarTransparency - C.TunnelHazeNearTransparency) * t
		card.Size = Vector3.new(0.2, cardHeight, halfTunnel * 2)
		card.CFrame = CFrame.new(x, floorY + cardHeight / 2, 0)
		card.Parent = hazeFolder
	end
end

local function buildTunnel(folder: Folder, layout: { [string]: any })
	local C = layout.Crowd
	if C.TunnelRows <= 0 then
		return
	end

	local tunnelFolder = Instance.new("Folder")
	tunnelFolder.Name = "Tunnel"
	tunnelFolder.Parent = folder

	local exitX, depth, halfTunnel = tunnelGeometry(layout)
	local floorY = layout.GroundY
	local thickness = C.TunnelWallThickness
	local doorHeight = C.TunnelHeight

	buildTunnelStructure(tunnelFolder, exitX, depth, halfTunnel, floorY, doorHeight, thickness, C.TunnelWallColor)
	buildTunnelRoof(
		tunnelFolder,
		exitX,
		depth,
		halfTunnel,
		floorY,
		doorHeight,
		thickness,
		C.TunnelWallColor,
		C.TunnelArchRise,
		C.TunnelArchSegments
	)
	buildTunnelHaze(tunnelFolder, exitX, depth, halfTunnel, floorY, doorHeight, C.TunnelArchRise, layout)

	-- Dark cap at the very back of the doorway, tall enough to reach the
	-- arch's peak too, so the passage reads as ending in darkness rather
	-- than showing through to whatever's beyond it.
	local capHeight = doorHeight + C.TunnelArchRise
	local cap = Instance.new("Part")
	cap.Name = "Backdrop"
	cap.Anchored = true
	cap.CanCollide = false
	cap.Material = Enum.Material.SmoothPlastic
	cap.Color = C.TunnelColor
	cap.Size = Vector3.new(thickness, capHeight, halfTunnel * 2)
	cap.CFrame = CFrame.new(exitX + depth, floorY + capHeight / 2, 0)
	cap.Parent = tunnelFolder

	-- The despawner itself, sized to fit the doorway and sitting inside
	-- the passage (a bit back from the mouth) rather than out on the open
	-- field.
	local squareSize = C.TunnelDespawnerSize
	local despawner = Instance.new("Part")
	despawner.Name = "SpawnerSquare"
	despawner.Anchored = true
	despawner.CanCollide = false
	despawner.Material = Enum.Material.Neon
	despawner.Color = layout.SlotMarkerColor
	despawner.Size = Vector3.new(squareSize, 0.2, squareSize)
	despawner.CFrame = CFrame.new(exitX + C.TunnelDespawnerInset, floorY + 0.1, 0)
	despawner.Parent = tunnelFolder
end

-- ----------------------------------------------------------------------------
-- Atmosphere -- a light global haze, not a per-crowd effect. Just a cheap
-- way to soften the whole scene's focus without a real blur shader.
-- ----------------------------------------------------------------------------

local function applyAtmosphere(layout: { [string]: any })
	local C = layout.Crowd
	if not C.EnableAtmosphere then
		return
	end

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end

	atmosphere.Color = C.AtmosphereColor
	atmosphere.Decay = C.AtmosphereDecay
	atmosphere.Density = C.AtmosphereDensity
	atmosphere.Haze = C.AtmosphereHaze
	atmosphere.Glare = C.AtmosphereGlare
end

-- totalX/totalZ are the ground plane's full footprint -- the barrier and
-- risers/crowd follow the "C" shape described above.
function Crowd.build(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	buildBarrier(folder, layout, totalX, totalZ)
	buildRisers(folder, layout, totalX, totalZ)
	buildFigures(folder, layout, totalX, totalZ)
	buildTunnel(folder, layout)
	applyAtmosphere(layout)
end

return Crowd
