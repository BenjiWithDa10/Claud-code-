--!strict
--[[
	Config.luau
	------------
	Single source of truth for every tunable number in the game.
	If you want to rebalance the economy or change the look of the world,
	this is the file you edit. Nothing here references runtime instances,
	so it is safe to require from both the server and the client.
]]

local Config = {}

-- ============================================================
-- WORLD / MAP  (the blocky "Grow a Garden" baseplate vibe)
-- ============================================================
Config.World = {
	-- Size of a single voxel block (studs). Everything snaps to this grid.
	BlockSize = 8,

	-- The grid of plots. Each plot is a square of tiles a player can stand on
	-- and decorate. Players start with 1 tile and buy more to expand.
	PlotTilesPerSide = 6, -- a plot is 6x6 tiles at full expansion
	TileSize = 8, -- studs per tile (matches BlockSize so it stays blocky)

	-- How plots are laid out in the world. Plots are arranged on a big grid
	-- with gaps (paths) between them so each player has their own island.
	PlotSpacing = 80, -- studs between plot origins
	PlotsPerRow = 6, -- plots arranged 6 wide, then wraps to next row

	-- Pastel-ish palette for the ground tiles so it reads "cozy blocky game".
	GroundColors = {
		Color3.fromRGB(133, 199, 122),
		Color3.fromRGB(120, 190, 110),
		Color3.fromRGB(146, 209, 135),
	},

	BaseplateColor = Color3.fromRGB(96, 150, 90),
	PathColor = Color3.fromRGB(196, 178, 140),
}

-- ============================================================
-- PLOTS  (expand with money, price scales with how many you own)
-- ============================================================
Config.Plot = {
	-- A player begins owning this many tiles (a small starter square).
	StartingTiles = 4, -- a 2x2 block

	-- Maximum tiles a single plot can hold (PlotTilesPerSide^2).
	MaxTiles = 36,

	-- Cost of buying the NEXT tile. The price grows the more tiles you own,
	-- exactly like the user asked ("goes up in price the more plots you have").
	-- cost = BaseTileCost * (CostGrowth ^ tilesOwned)
	BaseTileCost = 250,
	CostGrowth = 1.18,
}

-- ============================================================
-- CHARACTERS  (small customizable anime cast that live on your plot)
-- ============================================================
Config.Characters = {
	-- Cost to recruit a new character. Scales with how many you already have.
	BaseRecruitCost = 500,
	RecruitCostGrowth = 1.35,

	-- Hard cap so plots do not get overcrowded / laggy.
	MaxCharacters = 24,

	-- "Archetypes" are the anime-character roles the player customizes.
	-- Each archetype leans toward certain story Powers (see Config.Powers),
	-- which is how the invisible "enchant" influences the generated story.
	Archetypes = {
		{ id = "hero",     name = "Hero",          favors = "action",   baseAppeal = 10 },
		{ id = "rival",    name = "Rival",         favors = "action",   baseAppeal = 9 },
		{ id = "mage",     name = "Mage",          favors = "fantasy",  baseAppeal = 11 },
		{ id = "idol",     name = "Idol",          favors = "slice",    baseAppeal = 12 },
		{ id = "mentor",   name = "Mentor",        favors = "fantasy",  baseAppeal = 8 },
		{ id = "trickster",name = "Trickster",     favors = "comedy",   baseAppeal = 9 },
		{ id = "mecha",    name = "Mecha Pilot",   favors = "scifi",    baseAppeal = 11 },
		{ id = "spirit",   name = "Spirit",        favors = "mystery",  baseAppeal = 10 },
	},

	-- Cosmetic palettes players can recolor a character with (hair/outfit).
	HairColors = {
		Color3.fromRGB(244, 121, 131), -- pink
		Color3.fromRGB(99, 155, 255),  -- blue
		Color3.fromRGB(255, 214, 102), -- blonde
		Color3.fromRGB(140, 120, 220), -- purple
		Color3.fromRGB(80, 80, 90),    -- black
		Color3.fromRGB(120, 220, 180), -- mint
	},
	OutfitColors = {
		Color3.fromRGB(235, 235, 240),
		Color3.fromRGB(60, 70, 100),
		Color3.fromRGB(180, 60, 70),
		Color3.fromRGB(70, 140, 90),
		Color3.fromRGB(230, 160, 70),
	},
}

