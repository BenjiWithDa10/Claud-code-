--!strict
--[[
	init.client.luau
	----------------
	Builds the player's interface from code and keeps it in sync with the server.

	HUD (top):       coins, fans watching, world quality.
	Story panel:     the auto-generated genre / title / logline for your anime.
	Toolbar (right): Expand Plot, Recruit Cast, Build, Customize.

	Each toolbar button opens a panel that fires the matching remote. The server
	is authoritative -- the client just asks, then re-renders from SyncState.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local Config = require(Shared.Config)
local Util = require(Shared.Util)

local UILib = require(script.UILib)
local Theme = UILib.Theme

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Latest state pushed from the server. Panels read from this when re-rendering.
local state: any = nil

-- ----------------------------------------------------------------------------
-- Screen
-- ----------------------------------------------------------------------------
local screen = Instance.new("ScreenGui")
screen.Name = "AnimeWorldUI"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
screen.Parent = playerGui

-- ----------------------------------------------------------------------------
-- Toast notifications
-- ----------------------------------------------------------------------------
local function toast(message: string, ok: boolean)
	local t = UILib.frame({
		Size = UDim2.fromOffset(360, 44),
		Position = UDim2.new(0.5, -180, 0, 70),
		BackgroundColor3 = ok and Theme.PanelLight or Theme.Bad,
		BackgroundTransparency = 0.05,
	})
	UILib.corner(t, 10)
	local lbl = UILib.label({
		Size = UDim2.fromScale(1, 1),
		Text = message,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = ok and Theme.Text or Color3.fromRGB(30, 20, 20),
		Font = Enum.Font.GothamBold,
	})
	lbl.Parent = t
	t.Parent = screen
	task.delay(2.4, function()
		t:Destroy()
	end)
end

-- ----------------------------------------------------------------------------
-- HUD (top bar)
-- ----------------------------------------------------------------------------
local hud = UILib.frame({
	Size = UDim2.new(0, 520, 0, 56),
	Position = UDim2.new(0.5, -260, 0, 12),
	BackgroundTransparency = 0.05,
})
UILib.corner(hud, 12)
UILib.padding(hud, 10)
hud.Parent = screen
do
	local layout = UILib.listLayout(hud, 10, Enum.FillDirection.Horizontal)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
end

local function statBox(name: string, color: Color3)
	local box = UILib.frame({
		Size = UDim2.new(0, 160, 1, 0),
		BackgroundColor3 = Theme.PanelLight,
	})
	UILib.corner(box, 8)
	local title = UILib.label({
		Size = UDim2.new(1, -12, 0, 16),
		Position = UDim2.fromOffset(8, 4),
		Text = name,
		TextColor3 = Theme.SubText,
		TextSize = 12,
	})
	title.Parent = box
	local value = UILib.label({
		Name = "Value",
		Size = UDim2.new(1, -12, 0, 20),
		Position = UDim2.fromOffset(8, 20),
		Text = "0",
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = 18,
	})
	value.Parent = box
	box.Parent = hud
	return value
end

local moneyValue = statBox("COINS", Theme.Accent)
local fansValue = statBox("FANS WATCHING", Theme.AccentAlt)
local qualityValue = statBox("WORLD QUALITY", Theme.Good)

-- ----------------------------------------------------------------------------
-- Story panel (bottom)
-- ----------------------------------------------------------------------------
local storyPanel = UILib.frame({
	Size = UDim2.new(0, 460, 0, 110),
	Position = UDim2.new(0.5, -230, 1, -130),
	BackgroundTransparency = 0.08,
})
UILib.corner(storyPanel, 12)
UILib.padding(storyPanel, 12)
storyPanel.Parent = screen

local storyGenre = UILib.label({
	Size = UDim2.new(1, 0, 0, 16),
	Text = "GENRE",
	TextColor3 = Theme.Accent,
	TextSize = 13,
	Font = Enum.Font.GothamBold,
})
storyGenre.Parent = storyPanel
local storyTitle = UILib.label({
	Size = UDim2.new(1, 0, 0, 26),
	Position = UDim2.fromOffset(0, 18),
	Text = "An Empty Stage",
	TextSize = 22,
	Font = Enum.Font.GothamBold,
})
storyTitle.Parent = storyPanel
local storyLogline = UILib.label({
	Size = UDim2.new(1, 0, 0, 48),
	Position = UDim2.fromOffset(0, 48),
	Text = "",
	TextColor3 = Theme.SubText,
	TextSize = 14,
	TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top,
})
storyLogline.Parent = storyPanel

-- ----------------------------------------------------------------------------
-- Generic popup panel used by every shop
-- ----------------------------------------------------------------------------
local activePanel: Frame? = nil

local function closePanel()
	if activePanel then
		activePanel:Destroy()
		activePanel = nil
	end
end

local function openPanel(titleText: string, kind: string): (Frame, Frame)
	closePanel()
	local panel = UILib.frame({
		Size = UDim2.fromOffset(440, 460),
		Position = UDim2.new(0.5, -220, 0.5, -230),
		BackgroundTransparency = 0.02,
	})
	UILib.corner(panel, 14)
	panel:SetAttribute("PanelKind", kind)
	panel.Parent = screen
	activePanel = panel

	local header = UILib.label({
		Size = UDim2.new(1, -60, 0, 40),
		Position = UDim2.fromOffset(16, 10),
		Text = titleText,
		TextSize = 22,
		Font = Enum.Font.GothamBold,
	})
	header.Parent = panel

	local closeBtn = UILib.button({
		Size = UDim2.fromOffset(34, 34),
		Position = UDim2.new(1, -44, 0, 12),
		Text = "X",
		BackgroundColor3 = Theme.Bad,
		TextColor3 = Theme.Text,
	})
	closeBtn.Parent = panel
	closeBtn.Activated:Connect(closePanel)

	local body = UILib.frame({
		Size = UDim2.new(1, -24, 1, -64),
		Position = UDim2.fromOffset(12, 56),
		BackgroundTransparency = 1,
	})
	body.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = body
	local layout = UILib.listLayout(scroll, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	return panel, scroll
end

-- A reusable "store row": label on the left, action button on the right.
local function storeRow(parent: Instance, title: string, subtitle: string, buttonText: string, onClick: () -> ())
	local row = UILib.frame({
		Size = UDim2.new(1, -8, 0, 64),
		BackgroundColor3 = Theme.PanelLight,
	})
	UILib.corner(row, 10)
	row.Parent = parent

	local t = UILib.label({
		Size = UDim2.new(1, -150, 0, 22),
		Position = UDim2.fromOffset(12, 10),
		Text = title,
		Font = Enum.Font.GothamBold,
		TextSize = 16,
	})
	t.Parent = row
	local s = UILib.label({
		Size = UDim2.new(1, -150, 0, 18),
		Position = UDim2.fromOffset(12, 34),
		Text = subtitle,
		TextColor3 = Theme.SubText,
		TextSize = 13,
	})
	s.Parent = row

	local btn = UILib.button({
		Size = UDim2.fromOffset(120, 40),
		Position = UDim2.new(1, -132, 0.5, -20),
		Text = buttonText,
	})
	btn.Parent = row
	btn.Activated:Connect(onClick)
	return row
end

-- ----------------------------------------------------------------------------
-- Panels
-- ----------------------------------------------------------------------------
local function openExpandPanel()
	local _, scroll = openPanel("Expand Your Plot", "expand")
	if not state then
		return
	end

	local info = UILib.label({
		Size = UDim2.new(1, -8, 0, 40),
		Text = ("Plot size: %d / %d tiles. Each new tile costs more than the last.")
			:format(state.tiles, state.maxTiles),
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextSize = 14,
	})
	info.Parent = scroll

	if state.tiles >= state.maxTiles then
		storeRow(scroll, "Maxed out!", "Your plot is as big as it gets.", "MAX", function() end)
	else
		storeRow(
			scroll,
			"Buy next tile",
			("Cost: %s coins"):format(Util.formatNumber(state.nextTileCost)),
			"EXPAND",
			function()
				Remotes.BuyTile:FireServer()
			end
		)
	end
end

local function openRecruitPanel()
	local _, scroll = openPanel("Recruit Your Cast", "recruit")
	if not state then
		return
	end

	local info = UILib.label({
		Size = UDim2.new(1, -8, 0, 40),
		Text = ("Cast: %d / %d. Next recruit costs %s coins. Each character favors a story genre.")
			:format(#state.characters, Config.Characters.MaxCharacters, Util.formatNumber(state.nextRecruitCost)),
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextSize = 14,
	})
	info.Parent = scroll

	for _, arch in Config.Characters.Archetypes do
		local powerDef = Util.getPowerDef(arch.favors)
		storeRow(
			scroll,
			arch.name,
			("Favors %s  •  +%d appeal"):format(powerDef and powerDef.name or arch.favors, arch.baseAppeal),
			"RECRUIT",
			function()
				Remotes.RecruitChar:FireServer(arch.id)
			end
		)
	end
end

local function openBuildPanel()
	local _, scroll = openPanel("Build Power Structures", "build")
	if not state then
		return
	end

	local info = UILib.label({
		Size = UDim2.new(1, -8, 0, 44),
		Text = "Buildings feed hidden Power into a genre. The genre with the most Power becomes your anime's story. Focusing one genre boosts fan income!",
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextSize = 14,
	})
	info.Parent = scroll

	-- Count how many of each kind the player owns so we can show live prices.
	local owned: { [string]: number } = {}
	for _, b in state.buildings do
		owned[b.kind] = (owned[b.kind] or 0) + 1
	end

	for _, def in Config.Buildings.Catalog do
		local powerDef = Util.getPowerDef(def.power)
		local count = owned[def.id] or 0
		local cost = Util.buildingCost(def.cost, count)
		storeRow(
			scroll,
			("%s  (x%d)"):format(def.name, count),
			("%s  •  +%d power, +%d appeal  •  %s coins"):format(
				powerDef and powerDef.name or def.power,
				def.powerAmount,
				def.appeal,
				Util.formatNumber(cost)
			),
			"BUILD",
			function()
				Remotes.PlaceBuilding:FireServer(def.id)
			end
		)
	end
end

local function openCustomizePanel()
	local _, scroll = openPanel("Customize Your Cast", "customize")
	if not state then
		return
	end

	if #state.characters == 0 then
		local empty = UILib.label({
			Size = UDim2.new(1, -8, 0, 40),
			Text = "You have no characters yet. Recruit some first!",
			TextColor3 = Theme.SubText,
			TextWrapped = true,
		})
		empty.Parent = scroll
		return
	end

	for _, char in state.characters do
		local row = UILib.frame({
			Size = UDim2.new(1, -8, 0, 96),
			BackgroundColor3 = Theme.PanelLight,
		})
		UILib.corner(row, 10)
		row.Parent = scroll

		local nameLabel = UILib.label({
			Size = UDim2.new(1, -24, 0, 22),
			Position = UDim2.fromOffset(12, 8),
			Text = char.name,
			Font = Enum.Font.GothamBold,
			TextSize = 16,
		})
		nameLabel.Parent = row

		-- Cycle-hair button
		local hairBtn = UILib.button({
			Size = UDim2.fromOffset(120, 30),
			Position = UDim2.fromOffset(12, 54),
			Text = "Hair Color",
			BackgroundColor3 = Theme.AccentAlt,
			TextColor3 = Theme.Text,
		})
		hairBtn.Parent = row
		hairBtn.Activated:Connect(function()
			local nextHair = (char.hairColor % #Config.Characters.HairColors) + 1
			Remotes.CustomizeChar:FireServer(char.id, nextHair, nil, nil)
		end)

		local outfitBtn = UILib.button({
			Size = UDim2.fromOffset(120, 30),
			Position = UDim2.fromOffset(140, 54),
			Text = "Outfit Color",
			BackgroundColor3 = Theme.AccentAlt,
			TextColor3 = Theme.Text,
		})
		outfitBtn.Parent = row
		outfitBtn.Activated:Connect(function()
			local nextOutfit = (char.outfitColor % #Config.Characters.OutfitColors) + 1
			Remotes.CustomizeChar:FireServer(char.id, nil, nextOutfit, nil)
		end)
	end
end

-- ----------------------------------------------------------------------------
-- Toolbar (right side)
-- ----------------------------------------------------------------------------
local toolbar = UILib.frame({
	Size = UDim2.fromOffset(150, 250),
	Position = UDim2.new(1, -166, 0.5, -125),
	BackgroundTransparency = 0.05,
})
UILib.corner(toolbar, 12)
UILib.padding(toolbar, 10)
toolbar.Parent = screen
UILib.listLayout(toolbar, 8)

local function toolButton(text: string, onClick: () -> ())
	local b = UILib.button({
		Size = UDim2.new(1, 0, 0, 46),
		Text = text,
	})
	b.Parent = toolbar
	b.Activated:Connect(onClick)
end

toolButton("Expand Plot", openExpandPanel)
toolButton("Recruit Cast", openRecruitPanel)
toolButton("Build", openBuildPanel)
toolButton("Customize", openCustomizePanel)

-- ----------------------------------------------------------------------------
-- State sync
-- ----------------------------------------------------------------------------
local function applyState(newState: any)
	state = newState
	moneyValue.Text = Util.formatNumber(state.money)
	fansValue.Text = Util.formatNumber(state.fans)
	qualityValue.Text = Util.formatNumber(state.quality)

	if state.story then
		storyGenre.Text = string.upper(state.story.genre)
		storyTitle.Text = "\"" .. state.story.title .. "\""
		storyLogline.Text = state.story.logline
	end

	-- If a panel is open, re-render it so prices/counts update live.
	if activePanel then
		local name = activePanel:GetAttribute("PanelKind")
		-- (panels rebuild fully on open; cheapest correct refresh is to reopen)
		if name == "expand" then openExpandPanel()
		elseif name == "recruit" then openRecruitPanel()
		elseif name == "build" then openBuildPanel()
		elseif name == "customize" then openCustomizePanel()
		end
	end
end

Remotes.SyncState.OnClientEvent:Connect(applyState)
Remotes.Notify.OnClientEvent:Connect(function(message: string, ok: boolean)
	toast(message, ok)
end)

-- Pull initial state (server may have fired SyncState before we connected).
task.spawn(function()
	local ok, initial = pcall(function()
		return Remotes.RequestState:InvokeServer()
	end)
	if ok and initial then
		applyState(initial)
	end
end)

print("[AnimeWorldBuilder] Client UI ready.")
