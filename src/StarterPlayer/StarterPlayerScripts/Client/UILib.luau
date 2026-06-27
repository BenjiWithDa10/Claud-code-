--!strict
--[[
	UILib.luau
	----------
	Tiny helper library for building the UI from code, so the whole interface
	lives in source control instead of a binary place file. Just thin wrappers
	around Instance.new with sensible defaults and a consistent look.
]]

local UILib = {}

UILib.Theme = {
	Panel = Color3.fromRGB(28, 30, 44),
	PanelLight = Color3.fromRGB(40, 43, 62),
	Accent = Color3.fromRGB(244, 121, 168),
	AccentAlt = Color3.fromRGB(120, 160, 255),
	Good = Color3.fromRGB(120, 220, 150),
	Bad = Color3.fromRGB(235, 110, 110),
	Text = Color3.fromRGB(240, 240, 248),
	SubText = Color3.fromRGB(180, 184, 200),
}

function UILib.corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function UILib.padding(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
	return p
end

function UILib.listLayout(parent: Instance, gap: number?, dir: Enum.FillDirection?)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, gap or 6)
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

function UILib.frame(props: { [string]: any }): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = UILib.Theme.Panel
	f.BorderSizePixel = 0
	for k, v in props do
		(f :: any)[k] = v
	end
	return f
end

function UILib.label(props: { [string]: any }): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = UILib.Theme.Text
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 16
	l.TextXAlignment = Enum.TextXAlignment.Left
	for k, v in props do
		(l :: any)[k] = v
	end
	return l
end

function UILib.button(props: { [string]: any }): TextButton
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = UILib.Theme.Accent
	b.TextColor3 = Color3.fromRGB(20, 20, 30)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	for k, v in props do
		(b :: any)[k] = v
	end
	UILib.corner(b, 8)
	return b
end

return UILib
