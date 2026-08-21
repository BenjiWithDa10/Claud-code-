--!strict
--[[
	Crowd.luau
	----------
	Rings the outside of the ground with a stylized, static crowd: an
	invisible collision barrier sits right at the map's edge, and just
	beyond it, tiered rows of simple dark silhouettes step outward and rise
	higher -- the lower tiers of a packed stadium, not a flat wall.

	The barrier is the only thing players can actually collide with here --
	every figure is CanCollide = false, purely visual.

	Deliberately unfinished on purpose: no animation/cheering (that's tied
	to a future legendary-artist spawn event) and no day/night reaction
	(a future phone-flashlight effect at night). Both are just config hooks
	away once that gameplay exists, which is why every knob lives in
	Config.Map.Crowd instead of being hardcoded here.
]]

local Lighting = game:GetService("Lighting")

local Crowd = {}

-- ----------------------------------------------------------------------------
-- Invisible barrier
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
-- Crowd silhouettes
-- ----------------------------------------------------------------------------

local function buildFigure(
	folder: Folder,
	rng: Random,
	axis: string,
	fixedCoord: number,
	pos: number,
	width: number,
	height: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local baseY = layout.GroundY - layout.GroundDrop

	local torsoHeight = height * (1 - C.HeadHeightFraction)
	local headHeight = height * C.HeadHeightFraction
	local headWidth = width * C.HeadWidthFraction

	local color = C.ColorDark:Lerp(C.ColorLight, rng:NextNumber())
	local yaw = math.rad(rng:NextNumber(-C.MaxYawJitter, C.MaxYawJitter))

	local base
	local torsoSize, headSize
	if axis == "X" then
		base = CFrame.new(pos, baseY, fixedCoord) * CFrame.Angles(0, yaw, 0)
		torsoSize = Vector3.new(width, torsoHeight, C.FigureDepth)
		headSize = Vector3.new(headWidth, headHeight, C.FigureDepth * 0.8)
	else
		base = CFrame.new(fixedCoord, baseY, pos) * CFrame.Angles(0, yaw, 0)
		torsoSize = Vector3.new(C.FigureDepth, torsoHeight, width)
		headSize = Vector3.new(C.FigureDepth * 0.8, headHeight, headWidth)
	end

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

local function buildRow(
	folder: Folder,
	rng: Random,
	axis: string,
	fixedCoord: number,
	rangeMin: number,
	rangeMax: number,
	rowHeight: number,
	layout: { [string]: any }
)
	local C = layout.Crowd
	local pos = rangeMin

	while pos < rangeMax do
		local width = rng:NextNumber(C.FigureMinWidth, C.FigureMaxWidth)
		local height = math.max(1, rowHeight + rng:NextNumber(-2, 2))
		local center = pos + width / 2

		buildFigure(folder, rng, axis, fixedCoord, center, width, height, layout)

		pos += width + C.FigureGap
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
	local corner = C.FigureMaxWidth * 3 -- extend past corners so rows overlap and cover them

	for row = 0, C.RowCount - 1 do
		local outward = row * C.RowDepth
		local rowHeight = C.BaseHeight + row * C.RowRise

		buildRow(figuresFolder, rng, "X", halfZ + outward, -halfX - corner, halfX + corner, rowHeight, layout)
		buildRow(figuresFolder, rng, "X", -halfZ - outward, -halfX - corner, halfX + corner, rowHeight, layout)
		buildRow(figuresFolder, rng, "Z", halfX + outward, -halfZ - corner, halfZ + corner, rowHeight, layout)
		buildRow(figuresFolder, rng, "Z", -halfX - outward, -halfZ - corner, halfZ + corner, rowHeight, layout)
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
-- right on its edge, and the crowd rises up just beyond that.
function Crowd.build(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	buildBarrier(folder, layout, totalX, totalZ)
	buildFigures(folder, layout, totalX, totalZ)
	applyAtmosphere(layout)
end

return Crowd
