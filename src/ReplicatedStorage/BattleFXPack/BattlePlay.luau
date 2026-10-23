--!strict
-- BattleFXPack.BattlePlay : controllable battle loop vs a bot, client-side, using the pack's presentation.
-- Rules live in Play.Rules. For a live game the same loop runs with the server deciding outcomes.
local Seq = require(script.Parent:WaitForChild("Sequencer"))
local Menu = require(script.Parent:WaitForChild("BattleMenu"))
local Dialog = require(script.Parent:WaitForChild("BattleDialog"))
local Moves = require(script.Parent:WaitForChild("Moves"))
local FX = require(script.Parent:WaitForChild("FX"))

local Play = {}

Play.Rules = {
	MaxEnergy = 10,
	StartEnergy = 1,
	EnergyPerTurn = 1,
	ChargeGain = 2,
	Damage = {Charge = 0, Splash = 27, Bite = 17, Firework = 53, Shoot = 12, Sword = 20, Bomb = 30, Shield = 0},
	Cost = {},
	CatchBase = 0.10,
	CatchMax = 0.85,
	CoinsPerLevel = 2,
	BotChargeBelow = 3,
}

export type Fighter = {model: Model, name: string, level: number, hp: number, maxHp: number, moves: {string}, energy: number?, shield: boolean?}

export type Config = {
	playerPlatform: BasePart,
	enemyPlatform: BasePart,
	avatar: Model,
	team: {Fighter},
	wild: Fighter,
	items: {{name: string, count: number}},
	coins: number?,
	onCoins: ((number) -> ())?,
}

local R = Play.Rules

local function cost(name: string): number
	if R.Cost[name] then return R.Cost[name] end
	local m = Moves[name]
	return m and m.cost or 0
end

local function damage(name: string): number
	return R.Damage[name] or 0
end

local function catchChance(f: Fighter): number
	local hpFrac = math.clamp(f.hp / math.max(1, f.maxHp), 0, 1)
	return R.CatchBase + (R.CatchMax - R.CatchBase) * (1 - hpFrac)
end

local function sync(side: string, f: Fighter)
	Menu.SetSide(side, {name = f.name, level = f.level, hp = f.hp, maxHp = f.maxHp, energy = f.energy})
end

local function botPick(bot: Fighter, foe: Fighter): string
	local best: string? = nil
	local bestDmg = -1
	for _, m in bot.moves do
		local c = cost(m)
		local d = damage(m)
		if c <= (bot.energy or 0) and d > bestDmg and m ~= "Charge" and m ~= "Shield" then
			best = m; bestDmg = d
		end
	end
	if best and bestDmg >= foe.hp then return best end
	if (bot.energy or 0) < R.BotChargeBelow and table.find(bot.moves, "Charge") then return "Charge" end
	if best and math.random() < 0.8 then return best end
	if table.find(bot.moves, "Charge") then return "Charge" end
	return bot.moves[1]
end

local function resolve(attacker: Fighter, target: Fighter, move: string, side: string)
	local c = cost(move)
	attacker.energy = math.max(0, (attacker.energy or 0) - c)
	local action: Seq.Action = {attacker = attacker.model, target = target.model, move = move, cost = c, side = side}
	if move == "Charge" then
		attacker.energy = math.min(R.MaxEnergy, (attacker.energy or 0) + R.ChargeGain)
	elseif move == "Shield" then
		attacker.shield = true
	else
		local d = damage(move)
		if d > 0 and target.shield then
			action.blocked = true
			target.shield = false
		elseif d > 0 then
			target.hp = math.max(0, target.hp - d)
			action.damage = d
		end
	end
	return action
end

