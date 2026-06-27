--!strict
--[[
	Remotes.luau
	------------
	Lazily creates (server) and waits for (client) every RemoteEvent and
	RemoteFunction the game uses, all under a single folder in
	ReplicatedStorage. Requiring this module from either side returns a table
	of remotes you can index by name.

	Server  -> Client : "SyncState"     (RemoteEvent)  pushes the player's full state
	Client  -> Server : "BuyTile"       (RemoteEvent)  expand the plot
	Client  -> Server : "RecruitChar"   (RemoteEvent)  add a new character
	Client  -> Server : "CustomizeChar" (RemoteEvent)  recolor / rename a character
	Client  -> Server : "PlaceBuilding" (RemoteEvent)  buy + place a building
	Client  -> Server : "RequestState"  (RemoteFunction) initial pull on join
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "AnimeWorldRemotes"

local EVENTS = {
	"SyncState",
	"BuyTile",
	"RecruitChar",
	"CustomizeChar",
	"PlaceBuilding",
	"Notify",
}

local FUNCTIONS = {
	"RequestState",
}

local Remotes = {}

local function getFolder(): Folder
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	end
end

local function getOrCreate(folder: Folder, className: string, name: string): Instance
	if RunService:IsServer() then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing
		end
		local inst = Instance.new(className)
		inst.Name = name
		inst.Parent = folder
		return inst
	else
		return folder:WaitForChild(name)
	end
end

local folder = getFolder()

for _, name in EVENTS do
	Remotes[name] = getOrCreate(folder, "RemoteEvent", name)
end

for _, name in FUNCTIONS do
	Remotes[name] = getOrCreate(folder, "RemoteFunction", name)
end

-- Returned untyped on purpose: callers index named remotes (e.g.
-- Remotes.SyncState:FireClient) and call RemoteEvent/RemoteFunction methods
-- that a generic Instance type would reject under --!strict.
return Remotes :: any
