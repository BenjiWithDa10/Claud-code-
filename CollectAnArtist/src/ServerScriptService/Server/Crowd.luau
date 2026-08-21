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

	The barrier is the only thing players can actually collide with here --
	every riser and figure is CanCollide = false, purely visual.

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

-- A row's outline as a "C" shape open at the west (entrance) end: a North
-- wall, a chamfered NE corner, the East (exit) wall, a chamfered SE corner,
-- and a South wall. No segment at all on the west -- that end is open.
local function rowSegments(halfX: number, halfZ: number, exitX: number, chamfer: number): { { Vector3 } }
	local nearExitX = exitX - chamfer
	local nearZ = halfZ - chamfer

	return {
		{ Vector3.new(-halfX, 0, halfZ), Vector3.new(nearExitX, 0, halfZ) }, -- North
		{ Vector3.new(nearExitX, 0, halfZ), Vector3.new(exitX, 0, nearZ) }, -- NE chamfer
		{ Vector3.new(exitX, 0, nearZ), Vector3.new(exitX, 0, -nearZ) }, -- Exit wall
		{ Vector3.new(exitX, 0, -nearZ), Vector3.new(nearExitX, 0, -halfZ) }, -- SE chamfer
		{ Vector3.new(nearExitX, 0, -halfZ), Vector3.new(-halfX, 0, -halfZ) }, -- South
	}
end

-- ----------------------------------------------------------------------------
-- Invisible barrier: no wall at all on the entrance (west) end, closed
-- tight behind the exit stage's despawner on the east end.
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
	local exitX = exitWallX(layout)
	-- Extend past corners so the walls overlap and never leave a collision gap.
	local corner = C.BarrierThickness * 2

	-- North & South: open at the west (entrance) tip, closed against the exit wall.
	buildBarrierWall(barrierFolder, "X", halfZ, -halfX - corner, exitX + corner, layout)
	buildBarrierWall(barrierFolder, "X", -halfZ, -halfX - corner, exitX + corner, layout)
	-- Exit wall, right behind the despawner.
	buildBarrierWall(barrierFolder, "Z", exitX, -halfZ - corner, halfZ + corner, layout)
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

		for _, seg in ipairs(rowSegments(halfX + reach, halfZ + reach, exitX + reach, C.CornerChamfer)) do
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
		if center > length then
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

		for _, seg in ipairs(rowSegments(halfX + reach, halfZ + reach, exitX + reach, C.CornerChamfer)) do
			buildFigureSegment(figuresFolder, rng, seg[1], seg[2], standY, layout)
		end
	end
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
	applyAtmosphere(layout)
end

return Crowd
