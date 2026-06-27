# 🌸 Anime World Builder

A Roblox game in the cozy, blocky **"Grow a Garden"** style — but instead of
growing plants, you **build your own anime world**. Recruit a little cast of
customizable characters, drop them on your plot, raise hidden "Power" with
themed buildings, and let your characters' story attract fans. The better your
world, the more fans watch, the more coins you earn — and the bigger you grow.

The whole game is written in Luau and generated **from code** (no binary place
file), so it lives in git and syncs into Roblox Studio with [Rojo](https://rojo.space).

---

## 🎮 The core loop

```
spend coins ──▶ expand plot / recruit cast / build power
     ▲                              │
     │                              ▼
  fans pay   ◀── more fans  ◀── better story & higher quality
```

1. **Plot** — You spawn on your own blocky island. Buy tiles to expand it.
   Each new tile costs more than the last (`cost = base × growthᵗⁱˡᵉˢ`), so
   space is a real investment.
2. **Cast** — Recruit small, customizable anime characters (Hero, Mage, Idol,
   Mecha Pilot, …). Recolor their hair/outfit. Each archetype leans toward a
   story **genre**.
3. **Power (the invisible "enchant")** — Buildings (Dojo, Wizard Tower, Cozy
   Cafe, Mecha Lab, …) aren't just decoration: each one feeds hidden **Power**
   into one genre. You never see Power directly — it's the enchant that shapes
   your world.
4. **Story** — The genre with the most Power becomes the flavor of an
   auto-generated **anime story** (genre + title + logline) starring your cast.
5. **Fans & money** — Your world's **quality** (cast appeal + building appeal +
   plot size + Power) decides how many **fans** watch. Fans pay out coins every
   few seconds. **Focusing** your Power into one genre gives a "cohesion" bonus,
   so a sharp, single-genre world earns more than a scattered one.

---

## 🗂️ Project layout

```
default.project.json          Rojo project (maps folders into the DataModel)
aftman.toml                   Toolchain pin (Rojo)
src/
├── ReplicatedStorage/Shared/ Shared code (server + client)
│   ├── Config.luau           ★ ALL tunable numbers live here (balance/look)
│   ├── Remotes.luau          RemoteEvent/Function setup
│   ├── Types.luau            Profile / Character / Building types
│   ├── Util.luau             Cost formulas + lookups + formatting
│   └── StoryGen.luau         Turns your world into a genre/title/logline
├── ServerScriptService/Server/   (becomes one Script via init.server.luau)
│   ├── init.server.luau      Bootstrap: world, join/leave, remotes, economy tick
│   ├── PlayerDataService.luau DataStore save/load (in-memory fallback in Studio)
│   ├── WorldBuilder.luau     Procedural blocky world + tile geometry math
│   ├── PlotService.luau      Plot assignment + ground tiles + expansion
│   ├── CharacterService.luau Recruit / customize / render the cast
│   ├── BuildingService.luau  Place power buildings
│   └── EconomyService.luau   Quality → fans → coins, + story payload
└── StarterPlayer/StarterPlayerScripts/Client/  (LocalScript via init.client.luau)
    ├── init.client.luau      HUD, story panel, shop menus
    └── UILib.luau            Small UI builder helpers
```

---

## 🚀 Running it

You need [Roblox Studio](https://create.roblox.com/) and Rojo.

```bash
# 1. Install the toolchain (Aftman or Rokit both read aftman.toml)
aftman install            # or: rokit install

# 2. Start the Rojo server from the repo root
rojo serve

# 3. In Roblox Studio: install the Rojo plugin, open a new baseplate,
#    open the Rojo panel and click "Connect".
#    Press Play — the world, plots and UI all generate at runtime.
```

> **DataStores:** Saving uses `DataStoreService`. In Studio it's wrapped in a
> `pcall`, so it runs fine without API access (progress just isn't persisted).
> In a published game, enable *Studio Access to API Services* / publish to save.

---

## 🔧 Tuning the game

Almost everything is in **`src/ReplicatedStorage/Shared/Config.luau`**:

- **Plot prices / growth** → `Config.Plot`
- **Character archetypes, costs, colors** → `Config.Characters`
- **Genres ("Power")** → `Config.Powers`
- **Buildings (cost, which genre they power, appeal)** → `Config.Buildings`
- **Economy (tick rate, fans-per-quality, coins-per-fan, cohesion bonus,
  quality weights)** → `Config.Economy`

Adding a new building is just a new entry in `Config.Buildings.Catalog`; adding
a genre is a new entry in `Config.Powers.List` (plus a word bank in
`StoryGen.luau` if you want custom story flavor).

---

## 🧭 Ideas for next steps

- Visitor NPC "fans" that walk onto popular worlds.
- Rarity/leveling on characters and limited-time event buildings.
- A leaderboard of the highest-quality anime worlds on the server.
- Letting players walk-place buildings on specific tiles instead of auto-fill.
