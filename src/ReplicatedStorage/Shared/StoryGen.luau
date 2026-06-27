--!strict
--[[
	StoryGen.luau
	-------------
	Turns the player's world (dominant Power + cast + buildings) into a short
	"anime" story summary: a genre, a title and a logline. This is the payoff
	the user described -- the characters "build a story based on what you have
	built". The dominant Power (the invisible enchant) picks the genre, and the
	cast + buildings fill in the flavor words.

	Pure function of its inputs so it can run on the server and be unit-tested.
]]

local Config = require(script.Parent.Config)

local StoryGen = {}

-- Genre-flavored word banks keyed by Power id.
local BANK: { [string]: { titleA: { string }, titleB: { string }, hook: { string } } } = {
	action = {
		titleA = { "Blazing", "Iron", "Final", "Unbroken", "Crimson" },
		titleB = { "Fists", "Frontier", "Vanguard", "Strike", "Ascension" },
		hook = {
			"a tournament that will decide the fate of the world",
			"a rival who refuses to stay down",
			"one last fight before the sun sets",
		},
	},
	fantasy = {
		titleA = { "Echoes of", "The Last", "Realm of", "Veil of", "Throne of" },
		titleB = { "Aether", "the Moonspire", "Embergard", "the Hollow King", "Starlight" },
		hook = {
			"a forgotten spell that could remake the kingdom",
			"a prophecy nobody wanted to be true",
			"a door between worlds left carelessly open",
		},
	},
	slice = {
		titleA = { "Sunday at", "Quiet Days in", "After School", "Tea with", "Letters from" },
		titleB = { "the Cafe", "Sakura Lane", "the Club Room", "You", "Summer" },
		hook = {
			"a friendship that grows over shared afternoons",
			"a small town learning to dream bigger",
			"the little things that turn out to matter most",
		},
	},
	comedy = {
		titleA = { "Totally Normal", "Help, My", "Chaotic", "Definitely Not", "Oops, the" },
		titleB = { "School Life", "Roommate", "Club", "a Hero", "Apocalypse" },
		hook = {
			"a misunderstanding that spirals gloriously out of control",
			"a club president with absolutely no chill",
			"a plan that was doomed from sentence one",
		},
	},
	scifi = {
		titleA = { "Neon", "Orbital", "Project", "Zero", "Synthetic" },
		titleB = { "Genesis", "Drift", "Halcyon", "Protocol", "Horizon" },
		hook = {
			"a machine that started asking questions",
			"a colony that lost contact with home",
			"a pilot bonded to something they don't understand",
		},
	},
	mystery = {
		titleA = { "The Case of", "Whispers in", "Beneath", "Nobody Saw", "The Locked" },
		titleB = { "the Old Shrine", "the Rain", "the Festival", "Her", "Room" },
		hook = {
			"a disappearance the town refuses to discuss",
			"a clue that should not exist",
			"a truth buried under one too many smiles",
		},
	},
}

local function pick(list: { string }, seed: number): string
	if #list == 0 then
		return ""
	end
	local idx = (seed % #list) + 1
	return list[idx]
end

-- counts: map of power id -> total power amount
-- dominant: the power id with the most points (or nil if the world is empty)
-- castNames: array of character names to name-drop in the logline
export type Inputs = {
	dominant: string?,
	castNames: { string },
	quality: number,
	fans: number,
}

function StoryGen.generate(inputs: Inputs)
	local dominant = inputs.dominant
	if not dominant or not BANK[dominant] then
		return {
			genre = "Untold",
			title = "An Empty Stage",
			logline = "Your world is quiet. Recruit characters and build something for them to live in -- their story is waiting to begin.",
			fans = inputs.fans,
			quality = inputs.quality,
		}
	end

	local bank = BANK[dominant]
	local powerDef = nil
	for _, p in Config.Powers.List do
		if p.id == dominant then
			powerDef = p
		end
	end
	local genreName = powerDef and powerDef.name or dominant

	-- Seed picks off the quality so the story feels stable-ish but evolves
	-- as the world grows.
	local seed = math.floor(inputs.quality)
	local title = string.format("%s %s", pick(bank.titleA, seed), pick(bank.titleB, seed * 3 + 1))
	local hook = pick(bank.hook, seed * 7 + 2)

	local leadA = inputs.castNames[1] or "an unlikely lead"
	local leadB = inputs.castNames[2]

	local logline
	if leadB then
		logline = string.format("%s and %s are caught up in %s.", leadA, leadB, hook)
	else
		logline = string.format("%s is caught up in %s.", leadA, hook)
	end

	return {
		genre = genreName,
		title = title,
		logline = logline,
		fans = inputs.fans,
		quality = inputs.quality,
	}
end

return StoryGen
