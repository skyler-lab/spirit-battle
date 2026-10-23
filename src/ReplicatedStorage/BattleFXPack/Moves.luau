--!strict
-- Verified against footage: Charge, Splash, Bite, Firework. Unverified (same ingredients): Shoot, Sword, Bomb, Shield.
local FX = require(script.Parent:WaitForChild("FX"))

export type Ctx = { attacker: Model, target: Model, damage: number?, charge: any?, Cam: any? }

local Moves: {[string]: {cost: number, kind: string, play: (Ctx) -> ()}} = {}

local function center(m: Model): Vector3
	return (m:GetBoundingBox()).Position
end

local function hit(ctx: Ctx)
	if ctx.damage and ctx.damage > 0 then
		FX.DamageNumber(ctx.target, ctx.damage)
	end
end

Moves.Charge = {cost = 0, kind = "buff", play = function(ctx)
	if ctx.charge then ctx.charge:Add(1) end
	task.wait(0.6)
end}

Moves.Splash = {cost = 2, kind = "ranged", play = function(ctx)
	task.delay(0.3, function() hit(ctx) end)
	FX.Splash(ctx.target)
end}

Moves.Bite = {cost = 3, kind = "melee", play = function(ctx)
	task.delay(0.9, function() hit(ctx) end)
	FX.Bite(ctx.attacker, ctx.target)
end}

Moves.Firework = {cost = 4, kind = "ranged", play = function(ctx)
	task.delay(1.05, function()
		hit(ctx)
		if ctx.Cam then ctx.Cam.Punch(6, 0.5) end
	end)
	FX.Firework(ctx.attacker, ctx.target)
end}

Moves.Shoot = {cost = 2, kind = "ranged", play = function(ctx)
	local a = center(ctx.attacker)
	local t = center(ctx.target)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 232, 0)
	p.Size = Vector3.new(0.4, 0.4, 2.2)
	p.CFrame = CFrame.lookAt(a, t)
	p.Parent = workspace:FindFirstChild("BattleFX") or workspace
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 0.35, 0, 1)
		p.CFrame = CFrame.lookAt(a:Lerp(t, f), t)
		if f >= 1 then break end
		game:GetService("RunService").RenderStepped:Wait()
	end
	p:Destroy()
	FX.Starburst(t, 0.6)
	FX.HitFlash(ctx.target)
	hit(ctx)
	task.wait(0.6)
end}

Moves.Sword = {cost = 3, kind = "melee", play = function(ctx)
	local RunService = game:GetService("RunService")
	local start = ctx.attacker:GetPivot()
	local t = center(ctx.target)
	local dir = (Vector3.new(t.X, start.Position.Y, t.Z) - start.Position).Unit
	local lunge = start + dir * 4
	local t0 = os.clock()
	while os.clock() - t0 < 0.18 do
		local f = (os.clock() - t0) / 0.18
		ctx.attacker:PivotTo(start:Lerp(lunge, f))
		RunService.RenderStepped:Wait()
	end
	for i = -1, 1 do
		local w = Instance.new("WedgePart")
		w.Anchored = true; w.CanCollide = false; w.CastShadow = false
		w.Material = Enum.Material.Neon; w.Color = Color3.new(1, 1, 1)
		w.Size = Vector3.new(0.3, 5, 1.2)
		w.CFrame = CFrame.new(t) * CFrame.Angles(0, 0, math.rad(35 * i + 20))
		w.Parent = workspace:FindFirstChild("BattleFX") or workspace
		game:GetService("TweenService"):Create(w, TweenInfo.new(0.3), {Transparency = 1, Size = Vector3.new(0.05, 7, 0.2)}):Play()
		game:GetService("Debris"):AddItem(w, 0.35)
	end
	FX.HitFlash(ctx.target)
	hit(ctx)
	task.wait(0.2)
	t0 = os.clock()
	while os.clock() - t0 < 0.25 do
		local f = (os.clock() - t0) / 0.25
		ctx.attacker:PivotTo(lunge:Lerp(start, f))
		RunService.RenderStepped:Wait()
	end
	ctx.attacker:PivotTo(start)
	task.wait(0.3)
end}

Moves.Bomb = {cost = 5, kind = "ranged", play = function(ctx)
	local a = center(ctx.attacker)
	local t = center(ctx.target)
	local b = Instance.new("Part")
	b.Anchored = true; b.CanCollide = false; b.CastShadow = false
	b.Shape = Enum.PartType.Ball
	b.Material = Enum.Material.SmoothPlastic
	b.Color = Color3.fromRGB(40, 40, 50)
	b.Size = Vector3.new(1.4, 1.4, 1.4)
	b.Parent = workspace:FindFirstChild("BattleFX") or workspace
	local mid = (a + t) * 0.5 + Vector3.new(0, 8, 0)
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 0.9, 0, 1)
		b.Position = (1 - f) ^ 2 * a + 2 * (1 - f) * f * mid + f ^ 2 * t
		if f >= 1 then break end
		game:GetService("RunService").RenderStepped:Wait()
	end
	b:Destroy()
	FX.Starburst(t, 1.6)
	FX.ScreenFlash(0.5)
	FX.HitFlash(ctx.target, 0.3)
	if ctx.Cam then ctx.Cam.Punch(8, 0.5) end
	hit(ctx)
	FX.SparkleRain(t, 1.2)
	task.wait(1.0)
end}

Moves.Shield = {cost = 1, kind = "defend", play = function(ctx)
	local c = center(ctx.attacker)
	local _, size = ctx.attacker:GetBoundingBox()
	local r = math.max(size.X, size.Y, size.Z) * 0.9
	local s = Instance.new("Part")
	s.Name = "ShieldBubble"
	s.Anchored = true; s.CanCollide = false; s.CastShadow = false
	s.Shape = Enum.PartType.Ball
	s.Material = Enum.Material.ForceField
	s.Color = Color3.fromRGB(80, 220, 255)
	s.Size = Vector3.new(0.2, 0.2, 0.2)
	s.CFrame = CFrame.new(c)
	s.Parent = workspace:FindFirstChild("BattleFX") or workspace
	ctx.attacker:SetAttribute("ShieldBubble", true)
	s:SetAttribute("Owner", ctx.attacker.Name)
	game:GetService("TweenService"):Create(s, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = Vector3.new(r, r, r)}):Play()
	task.wait(0.8)
end}

function Moves.ShieldBreak(model: Model)
	local f = workspace:FindFirstChild("BattleFX")
	if not f then return end
	for _, p in f:GetChildren() do
		if p.Name == "ShieldBubble" and p:GetAttribute("Owner") == model.Name then
			game:GetService("TweenService"):Create(p, TweenInfo.new(0.2), {Size = p.Size * 1.3, Transparency = 1}):Play()
			game:GetService("Debris"):AddItem(p, 0.25)
		end
	end
	model:SetAttribute("ShieldBubble", nil)
end

return Moves
