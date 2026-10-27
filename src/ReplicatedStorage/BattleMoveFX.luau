-- BattleMoveFX: the look of each ability, by its fx type ("shot", "burst", "heal", "charge") and the user's element.
-- Client only; everything is made of Parts in code. Scale and pacing take example from the reference game
-- (big, screen-filling hits); the looks are our own per element: Fire flames, Nature leaves, Earth rocks, Wind streaks.
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local M = {}

local WHITE = Color3.new(1, 1, 1)
local ACCENT = {
	Fire = Color3.fromRGB(255, 220, 80),
	Nature = Color3.fromRGB(170, 240, 90),
	Earth = Color3.fromRGB(120, 85, 55),
	Wind = WHITE,
}

local function folder()
	local f = workspace:FindFirstChild("BattleFX")
	if not f then f = Instance.new("Folder"); f.Name = "BattleFX"; f.Parent = workspace end
	return f
end

local function part(size, color, cf, shape, material)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false; p.CastShadow = false
	p.Material = material or Enum.Material.Neon
	p.Size = size; p.Color = color; p.CFrame = cf
	if shape then p.Shape = shape end
	p.Parent = folder()
	return p
end

local function tween(o, t, props, style)
	local tw = TS:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function rnd(a, b) return a + math.random() * (b - a) end
local function spin() return CFrame.Angles(rnd(0, 6), rnd(0, 6), rnd(0, 6)) end

function M.center(m) return (m:GetBoundingBox()).Position end

function M.feet(m)
	local cf, size = m:GetBoundingBox()
	return cf.Position - Vector3.new(0, size.Y / 2, 0)
end

