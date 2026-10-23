--!strict
local FX = require(script.Parent:WaitForChild("FX"))
local Cam = require(script.Parent:WaitForChild("BattleCamera"))
local Dialog = require(script.Parent:WaitForChild("BattleDialog"))
local Moves = require(script.Parent:WaitForChild("Moves"))

local Seq = {}

export type Setup = {
	playerPlatform: BasePart,
	enemyPlatform: BasePart,
	avatarRoot: BasePart?,
	energyPillPlayer: GuiObject?,
	energyPillEnemy: GuiObject?,
	coinPill: GuiObject?,
}

local cfg: Setup? = nil
local charges: {[Model]: any} = {}

function Seq.Setup(s: Setup)
	cfg = s
	Cam.Setup(s.playerPlatform, s.enemyPlatform, s.avatarRoot)
end

local function platformTop(p: BasePart): CFrame
	return p.CFrame * CFrame.new(0, p.Size.Y * 0.5, 0)
end

local function placeOn(model: Model, p: BasePart, facing: Vector3)
	local _, size = model:GetBoundingBox()
	local pos = platformTop(p).Position + Vector3.new(0, size.Y * 0.5, 0)
	model:PivotTo(CFrame.lookAt(pos, Vector3.new(facing.X, pos.Y, facing.Z)))
end

function Seq.Entry(wild: Model, line: string)
	assert(cfg, "Seq.Setup first")
	local c = cfg :: Setup
	placeOn(wild, c.enemyPlatform, c.playerPlatform.Position)
	FX.Fade(true, 0.08)
	Cam.Intro()
	FX.Fade(false, 0.12)
	for _, d in wild:GetDescendants() do
		if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then d.Transparency = 0 end
	end
	local old = charges[wild]
	if old then old:Destroy() end
	charges[wild] = FX.Charge(wild, 0)
	Dialog.Say(line)
	Dialog.Hide()
end

function Seq.SendOut(model: Model)
	assert(cfg, "Seq.Setup first")
	local c = cfg :: Setup
	Cam.PlayerCloseup()
	task.wait(0.6)
	Cam.BehindPlayer()
	local at = platformTop(c.playerPlatform)
	local _, size = model:GetBoundingBox()
	local cf = CFrame.lookAt(at.Position + Vector3.new(0, size.Y * 0.5, 0), Vector3.new(c.enemyPlatform.Position.X, at.Position.Y + size.Y * 0.5, c.enemyPlatform.Position.Z))
	FX.SendOut(model, cf)
	task.wait(0.2)
	Cam.Main()
	local h = FX.Charge(model, 0)
	charges[model] = h
	return h
end

export type Action = {
	attacker: Model,
	target: Model,
	move: string,
	damage: number?,
	cost: number?,
	side: string,
	blocked: boolean?,
}

function Seq.Turn(actions: {Action})
	assert(cfg, "Seq.Setup first")
	local c = cfg :: Setup
	Dialog.ClearToasts()
	for _, a in actions do
		local def = Moves[a.move]
		if not def then
			warn("[BattleFXPack] unknown move: " .. tostring(a.move))
			continue
		end
		if a.side == "player" and a.move ~= "Charge" then
			Cam.Punch(-2, 0.8)
		end
		Dialog.Toast(a.attacker.Name .. " used " .. string.upper(a.move) .. "!")
		local pill = (a.side == "player") and c.energyPillPlayer or c.energyPillEnemy
		local cost = a.cost or def.cost
		if cost > 0 then
			if pill then Dialog.EnergyCost(pill, cost) end
			local h = charges[a.attacker]
			if h then h:Consume() end
		end
		if a.blocked then
			Moves.ShieldBreak(a.target)
			task.wait(0.4)
			continue
		end
		def.play({
			attacker = a.attacker,
			target = a.target,
			damage = a.damage,
			charge = charges[a.attacker],
			Cam = Cam,
		})
		task.wait(0.25)
	end
	if c.energyPillPlayer then Dialog.EnergyPop(c.energyPillPlayer, "+1") end
	if c.energyPillEnemy then Dialog.EnergyPop(c.energyPillEnemy, "+1") end
	for _, h in charges do h:Add(1) end
	-- shields last one turn
	for _, a in actions do Moves.ShieldBreak(a.attacker); Moves.ShieldBreak(a.target) end
	task.wait(0.5)
end

function Seq.Faint(dead: Model, line: string, teamRows: {Dialog.TeamRow}?, coinCount: number?, onCoin: ((number) -> ())?)
	assert(cfg, "Seq.Setup first")
	local c = cfg :: Setup
	FX.Faint(dead)
	task.wait(0.4)
	Dialog.Say(line)
	Dialog.Hide()
	if teamRows and #teamRows > 0 then
		Dialog.TeamXP(teamRows)
	end
	local h = charges[dead]
	if h then h:Destroy(); charges[dead] = nil end
	Cam.EnemyPlatform()
	local pos = (dead:GetBoundingBox()).Position
	FX.Vanish(dead)
	if coinCount and coinCount > 0 then
		FX.CoinBurst(pos, coinCount, c.coinPill, onCoin)
	end
	task.wait(0.3)
	Cam.Main()
end

function Seq.Catch(avatar: Model, target: Model, success: boolean, name: string?): boolean
	assert(cfg, "Seq.Setup first")
	Cam.PlayerCloseup()
	task.wait(0.8)
	Cam.Main()
	local box = FX.CatchBox(avatar, target)
	Cam.Zoom(box, 9)
	FX.BoxWobble(box, 3)
	if success then
		FX.StarBurst(box.Position + Vector3.new(0, 1, 0))
		task.wait(0.6)
		Cam.Main()
		Dialog.Say("Let's go!")
		Dialog.Say("We just caught " .. (name or target.Name) .. "!")
		Dialog.Hide()
		box:Destroy()
		local h = charges[target]
		if h then h:Destroy(); charges[target] = nil end
	else
		FX.Puff(box.Position, 1.2)
		box:Destroy()
		for _, d in target:GetDescendants() do
			if d:IsA("BasePart") then d.Transparency = 0 end
		end
		local g = FX.Ghost(target)
		task.wait(0.15)
		g:Destroy()
		Cam.Main()
		Dialog.Say("Oh no, it got out!")
		Dialog.Hide()
	end
	return success
end

function Seq.Swap(old: Model, new: Model)
	Cam.BehindPlayer()
	local h = charges[old]
	if h then h:Destroy(); charges[old] = nil end
	FX.Recall(old)
	task.wait(0.2)
	return Seq.SendOut(new)
end

function Seq.Exit()
	FX.Fade(true, 0.5)
	for _, h in charges do h:Destroy() end
	table.clear(charges)
	Dialog.ClearToasts()
	Dialog.Hide()
	Cam.Release()
	FX.Cleanup()
	FX.Fade(false, 0.5)
end

return Seq
