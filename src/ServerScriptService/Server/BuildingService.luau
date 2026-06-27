--!strict
--[[
	BuildingService.luau
	--------------------
	Handles the "power buildings" the user described. Each building is a blocky
	structure you place on a tile. It is mostly a delivery mechanism for an
	invisible enchant: every building feeds Power into one genre (action,
	fantasy, slice-of-life, ...). The genre with the most Power becomes the
	dominant flavor of your world's auto-generated story.

	Buildings also add raw Appeal, and each additional copy of the same building
	costs more (a gentle money sink that keeps the world growing).
]]

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Types = require(Shared.Types)

local WorldBuilder = require(script.Parent.WorldBuilder)
local PlotService = require(script.Parent.PlotService)
local PlayerDataService = require(script.Parent.PlayerDataService)

type Building = Types.Building

local BuildingService = {}

-- Build a small blocky structure flavored by the building's genre color.
local function buildModel(def, building: Building): Model
	local model = Instance.new("Model")
	model.Name = "Bld_" .. building.id

	-- Base
	local base = WorldBuilder.makeBlock(
		Vector3.new(5, 1, 5),
		CFrame.new(0, 0.5, 0),
		Color3.fromRGB(120, 110, 100),
		model,
		"Base"
	)
	-- Walls
	WorldBuilder.makeBlock(
		Vector3.new(4.4, 3.5, 4.4),
		CFrame.new(0, 2.75, 0),
		def.color,
		model,
		"Walls"
	)
	-- Roof (slightly bigger, darker shade of the genre color)
	local roofColor = def.color:Lerp(Color3.new(0, 0, 0), 0.3)
	WorldBuilder.makeBlock(
		Vector3.new(5.2, 1.2, 5.2),
		CFrame.new(0, 5.1, 0),
		roofColor,
		model,
		"Roof"
	)
	-- A glowing genre orb on top -- the visible hint of the invisible enchant.
	local powerDef = Util.getPowerDef(def.power)
	local orb = WorldBuilder.makeBlock(
		Vector3.new(1.2, 1.2, 1.2),
		CFrame.new(0, 6.4, 0),
		powerDef and powerDef.color or def.color,
		model,
		"PowerOrb"
	)
	orb.Material = Enum.Material.Neon
	orb.Shape = Enum.PartType.Ball

	model.PrimaryPart = base

	-- Name tag.
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(5, 1)
	billboard.StudsOffset = Vector3.new(0, 4.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = base
	billboard.Parent = base
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = def.name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.Parent = billboard

	return model
end

local function placeModel(player: Player, building: Building)
	local def = Util.getBuildingDef(building.kind)
	if not def then
		return
	end
	local record = PlotService.getRecord(player)
	if not record then
		return
	end
	local existing = record.contentFolder:FindFirstChild("Bld_" .. building.id)
	if existing then
		existing:Destroy()
	end

	local cframe = PlotService.tileCFrame(player, building.tile)
	if not cframe then
		return
	end

	local model = buildModel(def, building)
	model.Parent = record.contentFolder
	model:PivotTo(cframe)
end

BuildingService.placeModel = placeModel

function BuildingService.renderAll(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	for _, b in profile.buildings do
		placeModel(player, b)
	end
end

-- How many of a given building kind the player already owns.
local function countOfKind(profile: Types.Profile, kind: string): number
	local n = 0
	for _, b in profile.buildings do
		if b.kind == kind then
			n += 1
		end
	end
	return n
end

-- Place (buy) a building of the given kind. Returns ok, message.
function BuildingService.place(player: Player, kind: string): (boolean, string)
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	local def = Util.getBuildingDef(kind)
	if not def then
		return false, "Unknown building."
	end

	local owned = countOfKind(profile, kind)
	local cost = Util.buildingCost(def.cost, owned)
	if profile.money < cost then
		return false, ("Need %s coins for that building."):format(Util.formatNumber(cost))
	end

	local tile = PlotService.firstFreeTile(player)
	if not tile then
		return false, "No free space -- expand your plot first!"
	end

	profile.money -= cost

	local building: Building = {
		id = Util.newId("bld"),
		kind = kind,
		tile = tile,
	}
	table.insert(profile.buildings, building)

	placeModel(player, building)
	PlayerDataService.markDirty(player)

	return true, ("Built a %s! (+%d %s power)"):format(def.name, def.powerAmount, def.power)
end

return BuildingService
