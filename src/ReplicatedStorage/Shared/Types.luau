--!strict
--[[
	Types.luau
	----------
	Shared type definitions for the player save profile and its sub-records.
	Both server and client require this so the SyncState payload is typed the
	same on both ends.
]]

export type Character = {
	id: string,        -- unique within the player's profile
	name: string,
	archetype: string, -- matches Config.Characters.Archetypes[].id
	hairColor: number, -- index into Config.Characters.HairColors
	outfitColor: number, -- index into Config.Characters.OutfitColors
	tile: number,      -- which plot tile index it stands on
}

export type Building = {
	id: string,        -- unique within the player's profile
	kind: string,      -- matches Config.Buildings.Catalog[].id
	tile: number,      -- which plot tile index it occupies
}

export type Profile = {
	money: number,
	tiles: number,         -- how many plot tiles the player has unlocked
	characters: { Character },
	buildings: { Building },

	-- Derived, recomputed every economy tick (not strictly required to save,
	-- but handy for the UI and for quick fan payouts).
	fans: number,
	quality: number,
	dominantPower: string?,
}

-- The story payload the server generates and sends to the client.
export type StorySummary = {
	genre: string,
	title: string,
	logline: string,
	fans: number,
	quality: number,
}

return {}
