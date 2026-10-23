-- SpiritData: rarity colors, launch roster (names are placeholders until art direction), spawn odds per zone.
local C = Color3.fromRGB
local SpiritData = {}

SpiritData.RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret" }
SpiritData.RarityColor = {
	Common = C(235, 235, 235), Uncommon = C(90, 230, 110), Rare = C(70, 150, 255), Epic = C(185, 90, 255),
	Legendary = C(255, 165, 40), Mythic = C(255, 70, 180), Secret = C(40, 255, 235),
}
-- ball size by rarity (studs)
SpiritData.RaritySize = { Common = 2.2, Uncommon = 2.4, Rare = 2.7, Epic = 3, Legendary = 3.4, Mythic = 3.8, Secret = 4.2 }
-- cash per second at base (used in a later step)
SpiritData.RarityCash = { Common = 1, Uncommon = 3, Rare = 10, Epic = 30, Legendary = 100, Mythic = 300, Secret = 1000 }

-- Launch roster by rarity.
SpiritData.ByRarity = {
	Common = { "Wood", "Breeze" },
	Uncommon = { "Ember", "Pebble" },
	Rare = { "Nature", "Light" },
	Epic = { "Gale", "Blaze", "Boulder", "Pumpkin" },
	Legendary = { "Mother Earth", "Inferno" },
	Mythic = { "Tempest", "Mountain", "Void" },
	Secret = { "Eclipse", "Harvest Moon" },
}

-- Spawn odds per zone. Ordered common to rare. Weights are relative.
SpiritData.ZoneWeights = {
	[1] = { { "Common", 85 }, { "Uncommon", 15 } },
	[2] = { { "Uncommon", 70 }, { "Rare", 30 } },
	[3] = { { "Rare", 75 }, { "Epic", 25 } },
	[4] = { { "Epic", 80 }, { "Legendary", 20 } },
	[5] = { { "Legendary", 80 }, { "Mythic", 18 }, { "Secret", 2 } },
}
-- Spirits placed at the start of each round, per zone.
SpiritData.ZoneCounts = { [1] = 24, [2] = 22, [3] = 20, [4] = 16, [5] = 12 }

return SpiritData