-- ============================================================
-- POWERS  (the invisible "enchant" that flavors the world & story)
-- ============================================================
-- Powers are NOT visible objects. They are hidden stats that buildings and
-- characters contribute to. The dominant Power decides the genre of the
-- auto-generated story, which in turn changes how many fans you attract.
Config.Powers = {
	List = {
		{ id = "action",  name = "Action",        color = Color3.fromRGB(230, 90, 80) },
		{ id = "fantasy", name = "Fantasy",        color = Color3.fromRGB(150, 110, 230) },
		{ id = "slice",   name = "Slice of Life",  color = Color3.fromRGB(120, 200, 150) },
		{ id = "comedy",  name = "Comedy",         color = Color3.fromRGB(245, 200, 80) },
		{ id = "scifi",   name = "Sci-Fi",         color = Color3.fromRGB(80, 190, 220) },
		{ id = "mystery", name = "Mystery",        color = Color3.fromRGB(90, 100, 140) },
	},
}

-- ============================================================
-- BUILDINGS  (placeables that grant Power and raise world quality)
-- ============================================================
-- Each building gives flat Power toward one genre plus a small appeal bonus.
-- Buying buildings is the main money sink that grows your world's quality.
Config.Buildings = {
	BaseCostGrowth = 1.22, -- each copy of the same building costs more

	Catalog = {
		{
			id = "dojo", name = "Training Dojo", cost = 400, footprint = 1,
			power = "action", powerAmount = 6, appeal = 4,
			color = Color3.fromRGB(170, 80, 70),
		},
		{
			id = "tower", name = "Wizard Tower", cost = 650, footprint = 1,
			power = "fantasy", powerAmount = 8, appeal = 5,
			color = Color3.fromRGB(120, 90, 200),
		},
		{
			id = "cafe", name = "Cozy Cafe", cost = 350, footprint = 1,
			power = "slice", powerAmount = 6, appeal = 4,
			color = Color3.fromRGB(120, 190, 150),
		},
		{
			id = "stage", name = "Comedy Stage", cost = 500, footprint = 1,
			power = "comedy", powerAmount = 7, appeal = 5,
			color = Color3.fromRGB(235, 195, 90),
		},
		{
			id = "lab", name = "Mecha Lab", cost = 800, footprint = 1,
			power = "scifi", powerAmount = 9, appeal = 6,
			color = Color3.fromRGB(90, 180, 210),
		},
		{
			id = "shrine", name = "Old Shrine", cost = 600, footprint = 1,
			power = "mystery", powerAmount = 8, appeal = 5,
			color = Color3.fromRGB(100, 110, 150),
		},
	},
}

-- ============================================================
-- ECONOMY  (fans watch your anime -> money; better world = more fans)
-- ============================================================
Config.Economy = {
	StartingMoney = 1000,

	-- How often (seconds) we recompute fans and pay out income.
	TickInterval = 3,

	-- Fans are derived from world quality. Money is earned per tick from fans.
	-- fans = floor( quality * FansPerQuality )
	FansPerQuality = 1.5,

	-- income per tick = fans * MoneyPerFanPerTick * genreBonus
	MoneyPerFanPerTick = 0.05,

	-- "Genre cohesion" reward: if most of your Power is concentrated in one
	-- genre, the story is more focused and fans love it. This is the multiplier
	-- applied when a single genre dominates (1.0 = no bonus, up to this cap).
	MaxCohesionBonus = 2.0,

	-- World quality formula weights (see EconomyService for how they combine).
	Weights = {
		CharacterAppeal = 1.0, -- sum of each character's appeal
		BuildingAppeal = 1.0,  -- sum of each building's appeal
		TileBonus = 2.0,       -- bigger plot = slightly higher quality
		PowerScale = 0.25,     -- total raw Power contributes a little directly
	},
}

-- ============================================================
-- DATASTORE
-- ============================================================
Config.Data = {
	StoreName = "AnimeWorld_v1",
	AutosaveInterval = 60, -- seconds
}

return Config
