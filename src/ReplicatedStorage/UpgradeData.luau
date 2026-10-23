-- UpgradeData: everything players can buy with cash. ALL PRICES ARE 0 ON PURPOSE (placeholder, free while testing).
-- The owner sets real prices later by editing the numbers below. Amounts per level are also placeholders.
local U = {}

U.START = { Health = 100, Bag = 3, Slots = 6 }

-- prices[n] = cost of reaching level n. attr = the player attribute that stores the level.
U.Tracks = {
	{ id = "Health", name = "Max health", attr = "UpHealth", maxLevel = 5, perLevel = 25,   prices = { 0, 0, 0, 0, 0 } },
	{ id = "Bag",    name = "Follower limit", attr = "UpBag", maxLevel = 5, perLevel = 1,    prices = { 0, 0, 0, 0, 0 } },
	{ id = "Slots",  name = "Plot slots", attr = "UpSlots", maxLevel = 3, perLevel = 1,      prices = { 0, 0, 0 } },
	{ id = "Income", name = "Base income", attr = "UpIncome", maxLevel = 5, perLevel = 0.20, prices = { 0, 0, 0, 0, 0 } },
}
U.ById = {}
for _, t in ipairs(U.Tracks) do U.ById[t.id] = t end

-- coin price per coil id (0 = free while testing)
U.CoilPrices = { Chocolate = 0, Red = 0, Gold = 0, Rainbow = 0 }

-- one-use items bought in the shop. Shield = no storm damage for "seconds". max = most you can carry.
U.Items = {
	Shield = { name = "Storm shield", price = 0, max = 5, seconds = 10, attr = "Shields" },
}

return U