-- a flat ring that spreads across the floor
function M.Ring(pos, color, size, t)
	local r = part(Vector3.new(0.2, 2, 2), color, CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	r.Transparency = 0.15
	tween(r, t or 0.6, { Size = Vector3.new(0.2, size, size), Transparency = 1 })
	Debris:AddItem(r, (t or 0.6) + 0.05)
end

-- one flying piece in the element's own style
local function piece(element, color, pos)
	local accent = ACCENT[element] or WHITE
	local col = (math.random() < 0.55) and color or accent
	if element == "Nature" then
		return part(Vector3.new(rnd(0.9, 1.5), 0.12, rnd(0.5, 0.8)), col, CFrame.new(pos) * spin(), nil, Enum.Material.SmoothPlastic)
	elseif element == "Earth" then
		local s = rnd(0.8, 1.7)
		return part(Vector3.new(s, s * rnd(0.7, 1), s), col, CFrame.new(pos) * spin(), nil, Enum.Material.Slate)
	elseif element == "Wind" then
		return part(Vector3.new(0.18, rnd(2, 3.5), 0.18), col, CFrame.new(pos) * CFrame.Angles(rnd(-0.4, 0.4), rnd(0, 6), rnd(-0.4, 0.4)))
	end
	local s = rnd(0.6, 1.3) -- Fire
	return part(Vector3.new(s, s, s), col, CFrame.new(pos) * spin())
end

-- sparkles that hang in the air for a moment after a hit
function M.Linger(pos, color, count)
	local e = part(Vector3.new(0.5, 0.5, 0.5), WHITE, CFrame.new(pos), nil, Enum.Material.SmoothPlastic)
	e.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(WHITE, color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(1.2, 2.2)
	pe.Speed = NumberRange.new(2, 7)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 2
	pe.LightEmission = 1
	pe.Acceleration = Vector3.new(0, 1.5, 0)
	pe.Parent = e
	pe:Emit(count or 50)
	Debris:AddItem(e, 2.5)
end

-- the user gathers power: a ring at its feet and pieces pulled inward
function M.WindUp(model, element, color, t)
	local f = M.feet(model)
	M.Ring(f, color, 9, t)
	for _ = 1, 10 do
		local ang = rnd(0, math.pi * 2)
		local from = f + Vector3.new(math.cos(ang) * 6, rnd(0.5, 4), math.sin(ang) * 6)
		local p = piece(element, color, from)
		tween(p, t, { CFrame = CFrame.new(M.center(model)) * spin(), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(p, t + 0.05)
	end
end

-- big hit: rings across the floor, a column at the target, pieces erupting all around, lingering sparkles
function M.Eruption(target, element, color, scale)
	scale = scale or 1
	local g = M.feet(target)
	local c = M.center(target)
	for i = 0, 2 do
		task.delay(i * 0.1, function() M.Ring(g, (i == 1) and (ACCENT[element] or WHITE) or color, 34 * scale, 0.7) end)
	end
	local col = part(Vector3.new(1, 3 * scale, 3 * scale), color, CFrame.new(g) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	col.Transparency = 0.45
	tween(col, 0.35, { Size = Vector3.new(26 * scale, 4 * scale, 4 * scale), CFrame = CFrame.new(g + Vector3.new(0, 13 * scale, 0)) * CFrame.Angles(0, 0, math.rad(90)) })
	task.delay(0.25, function() tween(col, 0.4, { Transparency = 1, Size = Vector3.new(28 * scale, 1, 1) }) end)
	Debris:AddItem(col, 0.7)
	for _ = 1, math.floor(34 * scale) do
		local ang = rnd(0, math.pi * 2)
		local rad = rnd(0.5, 6 * scale)
		local start = g + Vector3.new(math.cos(ang) * rad, 0.3, math.sin(ang) * rad)
		local p = piece(element, color, start)
		local up = rnd(6, 16) * scale
		local out = Vector3.new(math.cos(ang), 0, math.sin(ang)) * rnd(1, 5)
		local t = rnd(0.5, 0.9)
		tween(p, t, { CFrame = CFrame.new(start + out + Vector3.new(0, up, 0)) * spin(), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(p, t + 0.05)
	end
	M.Linger(c + Vector3.new(0, 2, 0), color, 70)
end

-- something flies from the user to the target in an arc with a trail; calls onImpact when it lands
function M.Shot(attacker, target, element, color, onImpact)
	local a = M.center(attacker) + Vector3.new(0, 1.5, 0)
	local t = M.center(target)
	local body
	if element == "Earth" then
		body = part(Vector3.new(2.4, 2.1, 2.4), color, CFrame.new(a), nil, Enum.Material.Slate)
	elseif element == "Wind" then
		body = part(Vector3.new(2.6, 2.6, 2.6), Color3.fromRGB(225, 245, 255), CFrame.new(a), Enum.PartType.Ball)
		body.Transparency = 0.25
	else
		body = part(Vector3.new(2.4, 2.4, 2.4), color, CFrame.new(a), Enum.PartType.Ball)
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(ACCENT[element] or WHITE, color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Lifetime = NumberRange.new(0.3, 0.5)
	pe.Rate = 90
	pe.Speed = NumberRange.new(0.5, 2)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.LightEmission = (element == "Earth") and 0 or 1
	pe.Parent = body
	local mid = (a + t) * 0.5 + Vector3.new(0, 7, 0)
	local t0 = os.clock()
	while true do
		local f = math.clamp((os.clock() - t0) / 0.5, 0, 1)
		local pos = (1 - f) ^ 2 * a + 2 * (1 - f) * f * mid + f ^ 2 * t
		body.CFrame = CFrame.new(pos) * CFrame.Angles(f * 9, f * 6, 0)
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	body:Destroy()
	if onImpact then onImpact() end
end

-- a smaller burst where a shot or lunge lands
function M.Impact(target, element, color)
	local c = M.center(target)
	M.Ring(M.feet(target), color, 16, 0.5)
	for _ = 1, 16 do
		local p = piece(element, color, c)
		local dir = Vector3.new(rnd(-1, 1), rnd(0.2, 1), rnd(-1, 1)).Unit
		local t = rnd(0.35, 0.6)
		tween(p, t, { CFrame = CFrame.new(c + dir * rnd(4, 8)) * spin(), Transparency = 1 }, Enum.EasingStyle.Quart)
		Debris:AddItem(p, t + 0.05)
	end
	M.Linger(c, color, 30)
end

-- healing: a green ring, plus signs rising around the spirit
function M.Heal(model)
	local green = Color3.fromRGB(90, 235, 110)
	local f = M.feet(model)
	M.Ring(f, green, 12, 0.7)
	for i = 1, 12 do
		task.delay(i * 0.04, function()
			local ang = rnd(0, math.pi * 2)
			local pos = f + Vector3.new(math.cos(ang) * rnd(1, 3.5), rnd(0.5, 2), math.sin(ang) * rnd(1, 3.5))
			local h = part(Vector3.new(1.1, 0.35, 0.35), green, CFrame.new(pos))
			local v = part(Vector3.new(0.35, 1.1, 0.35), green, CFrame.new(pos))
			for _, p in ipairs({ h, v }) do
				tween(p, 0.9, { CFrame = p.CFrame + Vector3.new(0, rnd(4, 7), 0), Transparency = 1 })
				Debris:AddItem(p, 0.95)
			end
		end)
	end
	M.Linger(M.center(model), green, 35)
end

-- charging: a yellow ring at the feet and a quick flash (the orbiting bolts show the energy itself)
function M.ChargeFlash(model)
	local yellow = Color3.fromRGB(255, 230, 40)
	M.Ring(M.feet(model), yellow, 11, 0.5)
	M.Linger(M.center(model), yellow, 25)
end

return M