function Play.Run(cfg: Config): string
	local coins = cfg.coins or 0
	local me = cfg.team[1]
	local wild = cfg.wild
	for _, f in cfg.team do f.energy = f.energy or R.StartEnergy; f.shield = false end
	wild.energy = wild.energy or R.StartEnergy
	wild.shield = false

	local ep, ee, coinPill = Menu.Pills()
	Seq.Setup({
		playerPlatform = cfg.playerPlatform,
		enemyPlatform = cfg.enemyPlatform,
		avatarRoot = cfg.avatar:FindFirstChild("HumanoidRootPart") :: BasePart?,
		energyPillPlayer = ep,
		energyPillEnemy = ee,
		coinPill = coinPill,
	})

	Menu.Hide()
	Seq.Entry(wild.model, "A wild " .. wild.name .. " has appeared!")
	Seq.SendOut(me.model)
	Menu.Show()
	Menu.SetCoins(coins)
	sync("enemy", wild)
	sync("player", me)

	local result: string? = nil

	local function endOfTurn()
		me.energy = math.min(R.MaxEnergy, (me.energy or 0) + R.EnergyPerTurn)
		wild.energy = math.min(R.MaxEnergy, (wild.energy or 0) + R.EnergyPerTurn)
		me.shield = false
		wild.shield = false
		sync("enemy", wild)
		sync("player", me)
	end

	local function playerFainted(): boolean
		Menu.Hide()
		FX.Faint(me.model)
		Dialog.Say(me.name .. " fainted!")
		Dialog.Hide()
		local alive = {}
		for i, f in cfg.team do if f.hp > 0 then table.insert(alive, i) end end
		if #alive == 0 then return true end
		Menu.Show()
		local slots = {}
		for _, f in cfg.team do table.insert(slots, {name = f.name, level = f.level, hp = f.hp, maxHp = f.maxHp, active = f == me}) end
		local pick: number? = nil
		while not pick do
			pick = Menu.TeamPage(slots)
			if pick and cfg.team[pick].hp <= 0 then pick = nil end
		end
		Menu.Hide()
		local old = me
		me = cfg.team[pick :: number]
		for _, d in old.model:GetDescendants() do if d:IsA("BasePart") then d.Transparency = 1 end end
		Seq.SendOut(me.model)
		Menu.Show()
		sync("player", me)
		return false
	end

	while not result do
		Menu.Show()
		local choice = Menu.MainMenu()

		if choice == "Fight" then
			local infos = {}
			for _, m in me.moves do table.insert(infos, {name = m, cost = cost(m), kind = Moves[m] and Moves[m].kind or nil}) end
			local mv = Menu.MovePage(infos, me.energy or 0)
			if mv then
				Menu.Hide()
				local a1 = resolve(me, wild, mv, "player")
				local actions = {a1}
				if wild.hp > 0 then
					local bm = botPick(wild, me)
					table.insert(actions, resolve(wild, me, bm, "enemy"))
				end
				Menu.Show()
				Seq.Turn(actions)
				endOfTurn()
				if wild.hp <= 0 then
					Menu.Hide()
					local drop = math.max(1, wild.level * R.CoinsPerLevel)
					local n = math.min(drop, 12)
					Seq.Faint(wild.model, wild.name .. " died!", nil, n, function()
						coins += math.ceil(drop / n)
						if cfg.onCoins then cfg.onCoins(coins) end
						Menu.SetCoins(coins)
					end)
					Dialog.Say("Nice kill!")
					Dialog.Hide()
					result = "win"
				elseif me.hp <= 0 then
					if playerFainted() then result = "lose" end
				end
			end

		elseif choice == "Bag" then
			local items = {}
			for _, it in cfg.items do table.insert(items, {name = it.name, count = it.count, catchChance = catchChance(wild)}) end
			local item = Menu.BagPage(items)
			if item then
				for _, it in cfg.items do if it.name == item then it.count -= 1 end end
				Menu.Hide()
				local ok = math.random() < catchChance(wild)
				Seq.Catch(cfg.avatar, wild.model, ok, wild.name)
				if ok then
					result = "catch"
				else
					Menu.Show()
					local bm = botPick(wild, me)
					Seq.Turn({resolve(wild, me, bm, "enemy")})
					endOfTurn()
					if me.hp <= 0 and playerFainted() then result = "lose" end
				end
			end

		elseif choice == "Team" then
			local slots = {}
			for _, f in cfg.team do table.insert(slots, {name = f.name, level = f.level, hp = f.hp, maxHp = f.maxHp, active = f == me}) end
			local pick = Menu.TeamPage(slots)
			if pick and cfg.team[pick] ~= me and cfg.team[pick].hp > 0 then
				Menu.Hide()
				local old = me
				me = cfg.team[pick]
				Seq.Swap(old.model, me.model)
				Menu.Show()
				sync("player", me)
				local bm = botPick(wild, me)
				Seq.Turn({resolve(wild, me, bm, "enemy")})
				endOfTurn()
				if me.hp <= 0 and playerFainted() then result = "lose" end
			end

		elseif choice == "Run" then
			Menu.Hide()
			Dialog.Say("Got away safely!")
			Dialog.Hide()
			result = "run"
		end
	end

	Menu.Hide()
	Seq.Exit()
	return result :: string
end

return Play
