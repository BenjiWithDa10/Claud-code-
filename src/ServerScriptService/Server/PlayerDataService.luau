--!strict
--[[
	PlayerDataService.luau
	----------------------
	Owns each player's Profile (money / tiles / characters / buildings) and
	persists it with DataStoreService. Other services read & mutate the profile
	through this module and call MarkDirty so it autosaves.

	DataStore access is wrapped in pcall so Studio (where DataStores are often
	disabled) still runs -- it just falls back to an in-memory profile.
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Types = require(Shared.Types)

type Profile = Types.Profile

local PlayerDataService = {}

local profiles: { [Player]: Profile } = {}
local dirty: { [Player]: boolean } = {}

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.Data.StoreName)
	end)
	if ok then
		store = result
	else
		warn("[PlayerDataService] DataStore unavailable, running in-memory only.")
	end
end

local function defaultProfile(): Profile
	return {
		money = Config.Economy.StartingMoney,
		tiles = Config.Plot.StartingTiles,
		characters = {},
		buildings = {},
		fans = 0,
		quality = 0,
		dominantPower = nil,
	}
end

-- Strip the derived/runtime fields before saving; they are recomputed on load.
local function serialize(profile: Profile)
	return {
		money = profile.money,
		tiles = profile.tiles,
		characters = profile.characters,
		buildings = profile.buildings,
	}
end

local function deserialize(data: any): Profile
	local p = defaultProfile()
	if type(data) == "table" then
		p.money = tonumber(data.money) or p.money
		p.tiles = tonumber(data.tiles) or p.tiles
		if type(data.characters) == "table" then
			p.characters = data.characters
		end
		if type(data.buildings) == "table" then
			p.buildings = data.buildings
		end
	end
	return p
end

function PlayerDataService.load(player: Player): Profile
	local profile = defaultProfile()

	if store then
		local key = "player_" .. player.UserId
		local ok, data = pcall(function()
			return store:GetAsync(key)
		end)
		if ok and data then
			profile = deserialize(data)
		elseif not ok then
			warn(("[PlayerDataService] load failed for %s: %s"):format(player.Name, tostring(data)))
		end
	end

	profiles[player] = profile
	return profile
end

function PlayerDataService.get(player: Player): Profile?
	return profiles[player]
end

function PlayerDataService.markDirty(player: Player)
	dirty[player] = true
end

function PlayerDataService.save(player: Player)
	local profile = profiles[player]
	if not profile or not store then
		return
	end
	if not dirty[player] then
		return
	end

	local key = "player_" .. player.UserId
	local ok, err = pcall(function()
		store:SetAsync(key, serialize(profile))
	end)
	if ok then
		dirty[player] = false
	else
		warn(("[PlayerDataService] save failed for %s: %s"):format(player.Name, tostring(err)))
	end
end

function PlayerDataService.release(player: Player)
	PlayerDataService.save(player)
	profiles[player] = nil
	dirty[player] = nil
end

-- Periodic autosave loop. Started by the bootstrap.
function PlayerDataService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(Config.Data.AutosaveInterval)
			for player in profiles do
				PlayerDataService.save(player)
			end
		end
	end)

	-- Best-effort flush when the server shuts down.
	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			dirty[player] = true
			PlayerDataService.save(player)
		end
	end)
end

return PlayerDataService
