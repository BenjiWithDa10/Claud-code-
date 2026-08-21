--!strict
--[[
	ConveyorLine.luau
	-----------------
	Builds the central walkway that runs down the middle of the map. It's a
	flat slab whose top sits flush with GroundY, so artists (and players)
	cross it without any step up or down.
]]

local ConveyorLine = {}

function ConveyorLine.build(folder: Folder, layout: { [string]: any })
	local walkway = Instance.new("Part")
	walkway.Name = "Walkway"
	walkway.Anchored = true
	walkway.Size = Vector3.new(layout.ConveyorLength, layout.ConveyorHeight, layout.ConveyorWidth)
	walkway.CFrame = CFrame.new(0, layout.GroundY - layout.ConveyorHeight / 2, 0)
	walkway.Color = layout.ConveyorColor
	walkway.Material = Enum.Material.SmoothPlastic
	walkway.TopSurface = Enum.SurfaceType.Smooth
	walkway.BottomSurface = Enum.SurfaceType.Smooth
	walkway.Parent = folder
end

return ConveyorLine
