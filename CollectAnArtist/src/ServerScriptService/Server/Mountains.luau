--!strict
--[[
	Mountains.luau
	--------------
	Rings the outside of the ground with a wall of blocky, low-poly
	"mountains" so the map reads as having a natural edge instead of just
	stopping in open space (or relying on an obvious invisible wall).

	Each mountain is one chunky, slightly-rotated block of random width and
	height; consecutive blocks along an edge overlap a little so there are
	no gaps or seams, and every block is buried well below GroundY so there
	is never a floating gap at its base.
]]

local Mountains = {}

local function placeRow(
	folder: Folder,
	rng: Random,
	axis: string,
	fixedCoord: number,
	rangeMin: number,
	rangeMax: number,
	layout: { [string]: any }
)
	local M = layout.Mountains
	local groundTopY = layout.GroundY - layout.GroundDrop

	local pos = rangeMin
	while pos < rangeMax do
		local width = rng:NextNumber(M.MinWidth, M.MaxWidth)
		local height = rng:NextNumber(M.MinHeight, M.MaxHeight)
		local center = pos + width / 2

		local bottomY = groundTopY - M.BaseEmbed
		local topY = groundTopY + height
		local sizeY = topY - bottomY
		local centerY = (bottomY + topY) / 2

		local part = Instance.new("Part")
		part.Name = "Mountain"
		part.Anchored = true
		part.Material = Enum.Material.Rock
		part.Color = (height > M.SnowHeight) and M.SnowColor or M.Color

		local rotation = CFrame.Angles(0, math.rad(rng:NextNumber(-6, 6)), 0)

		if axis == "X" then
			part.Size = Vector3.new(width, sizeY, M.Depth)
			part.CFrame = CFrame.new(center, centerY, fixedCoord) * rotation
		else
			part.Size = Vector3.new(M.Depth, sizeY, width)
			part.CFrame = CFrame.new(fixedCoord, centerY, center) * rotation
		end

		part.Parent = folder

		pos += width * M.OverlapFactor
	end
end

-- totalX/totalZ are the ground plane's full footprint -- the mountain ring
-- sits just outside it on all four sides.
function Mountains.build(folder: Folder, layout: { [string]: any }, totalX: number, totalZ: number)
	local M = layout.Mountains
	local rng = Random.new(M.Seed)

	local halfX = totalX / 2
	local halfZ = totalZ / 2
	local corner = M.MaxWidth -- extend rows past the corners so they overlap and cover them

	-- North / south walls run along X, just beyond the ground's Z edges.
	placeRow(folder, rng, "X", halfZ + M.Depth / 2, -halfX - corner, halfX + corner, layout)
	placeRow(folder, rng, "X", -halfZ - M.Depth / 2, -halfX - corner, halfX + corner, layout)

	-- East / west walls run along Z, just beyond the ground's X edges.
	placeRow(folder, rng, "Z", halfX + M.Depth / 2, -halfZ - corner, halfZ + corner, layout)
	placeRow(folder, rng, "Z", -halfX - M.Depth / 2, -halfZ - corner, halfZ + corner, layout)
end

return Mountains
