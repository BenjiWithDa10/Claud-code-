--!strict
--[[
	init.server.luau
	----------------
	Server bootstrap for Anime World Builder. Builds the world, loads/saves
	player data, assigns plots, wires every remote, and runs the economy tick.

	Flow on join:
	  load profile -> assign plot -> render saved characters & buildings ->
	  set spawn -> push initial state to the client.
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Remotes = require(Shared.Remotes)
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local PlayerDataService = require(script.PlayerDataService)
local WorldBuilder = require(script.WorldBuilder)
local PlotService = require(script.PlotService)
local CharacterService = require(script.CharacterService)
local BuildingService = require(script.BuildingService)
local EconomyService = require(script.EconomyService)

-- ----------------------------------------------------------------------------
-- World
-- ----------------------------------------------------------------------------
WorldBuilder.buildBaseplate(PlotService.MAX_PLOTS)

-- ----------------------------------------------------------------------------
-- State payload
-- ----------------------------------------------------------------------------
local function buildState(player: Player)
	local profile = PlayerDataService.get(player)
	if not profile then
		return nil
	end

	-- Make sure derived fields are fresh before we send them.
	EconomyService.recompute(profile)
	local story = EconomyService.buildStory(profile)

	return {
		money = profile.money,
		tiles = profile.tiles,
		maxTiles = Config.Plot.MaxTiles,
		nextTileCost = Util.nextTileCost(profile.tiles),
		nextRecruitCost = Util.nextRecruitCost(#profile.characters),
		characters = profile.characters,
		buildings = profile.buildings,
		fans = profile.fans,
		quality = profile.quality,
		dominantPower = profile.dominantPower,
		story = story,
	}
end

local function syncState(player: Player)
	local state = buildState(player)
	if state then
		Remotes.SyncState:FireClient(player, state)
	end
end

local function notify(player: Player, message: string, ok: boolean)
	Remotes.Notify:FireClient(player, message, ok)
end

-- ----------------------------------------------------------------------------
-- Join / leave
-- ----------------------------------------------------------------------------
local function onPlayerAdded(player: Player)
	PlayerDataService.load(player)
	PlotService.assign(player)
	CharacterService.renderAll(player)
	BuildingService.renderAll(player)

	-- Teleport the player onto their plot when their character spawns.
	local function placeCharacter(charModel: Model)
		local spawn = PlotService.spawnCFrame(player)
		if spawn then
			charModel:PivotTo(spawn)
		end
	end

	player.CharacterAdded:Connect(placeCharacter)
	if player.Character then
		placeCharacter(player.Character)
	end

	syncState(player)
end

local function onPlayerRemoving(player: Player)
	PlayerDataService.release(player)
	PlotService.release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
-- Handle players already present (e.g. when the script reloads in Studio).
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

-- ----------------------------------------------------------------------------
-- Remotes
-- ----------------------------------------------------------------------------
Remotes.RequestState.OnServerInvoke = function(player: Player)
	return buildState(player)
end

Remotes.BuyTile.OnServerEvent:Connect(function(player: Player)
	local ok, message = PlotService.buyTile(player)
	notify(player, message, ok)
	syncState(player)
end)

Remotes.RecruitChar.OnServerEvent:Connect(function(player: Player, archetypeId: any)
	if type(archetypeId) ~= "string" then
		return
	end
	local ok, message = CharacterService.recruit(player, archetypeId)
	notify(player, message, ok)
	syncState(player)
end)

Remotes.CustomizeChar.OnServerEvent:Connect(
	function(player: Player, charId: any, hair: any, outfit: any, name: any)
		if type(charId) ~= "string" then
			return
		end
		local ok, message = CharacterService.customize(
			player,
			charId,
			type(hair) == "number" and hair or nil,
			type(outfit) == "number" and outfit or nil,
			type(name) == "string" and name or nil
		)
		notify(player, message, ok)
		syncState(player)
	end
)

Remotes.PlaceBuilding.OnServerEvent:Connect(function(player: Player, kind: any)
	if type(kind) ~= "string" then
		return
	end
	local ok, message = BuildingService.place(player, kind)
	notify(player, message, ok)
	syncState(player)
end)

-- ----------------------------------------------------------------------------
-- Economy tick
-- ----------------------------------------------------------------------------
PlayerDataService.startAutosave()

task.spawn(function()
	while true do
		task.wait(Config.Economy.TickInterval)
		for _, player in Players:GetPlayers() do
			local income = EconomyService.payTick(player)
			if income > 0 then
				syncState(player)
			end
		end
	end
end)

print("[AnimeWorldBuilder] Server started. Plots available:", PlotService.MAX_PLOTS)
