--!strict
--[[
	WorldBuilder.luau
	-----------------
	Procedurally builds the static blocky world (the "Grow a Garden" baseplate
	vibe) entirely from code, and exposes the tile geometry math the rest of
	the game uses to place plots, characters and buildings on a clean grid.

	Because everything is generated at runtime, the whole game lives in code and
	syncs cleanly through Rojo -- there is no binary place file to hand-edit.
]]

local Workspace = game:GetService("Workspace")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)

local WorldBuilder = {}

local W = Config.World
local TILES_PER_SIDE = W.PlotTilesPerSide
local TILE = W.TileSize

-- Folder that holds everything we generate, kept tidy under Workspace.
local worldFolder: Folder

local function ensureFolder(): Folder
	if not worldFolder or not worldFolder.Parent then
		worldFolder = Instance.new("Folder")
		worldFolder.Name = "AnimeWorld"
		worldFolder.Parent = Workspace
	end
	return worldFolder
end

local function makeBlock(size: Vector3, cframe: CFrame, color: Color3, parent: Instance, name: string?): Part
	local part = Instance.new("Part")
	part.Name = name or "Block"
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

WorldBuilder.makeBlock = makeBlock

-- ----------------------------------------------------------------------------
-- TILE GEOMETRY
-- ----------------------------------------------------------------------------

-- Local offset (relative to a plot's origin) of the centre of a tile.
-- Tiles are laid out as a TILES_PER_SIDE x TILES_PER_SIDE grid, centred on
-- the plot origin so expansion grows outward symmetrically.
function WorldBuilder.tileLocalOffset(tileIndex: number): Vector3
	local row = math.floor(tileIndex / TILES_PER_SIDE)
	local col = tileIndex % TILES_PER_SIDE
	local half = (TILES_PER_SIDE - 1) / 2
	local x = (col - half) * TILE
	local z = (row - half) * TILE
	return Vector3.new(x, 0, z)
end

-- The order tiles unlock in as the player expands: from the centre outward,
-- so a growing plot always looks like a tidy expanding square.
local unlockOrder: { number }? = nil
function WorldBuilder.getUnlockOrder(): { number }
	if unlockOrder then
		return unlockOrder
	end
	local order = {}
	for i = 0, (TILES_PER_SIDE * TILES_PER_SIDE) - 1 do
		table.insert(order, i)
	end
	local half = (TILES_PER_SIDE - 1) / 2
	table.sort(order, function(a, b)
		local oa = WorldBuilder.tileLocalOffset(a)
		local ob = WorldBuilder.tileLocalOffset(b)
		local da = oa.X * oa.X + oa.Z * oa.Z
		local db = ob.X * ob.X + ob.Z * ob.Z
		if da == db then
			return a < b
		end
		return da < db
	end)
	unlockOrder = order
	return order
end

-- Returns the tile index that occupies the Nth unlock slot (0-based).
function WorldBuilder.tileForSlot(slot: number): number
	local order = WorldBuilder.getUnlockOrder()
	return order[slot + 1] or order[#order]
end

-- World-space position of a plot origin given its plot index in the big grid.
function WorldBuilder.plotOrigin(plotIndex: number): Vector3
	local row = math.floor(plotIndex / W.PlotsPerRow)
	local col = plotIndex % W.PlotsPerRow
	return Vector3.new(col * W.PlotSpacing, 0, row * W.PlotSpacing)
end

-- ----------------------------------------------------------------------------
-- STATIC WORLD
-- ----------------------------------------------------------------------------

-- A large flat baseplate plus a soft skybox-ish backdrop. Plots are placed on
-- top of this by PlotService.
function WorldBuilder.buildBaseplate(maxPlots: number)
	local folder = ensureFolder()

	-- Compute how big the baseplate needs to be to fit all plots.
	local rows = math.ceil(maxPlots / W.PlotsPerRow)
	local width = (W.PlotsPerRow + 1) * W.PlotSpacing
	local depth = (rows + 1) * W.PlotSpacing

	local centre = Vector3.new(
		(W.PlotsPerRow - 1) * W.PlotSpacing / 2,
		-1,
		(rows - 1) * W.PlotSpacing / 2
	)

	makeBlock(
		Vector3.new(width, 2, depth),
		CFrame.new(centre),
		W.BaseplateColor,
		folder,
		"Baseplate"
	)

	-- A thin decorative border so the world has an edge, not an abyss.
	local border = Instance.new("Folder")
	border.Name = "Border"
	border.Parent = folder

	return folder
end

function WorldBuilder.getWorldFolder(): Folder
	return ensureFolder()
end

return WorldBuilder
