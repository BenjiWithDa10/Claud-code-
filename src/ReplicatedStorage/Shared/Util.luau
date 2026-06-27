--!strict
--[[
	Util.luau
	---------
	Small stateless helpers shared by server and client.
]]

local Config = require(script.Parent.Config)

local Util = {}

-- Deterministic-ish unique id from a counter + a short random suffix.
local counter = 0
function Util.newId(prefix: string?): string
	counter += 1
	local suffix = tostring(math.random(1000, 9999))
	return string.format("%s%d_%s", prefix or "id", counter, suffix)
end

-- Cost of the next plot tile given how many the player already owns.
function Util.nextTileCost(tilesOwned: number): number
	return math.floor(Config.Plot.BaseTileCost * (Config.Plot.CostGrowth ^ tilesOwned))
end

-- Cost of the next character recruit given current roster size.
function Util.nextRecruitCost(charCount: number): number
	return math.floor(Config.Characters.BaseRecruitCost * (Config.Characters.RecruitCostGrowth ^ charCount))
end

-- Cost of placing another copy of a building, given how many of that
-- specific kind the player already owns.
function Util.buildingCost(baseCost: number, ownedOfKind: number): number
	return math.floor(baseCost * (Config.Buildings.BaseCostGrowth ^ ownedOfKind))
end

-- Lookup helpers ---------------------------------------------------------

function Util.getArchetype(id: string)
	for _, a in Config.Characters.Archetypes do
		if a.id == id then
			return a
		end
	end
	return nil
end

function Util.getBuildingDef(kind: string)
	for _, b in Config.Buildings.Catalog do
		if b.id == kind then
			return b
		end
	end
	return nil
end

function Util.getPowerDef(id: string)
	for _, p in Config.Powers.List do
		if p.id == id then
			return p
		end
	end
	return nil
end

-- Clamp + format money with thousands separators for the HUD.
function Util.formatNumber(n: number): string
	local s = tostring(math.floor(n))
	local formatted = s
	while true do
		local replaced
		formatted, replaced = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if replaced == 0 then
			break
		end
	end
	return formatted
end

return Util
