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

	Each row's outline is 4 straight edges with a diagonal chamfer at every
	corner (instead of the edges meeting at a hard right angle), so risers
	and figures both wrap smoothly around the map instead of looking like 4
	separate walls butted together.

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

-- ----------------------------------------------------------------------------
-- Ring geometry: each row's outline as 8 segments (N/E/S/W straights, each
-- trimmed back by CornerChamfer, plus a diagonal fill at each corner).
-- Points are Vector3 with Y left at 0 -- callers supply the row's height.
-- ----------------------------------------------------------------------------

local function ringSegments(halfX: number, halfZ: number, chamfer: number): { { Vector3 } }
	local nearX, nearZ = halfX - chamfer, halfZ - chamfer

	return {
		-- Straight edges.
		{ Vector3.new(-nearX, 0, halfZ), Vector3.new(nearX, 0, halfZ) }, -- North
		{ Vector3.new(nearX, 0, -halfZ), Vector3.new(-nearX, 0, -halfZ) }, -- South
		{ Vector3.new(halfX, 0, -nearZ), Vector3.new(halfX, 0, nearZ) }, -- East
		{ Vector3.new(-halfX, 0, nearZ), Vector3.new(-halfX, 0, -nearZ) }, -- West
		-- Diagonal corner fills, each connecting the ends of the two
		-- straights that would otherwise meet at a hard right angle.
		{ Vector3.new(nearX, 0, halfZ), Vector3.new(halfX, 0, nearZ) }, -- NE
		{ Vector3.new(-nearX, 0, halfZ), Vector3.new(-halfX, 0, nearZ) }, -- NW
		{ Vector3.new(-nearX, 0, -halfZ), Vector3.new(-halfX, 0, -nearZ) }, -- SW
		{ Vector3.new(nearX, 0, -halfZ), Vector3.new(halfX, 0, -nearZ) }, -- SE
	}
end

-- ----------------------------------------------------------------------------
-- Invisible barrier (unchanged square corners -- it's invisible, so the
-- hard corner has no visual impact, and the overlap already guarantees no
-- collision gap).
-- ----------------------------------------------------------------------------

local function buildBarrierWall(
	folder: Folder,
	axis: string,
	fixedCoord: number,
	length: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local groundTopY = layout.GroundY - layout.GroundDrop
	local bottomY = groundTopY - C.BarrierEmbed
	local topY = groundTopY + C.BarrierHeight
	local sizeY = topY - bottomY
	local centerY = (bottomY + topY) / 2

	local wall = Instance.new("Part")
	wall.Name = "Barrier"
	wall.Anchored = true
	wall.CanCollide = true
	wall.Transparency = 1
	wall.Material = Enum.Material.SmoothPlastic

	if axis == "X" then
		wall.Size = Vector3.new(length, sizeY, C.BarrierThickness)
		wall.CFrame = CFrame.new(0, centerY, fixedCoord)
	else
		wall.Size = Vector3.new(C.BarrierThickness, sizeY, length)
		wall.CFrame = CFrame.new(fixedCoord, centerY, 0)
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
	-- Extend each wall past its corners so the four walls overlap and never
	-- leave a gap a player could slip through.
	local corner = C.BarrierThickness * 2

	buildBarrierWall(barrierFolder, "X", halfZ, totalX + corner * 2, layout)
	buildBarrierWall(barrierFolder, "X", -halfZ, totalX + corner * 2, layout)
	buildBarrierWall(barrierFolder, "Z", halfX, totalZ + corner * 2, layout)
	buildBarrierWall(barrierFolder, "Z", -halfX, totalZ + corner * 2, layout)
end

-- ----------------------------------------------------------------------------
-- Risers -- solid ascending steps each row of figures stands on. Built
-- from the same 8-segment ring outline as the figures, so the riser mass
-- itself is chamfered at the corners too.
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
	local groundTopY = layout.GroundY - layout.GroundDrop

	for row = 1, C.RowCount - 1 do
		local reach = row * C.RowDepth + C.RowDepth / 2
		local topY = groundTopY + row * C.RowRise

		for _, seg in ipairs(ringSegments(halfX + reach, halfZ + reach, C.CornerChamfer)) do
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
	local groundTopY = layout.GroundY - layout.GroundDrop

	for row = 0, C.RowCount - 1 do
		local reach = row * C.RowDepth + C.RowDepth / 2
		local standY = groundTopY + row * C.RowRise

		for _, seg in ipairs(ringSegments(halfX + reach, halfZ + reach, C.CornerChamfer)) do
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

-- totalX/totalZ are the ground plane's full footprint -- the barrier sits
-- right on its edge, and the risers/crowd climb upward just beyond that.
function Crowd.build(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	buildBarrier(folder, layout, totalX, totalZ)
	buildRisers(folder, layout, totalX, totalZ)
	buildFigures(folder, layout, totalX, totalZ)
	applyAtmosphere(layout)
end

return Crowd
