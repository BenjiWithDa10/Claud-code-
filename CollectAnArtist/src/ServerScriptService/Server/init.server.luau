--!strict
--[[
	init.server.luau
	----------------
	Bootstrap for Collect an Artist. Right now this only lays out the base
	map -- no spawn logic, no remotes, no gameplay scripts yet.

	Calls MapBuilder.buildRuntime(), not MapBuilder.build(): this rebuilds
	only the systemic/parametric pieces (Ground, ConveyorLine, Studios) and
	never touches Stages/Crowd, so pressing Play can never wipe or disturb
	the hand-built entrance stage/crowd/tunnel -- whatever's already sitting
	in Workspace.Map.Stages/Crowd is left exactly as-is. Those are built (or
	rebuilt after a deliberate delete) manually via the Command Bar --
	require(game.ServerScriptService.Server.MapBuilder).build() -- never
	automatically at runtime.
]]

local MapBuilder = require(script.MapBuilder)

MapBuilder.buildRuntime()

print("[CollectAnArtist] Base map built (Stages/Crowd left untouched).")
