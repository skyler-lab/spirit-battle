-- BattleData: the one battle rule set. Every battle uses these rules; spirits differ by element, health and their own abilities.
-- All numbers here are PLACEHOLDERS to be tuned in playtests.
local D = {}

D.MaxEnergy = 10
D.StartEnergy = 1
D.TurnEnergy = 1 -- free energy each side gets at the end of every turn

-- kind: attack deals power x element multiplier. heal restores health. block cancels one incoming attack and refunds
-- its own cost when it blocks. charge is free and gives energy.
-- fx tells the client which effect to play: "lunge" (dash in and hit), "shot" (something flies over), "burst" (big hit
-- that erupts around the target), "heal", "block", "charge". The look also follows the user's element.
D.Moves = {
	Charge = { name = "Charge", cost = 0, gain = 2, kind = "charge", fx = "charge" },
	-- Wood (Nature)
	VineWhip = { name = "Vine Whip", cost = 2, power = 18, kind = "attack", fx = "lunge" },
	Regrow = { name = "Regrow", cost = 3, heal = 25, kind = "heal", fx = "heal" },
	LeafStorm = { name = "Leaf Storm", cost = 5, power = 45, kind = "attack", fx = "burst" },
	-- Ember (Fire)
	Fireball = { name = "Fireball", cost = 2, power = 18, kind = "attack", fx = "shot" },
	FlameGuard = { name = "Flame Guard", cost = 1, kind = "block", fx = "block" },
	Inferno = { name = "Inferno", cost = 5, power = 45, kind = "attack", fx = "burst" },
	-- Pebble (Earth)
	RockThrow = { name = "Rock Throw", cost = 2, power = 18, kind = "attack", fx = "shot" },
	StoneWall = { name = "Stone Wall", cost = 1, kind = "block", fx = "block" },
	Quake = { name = "Quake", cost = 5, power = 45, kind = "attack", fx = "burst" },
	-- Breeze (Wind)
	Gust = { name = "Gust", cost = 1, power = 12, kind = "attack", fx = "lunge" },
	Twister = { name = "Twister", cost = 3, power = 28, kind = "attack", fx = "shot" },
	Tempest = { name = "Tempest", cost = 5, power = 45, kind = "attack", fx = "burst" },
	-- the old shared moves (2026-10-23 to 2026-10-27); no spirit uses them now
	Strike = { name = "Strike", cost = 2, power = 20, kind = "attack", fx = "lunge" },
	Blast = { name = "Blast", cost = 5, power = 45, kind = "attack", fx = "burst" },
	Block = { name = "Block", cost = 1, kind = "block", fx = "block" },
}

-- Test roster (battle stats only). Every spirit also has Charge. Water is reserved for when a water spirit exists.
D.Spirits = {
	Wood = { element = "Nature", hp = 100, moves = { "VineWhip", "Regrow", "LeafStorm" } },
	Ember = { element = "Fire", hp = 90, moves = { "Fireball", "FlameGuard", "Inferno" } },
	Pebble = { element = "Earth", hp = 120, moves = { "RockThrow", "StoneWall", "Quake" } },
	Breeze = { element = "Wind", hp = 85, moves = { "Gust", "Twister", "Tempest" } },
}

-- the 4 moves on a spirit's FIGHT page: Charge first, then its own 3
function D.movesFor(name)
	local s = D.Spirits[name]
	local list = { "Charge" }
	if s then for _, id in ipairs(s.moves) do table.insert(list, id) end end
	return list
end

function D.canUse(name, id)
	return table.find(D.movesFor(name), id) ~= nil
end

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

-- seconds each event takes to play (server and client both use D.eventTime so they stay in step).
-- The "used X!" line is short because the move's effect starts right with it (like the reference game).
D.EventTime = { say = 0.2, hit = 1.0, heal = 1.0, blocked = 1.0, en = 0.2, reject = 0.4, ["end"] = 0.4, tame = 0.9 }
D.FxTime = { charge = 0.9, block = 0.7 }
D.HitTime = { lunge = 1.0, shot = 1.3, burst = 1.9 } -- by the move's fx
D.EndTime = { win = 2.4, lose = 1.8, tame = 1.2, run = 0.4 }
D.TameTime = { ok = 4.4, fail = 4.0 }

function D.eventTime(e)
	if e.k == "fx" then return D.FxTime[e.type] or 0.45 end
	if e.k == "hit" or e.k == "blocked" then
		local m = e.move and D.Moves[e.move]
		return (m and D.HitTime[m.fx]) or D.EventTime[e.k]
	end
	if e.k == "end" then return D.EndTime[e.result] or D.EventTime["end"] end
	if e.k == "tame" then return e.ok and D.TameTime.ok or D.TameTime.fail end
	return D.EventTime[e.k] or 0.3
end

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
