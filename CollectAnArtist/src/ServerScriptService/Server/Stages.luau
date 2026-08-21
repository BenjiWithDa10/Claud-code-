--!strict
--[[
	Stages.luau
	-----------
	Builds the entrance and exit stages, one at each end of the conveyor
	line. Same flush ground height as everything else -- these just mark
	where artists will spawn in and where they'll be collected/despawn.
]]

local Stages = {}

local function makeStage(folder: Folder, name: string, centerX: number, layout: { [string]: any })
	local stage = Instance.new("Part")
	stage.Name = name
	stage.Anchored = true
	stage.Size = Vector3.new(layout.StageLength, layout.StageHeight, layout.StageWidth)
	stage.CFrame = CFrame.new(centerX, layout.GroundY - layout.StageHeight / 2, 0)
	stage.Color = layout.StageColor
	stage.Material = Enum.Material.SmoothPlastic
	stage.TopSurface = Enum.SurfaceType.Smooth
	stage.BottomSurface = Enum.SurfaceType.Smooth
	stage.Parent = folder
end

function Stages.build(folder: Folder, layout: { [string]: any })
	local halfConveyor = layout.ConveyorLength / 2

	makeStage(folder, "EntranceStage", -halfConveyor - layout.StageLength / 2, layout)
	makeStage(folder, "ExitStage", halfConveyor + layout.StageLength / 2, layout)
end

return Stages
