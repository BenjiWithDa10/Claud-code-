--!strict
--[[
	CharacterService.luau
	---------------------
	Handles the small customizable "anime" characters that live on the player's
	plot. Each one is a little blocky figure built from parts (head, hair, body,
	legs) so it matches the voxel aesthetic. Players recruit them (cost scales
	with roster size), recolor their hair/outfit, and rename them. Each
	character contributes Appeal and pushes the world's Power toward the genre
	its archetype favors.
]]

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Types = require(Shared.Types)

local WorldBuilder = require(script.Parent.WorldBuilder)
local PlotService = require(script.Parent.PlotService)
local PlayerDataService = require(script.Parent.PlayerDataService)

type Character = Types.Character

local CharacterService = {}

-- Build a tiny blocky humanoid-ish figure and return the model.
local function buildModel(char: Character): Model
	local model = Instance.new("Model")
	model.Name = "Char_" .. char.id

	local hairColor = Config.Characters.HairColors[char.hairColor]
		or Config.Characters.HairColors[1]
	local outfitColor = Config.Characters.OutfitColors[char.outfitColor]
		or Config.Characters.OutfitColors[1]
	local skin = Color3.fromRGB(255, 224, 196)

	-- Legs
	local legs = WorldBuilder.makeBlock(
		Vector3.new(1.6, 1.4, 1.2),
		CFrame.new(0, 0.7, 0),
		Color3.fromRGB(60, 60, 70),
		model,
		"Legs"
	)
	-- Body (outfit)
	local body = WorldBuilder.makeBlock(
		Vector3.new(2, 2, 1.2),
		CFrame.new(0, 2.4, 0),
		outfitColor,
		model,
		"Body"
	)
	-- Head (skin)
	local head = WorldBuilder.makeBlock(
		Vector3.new(1.8, 1.8, 1.8),
		CFrame.new(0, 4.3, 0),
		skin,
		model,
		"Head"
	)
	-- Hair (a slab on top + a fringe, colored by the hair palette)
	WorldBuilder.makeBlock(
		Vector3.new(2.05, 0.8, 2.05),
		CFrame.new(0, 5.3, 0),
		hairColor,
		model,
		"HairTop"
	)
	WorldBuilder.makeBlock(
		Vector3.new(2.05, 0.6, 0.4),
		CFrame.new(0, 4.7, 0.85),
		hairColor,
		model,
		"HairFringe"
	)
	-- Simple eyes so it reads as a character.
	local function eye(x: number)
		local e = WorldBuilder.makeBlock(
			Vector3.new(0.3, 0.4, 0.1),
			CFrame.new(x, 4.4, 0.95),
			Color3.fromRGB(40, 40, 50),
			model,
			"Eye"
		)
		e.Material = Enum.Material.Neon
	end
	eye(-0.45)
	eye(0.45)

	model.PrimaryPart = legs

	-- Floating name tag.
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(4, 1)
	billboard.StudsOffset = Vector3.new(0, 3.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = head
	billboard.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = char.name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.4
	label.TextScaled = true
	label.Font = Enum.Font.GothamMedium
	label.Parent = billboard

	return model
end

local function placeModel(player: Player, char: Character)
	local record = PlotService.getRecord(player)
	if not record then
		return
	end
	-- Remove any stale model with this id.
	local existing = record.contentFolder:FindFirstChild("Char_" .. char.id)
	if existing then
		existing:Destroy()
	end

	local cframe = PlotService.tileCFrame(player, char.tile)
	if not cframe then
		return
	end

	local model = buildModel(char)
	model.Parent = record.contentFolder
	model:PivotTo(cframe)
end

CharacterService.placeModel = placeModel

-- Rebuild every character model from the saved profile (used on join).
function CharacterService.renderAll(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	for _, char in profile.characters do
		placeModel(player, char)
	end
end

-- Recruit a new character of the given archetype. Returns ok, message.
function CharacterService.recruit(player: Player, archetypeId: string): (boolean, string)
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	if #profile.characters >= Config.Characters.MaxCharacters then
		return false, "Your cast is full!"
	end

	local archetype = Util.getArchetype(archetypeId)
	if not archetype then
		return false, "Unknown character type."
	end

	local cost = Util.nextRecruitCost(#profile.characters)
	if profile.money < cost then
		return false, ("Need %s coins to recruit."):format(Util.formatNumber(cost))
	end

	local tile = PlotService.firstFreeTile(player)
	if not tile then
		return false, "No free space -- expand your plot first!"
	end

	profile.money -= cost

	local char: Character = {
		id = Util.newId("char"),
		name = archetype.name .. " #" .. tostring(#profile.characters + 1),
		archetype = archetypeId,
		hairColor = math.random(1, #Config.Characters.HairColors),
		outfitColor = math.random(1, #Config.Characters.OutfitColors),
		tile = tile,
	}
	table.insert(profile.characters, char)

	placeModel(player, char)
	PlayerDataService.markDirty(player)

	return true, ("Recruited %s!"):format(char.name)
end

-- Find a character by id within a profile.
local function findChar(profile: Types.Profile, charId: string): Types.Character?
	for _, c in profile.characters do
		if c.id == charId then
			return c
		end
	end
	return nil
end

-- Customize an existing character (recolor / rename). Returns ok, message.
function CharacterService.customize(
	player: Player,
	charId: string,
	hairColor: number?,
	outfitColor: number?,
	name: string?
): (boolean, string)
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "No profile loaded."
	end
	local char = findChar(profile, charId)
	if not char then
		return false, "Character not found."
	end

	if hairColor and hairColor >= 1 and hairColor <= #Config.Characters.HairColors then
		char.hairColor = hairColor
	end
	if outfitColor and outfitColor >= 1 and outfitColor <= #Config.Characters.OutfitColors then
		char.outfitColor = outfitColor
	end
	if name and #name > 0 then
		-- Keep names short and sanitized for the floating tag.
		char.name = string.sub(name, 1, 18)
	end

	placeModel(player, char)
	PlayerDataService.markDirty(player)
	return true, "Saved!"
end

return CharacterService
