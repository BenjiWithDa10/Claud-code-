--!strict
--[[
	init.server.luau
	----------------
	Bootstrap for Collect an Artist. Right now this only lays out the base
	map -- no spawn logic, no remotes, no gameplay scripts yet.
]]

local MapBuilder = require(script.MapBuilder)

MapBuilder.build()

print("[CollectAnArtist] Base map built.")
