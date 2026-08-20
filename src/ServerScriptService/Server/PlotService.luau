--!strict
--[[
	PlotService.luau
	----------------
	Assigns each player a plot in the world grid, builds the blocky ground tiles
	for the tiles they have unlocked, and handles plot expansion (buying the
	next tile, with the price scaling up the more you own -- exactly the
	"goes up in price the more plots you have" mechanic).

	It also tracks tile occupancy so CharacterService / BuildingService can find
	a free tile to drop something on.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerDataService = require(script.Parent.PlayerDataService)

local PlotService = {}

local W = Config.World
local TILE = W.TileSize

type PlotRecord = {
	plotIndex: number,
	origin: Vector3,
	folder: Folder,
	groundFolder: Folder,
	contentFolder: Folder, -- characters + buildings live here
	tileParts: { [number]: Part }, -- tileIndex -> ground part
}

local plots: { [Player]: PlotRecord } = {}
local usedPlotIndices: { [number]: boolean } = {}

local MAX_PLOTS = W.PlotsPerRow * W.PlotsPerRow -- square arena

local function allocatePlotIndex(): number
	for i = 0, MAX_PLOTS - 1 do
		if not usedPlotIndices[i] then
			usedPlotIndices[i] = true
			return i
		end
	end
	-- Fallback: overflow players share the last plot (should not happen in
	-- normal server sizes, but never error out).
	return MAX_PLOTS - 1
end

PlotService.MAX_PLOTS = MAX_PLOTS

-- Build (or rebuild) the visible ground tiles for the player's unlocked count.
local function renderGround(record: PlotRecord, tilesUnlocked: number)
	-- Clear existing.
	record.groundFolder:ClearAllChildren()
	record.tileParts = {}

	for slot = 0, tilesUnlocked - 1 do
		local tileIndex = WorldBuilder.tileForSlot(slot)
		local offset = WorldBuilder.tileLocalOffset(tileIndex)
		local color = W.GroundColors[(tileIndex % #W.GroundColors) + 1]
		local part = WorldBuilder.makeBlock(
			Vector3.new(TILE, 1.5, TILE),
			CFrame.new(record.origin + offset + Vector3.new(0, 0.75, 0)),
			color,
			record.groundFolder,
			"Tile_" .. tileIndex
		)
		part:SetAttribute("TileIndex", tileIndex)
		record.tileParts[tileIndex] = part
	end
end

function PlotService.assign(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end

	local plotIndex = allocatePlotIndex()
	local origin = WorldBuilder.plotOrigin(plotIndex)

	local folder = Instance.new("Folder")
	folder.Name = "Plot_" .. player.UserId
	folder:SetAttribute("OwnerUserId", player.UserId)
	folder.Parent = WorldBuilder.getWorldFolder()

	local groundFolder = Instance.new("Folder")
	groundFolder.Name = "Ground"
	groundFolder.Parent = folder

	local contentFolder = Instance.new("Folder")
	contentFolder.Name = "Content"
	contentFolder.Parent = folder

	local record: PlotRecord = {
		plotIndex = plotIndex,
		origin = origin,
		folder = folder,
		groundFolder = groundFolder,
		contentFolder = contentFolder,
		tileParts = {},
	}
	plots[player] = record

	renderGround(record, profile.tiles)

	-- A nameplate floating over the plot so players can find each other.
	local sign = WorldBuilder.makeBlock(
		Vector3.new(TILE, 0.4, TILE),
		CFrame.new(origin + Vector3.new(0, 8, 0)),
		Color3.fromRGB(40, 40, 50),
		folder,
		"Sign"
	)
	sign.Transparency = 1
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(8, 2)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = player.DisplayName .. "'s Anime World"
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard

	-- A welcome sign floating right above the spawn point.
	local welcomeSign = WorldBuilder.makeBlock(
		Vector3.new(TILE, 0.4, TILE),
		CFrame.new(origin + Vector3.new(0, 11, 0)),
		Color3.fromRGB(40, 40, 50),
		folder,
		"WelcomeSign"
	)
	welcomeSign.Transparency = 1
	local welcomeBillboard = Instance.new("BillboardGui")
	welcomeBillboard.Size = UDim2.fromScale(8, 2)
	welcomeBillboard.StudsOffset = Vector3.new(0, 2, 0)
	welcomeBillboard.AlwaysOnTop = true
	welcomeBillboard.Parent = welcomeSign
	local welcomeLabel = Instance.new("TextLabel")
	welcomeLabel.Size = UDim2.fromScale(1, 1)
	welcomeLabel.BackgroundTransparency = 1
	welcomeLabel.Text = "Hello Benji"
	welcomeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	welcomeLabel.TextStrokeTransparency = 0.4
	welcomeLabel.TextScaled = true
	welcomeLabel.Font = Enum.Font.GothamBold
	welcomeLabel.Parent = welcomeBillboard

	return record
end

function PlotService.getRecord(player: Player): PlotRecord?
	return plots[player]
end

-- World-space CFrame for a given tile index on the player's plot.
function PlotService.tileCFrame(player: Player, tileIndex: number): CFrame?
	local record = plots[player]
	if not record then
		return nil
	end
	local offset = WorldBuilder.tileLocalOffset(tileIndex)
	return CFrame.new(record.origin + offset + Vector3.new(0, 1.5, 0))
end

-- The spawn location for a player (centre tile, a little above ground).
function PlotService.spawnCFrame(player: Player): CFrame?
	local record = plots[player]
	if not record then
		return nil
	end
	return CFrame.new(record.origin + Vector3.new(0, 5, 0))
end

-- Which tiles are currently unlocked (by tile index)?
function PlotService.unlockedTiles(player: Player): { number }
	local profile = PlayerDataService.get(player)
	if not profile then
		return {}
	end
	local result = {}
	for slot = 0, profile.tiles - 1 do
		table.insert(result, WorldBuilder.tileForSlot(slot))
	end
	return result
end

-- Find an unlocked tile that has nothing placed on it. Returns nil if full.
function PlotService.firstFreeTile(player: Player): number?
	local profile = PlayerDataService.get(player)
	if not profile then
		return nil
	end

	local occupied: { [number]: boolean } = {}
	for _, c in profile.characters do
		occupied[c.tile] = true
	end
	for _, b in profile.buildings do
		occupied[b.tile] = true
	end

	for slot = 0, profile.tiles - 1 do
		local tileIndex = WorldBuilder.tileForSlot(slot)
		if not occupied[tileIndex] then
			return tileIndex
		end
	end
	return nil
end

-- Attempt to buy the next plot tile. Returns ok, message.
function PlotService.buyTile(player: Player): (boolean, string)
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	if profile.tiles >= Config.Plot.MaxTiles then
		return false, "Your plot is already at maximum size!"
	end

	local cost = Util.nextTileCost(profile.tiles)
	if profile.money < cost then
		return false, ("Need %s coins to expand."):format(Util.formatNumber(cost))
	end

	profile.money -= cost
	profile.tiles += 1

	local record = plots[player]
	if record then
		renderGround(record, profile.tiles)
	end

	PlayerDataService.markDirty(player)
	return true, ("Plot expanded! Next tile costs %s."):format(
		Util.formatNumber(Util.nextTileCost(profile.tiles))
	)
end

function PlotService.release(player: Player)
	local record = plots[player]
	if record then
		usedPlotIndices[record.plotIndex] = nil
		record.folder:Destroy()
	end
	plots[player] = nil
end

return PlotService
