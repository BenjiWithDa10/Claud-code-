--!strict
--[[
	EconomyService.luau
	-------------------
	The money loop the user described: the better your anime world is, the more
	fans watch, and fans pay out coins over time. You spend coins to expand the
	plot, recruit characters and build power buildings -- which raises quality,
	which brings more fans. The flywheel that makes you "bigger and bigger".

	Quality is computed from:
	  * total character appeal (each archetype has a base appeal)
	  * total building appeal
	  * plot size (a bigger stage)
	  * total raw Power (scaled down)
	  * a "genre cohesion" multiplier: focusing your Power into one genre makes
	    a tighter story that fans reward.

	The dominant Power is the invisible enchant that decides the story's genre.
]]

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local StoryGen = require(Shared.StoryGen)
local Types = require(Shared.Types)

local PlayerDataService = require(script.Parent.PlayerDataService)

local EconomyService = {}

-- Sum Power per genre across the player's characters and buildings.
-- Returns the per-genre table, the total, and the dominant genre id.
local function computePower(profile: Types.Profile): ({ [string]: number }, number, string?)
	local power: { [string]: number } = {}
	for _, p in Config.Powers.List do
		power[p.id] = 0
	end

	-- Characters nudge their favored genre.
	for _, c in profile.characters do
		local arch = Util.getArchetype(c.archetype)
		if arch then
			power[arch.favors] = (power[arch.favors] or 0) + 2
		end
	end

	-- Buildings are the main Power source.
	for _, b in profile.buildings do
		local def = Util.getBuildingDef(b.kind)
		if def then
			power[def.power] = (power[def.power] or 0) + def.powerAmount
		end
	end

	local total = 0
	local dominant: string? = nil
	local best = 0
	for genre, amount in power do
		total += amount
		if amount > best then
			best = amount
			dominant = genre
		end
	end

	if total == 0 then
		dominant = nil
	end

	return power, total, dominant
end

-- Cohesion: 1.0 when Power is spread evenly, up to MaxCohesionBonus when it is
-- all concentrated in the dominant genre.
local function cohesion(power: { [string]: number }, total: number, dominant: string?): number
	if total <= 0 or not dominant then
		return 1.0
	end
	local share = power[dominant] / total -- 0..1
	-- Map share (1/numGenres .. 1) -> (1 .. MaxCohesionBonus)
	local numGenres = #Config.Powers.List
	local minShare = 1 / numGenres
	local t = math.clamp((share - minShare) / (1 - minShare), 0, 1)
	return 1 + t * (Config.Economy.MaxCohesionBonus - 1)
end

-- Recompute quality / fans for a profile and write the derived fields back.
-- Returns the dominant genre and the cohesion multiplier (for income).
function EconomyService.recompute(profile: Types.Profile): (string?, number)
	local weights = Config.Economy.Weights

	local charAppeal = 0
	for _, c in profile.characters do
		local arch = Util.getArchetype(c.archetype)
		if arch then
			charAppeal += arch.baseAppeal
		end
	end

	local buildingAppeal = 0
	for _, b in profile.buildings do
		local def = Util.getBuildingDef(b.kind)
		if def then
			buildingAppeal += def.appeal
		end
	end

	local power, totalPower, dominant = computePower(profile)
	local coh = cohesion(power, totalPower, dominant)

	local quality = (
		charAppeal * weights.CharacterAppeal
		+ buildingAppeal * weights.BuildingAppeal
		+ profile.tiles * weights.TileBonus
		+ totalPower * weights.PowerScale
	) * coh

	local fans = math.floor(quality * Config.Economy.FansPerQuality)

	profile.quality = math.floor(quality)
	profile.fans = fans
	profile.dominantPower = dominant

	return dominant, coh
end

-- Pay one tick of income to the player based on current fans.
function EconomyService.payTick(player: Player): number
	local profile = PlayerDataService.get(player)
	if not profile then
		return 0
	end

	local dominant, coh = EconomyService.recompute(profile)
	local income = math.floor(profile.fans * Config.Economy.MoneyPerFanPerTick * coh)

	if income > 0 then
		profile.money += income
		PlayerDataService.markDirty(player)
	end

	return income
end

-- Build the story summary payload for the client.
function EconomyService.buildStory(profile: Types.Profile): Types.StorySummary
	EconomyService.recompute(profile)

	local castNames = {}
	for _, c in profile.characters do
		table.insert(castNames, c.name)
	end

	return StoryGen.generate({
		dominant = profile.dominantPower,
		castNames = castNames,
		quality = profile.quality,
		fans = profile.fans,
	})
end

return EconomyService
