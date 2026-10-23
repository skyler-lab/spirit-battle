-- BattleData: the one battle rule set. Every battle uses these numbers; only spirits and their elements differ.
-- All numbers here are PLACEHOLDERS to be tuned in playtests.
local D = {}

D.MaxEnergy = 10
D.StartEnergy = 1
D.TurnEnergy = 1 -- free energy each side gets at the end of every turn

-- kind: attack deals power x element multiplier. block cancels one incoming attack and refunds its own cost.
-- charge is free and gives energy.
D.Moves = {
	Charge = { name = "Charge", cost = 0, gain = 2, kind = "charge" },
	Strike = { name = "Strike", cost = 2, power = 20, kind = "attack" },
	Blast = { name = "Blast", cost = 5, power = 45, kind = "attack" },
	Block = { name = "Block", cost = 1, kind = "block" },
}
D.MoveOrder = { "Charge", "Strike", "Blast", "Block" }

-- Test roster (battle stats only). Water is reserved for when a water spirit exists.
D.Spirits = {
	Wood = { element = "Nature", hp = 100 },
	Ember = { element = "Fire", hp = 100 },
	Pebble = { element = "Earth", hp = 100 },
	Breeze = { element = "Wind", hp = 100 },
}

-- Strong[attackerElement] = elements it beats
D.Strong = {
	Fire = { "Nature" },
	Nature = { "Earth" },
	Earth = { "Wind" },
	Wind = { "Fire" },
	Water = { "Fire" },
}
D.StrongMult = 1.5
D.WeakMult = 0.5

D.ElementColor = {
	Fire = Color3.fromRGB(255, 120, 40), Nature = Color3.fromRGB(90, 200, 90), Earth = Color3.fromRGB(170, 125, 70),
	Wind = Color3.fromRGB(190, 230, 255), Water = Color3.fromRGB(70, 150, 255),
}

-- seconds each event type takes to play (server and client both use this so they stay in step)
D.EventTime = { say = 1.3, fx = 0.9, hit = 1.0, blocked = 0.9, en = 0.35, reject = 0.4, ["end"] = 0.4, tame = 1.4 }

-- Taming (PLACEHOLDERS). TAME only works when the wild spirit's health is at or below Threshold (fraction of max).
-- Chance scales linearly from ChanceAtThreshold (at exactly Threshold) up to ChanceAtZero (as health nears 0).
-- A failed try uses your turn: the wild spirit still makes its move.
D.Tame = {
	Threshold = 0.30,
	ChanceAtThreshold = 0.25,
	ChanceAtZero = 0.90,
	MaxOwned = 60, -- cap on the saved owned-spirits list
}

-- 0 when the wild spirit is too healthy to tame, otherwise the success chance (0 to 1)
function D.tameChance(hp, maxHp)
	if not hp or not maxHp or maxHp <= 0 or hp <= 0 then return 0 end
	local frac = hp / maxHp
	if frac > D.Tame.Threshold then return 0 end
	local t = math.clamp(frac / D.Tame.Threshold, 0, 1)
	return D.Tame.ChanceAtZero + (D.Tame.ChanceAtThreshold - D.Tame.ChanceAtZero) * t
end

function D.multiplier(attEl, defEl)
	local s = D.Strong[attEl]
	if s and table.find(s, defEl) then return D.StrongMult end
	local t = D.Strong[defEl]
	if t and table.find(t, attEl) then return D.WeakMult end
	return 1
end

return D
