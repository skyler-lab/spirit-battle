--!strict
-- BattleFXPack.FX : client-side battle effects built from Parts in code.
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local FX = {}

local function folder(): Folder
	local f = Workspace:FindFirstChild("BattleFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "BattleFX"
		f.Parent = Workspace
	end
	return f :: Folder
end

local function modelCenter(model: Model): Vector3
	local cf, _ = model:GetBoundingBox()
	return cf.Position
end

local function modelHeight(model: Model): number
	local _, size = model:GetBoundingBox()
	return size.Y
end

local function part(size: Vector3, color: Color3, material: Enum.Material?, cf: CFrame?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.Neon
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if cf then p.CFrame = cf end
	p.Parent = folder()
	return p
end

local function wedge(size: Vector3, color: Color3, cf: CFrame): WedgePart
	local w = Instance.new("WedgePart")
	w.Anchored = true
	w.CanCollide = false
	w.CanQuery = false
	w.CanTouch = false
	w.CastShadow = false
	w.Size = size
	w.Color = color
	w.Material = Enum.Material.Neon
	w.CFrame = cf
	w.Parent = folder()
	return w
end

local function tween(obj: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function bezier(p0: Vector3, p1: Vector3, p2: Vector3, a: number): Vector3
	return (1 - a) ^ 2 * p0 + 2 * (1 - a) * a * p1 + a ^ 2 * p2
end

local function arcTo(obj: Instance, from: Vector3, to: Vector3, peak: number, t: number, faceTarget: boolean)
	local mid = (from + to) * 0.5 + Vector3.new(0, peak, 0)
	local start = os.clock()
	local last = from
	while true do
		local a = math.clamp((os.clock() - start) / t, 0, 1)
		local pos = bezier(from, mid, to, a)
		local cf
		if faceTarget then
			local look = (pos - last)
			if look.Magnitude < 0.01 then look = (to - from) end
			cf = CFrame.lookAt(pos, pos + look)
		else
			cf = CFrame.new(pos)
		end
		if obj:IsA("Model") then
			obj:PivotTo(cf)
		else
			(obj :: BasePart).CFrame = cf
		end
		last = pos
		if a >= 1 then break end
		RunService.RenderStepped:Wait()
	end
end

local YELLOW = Color3.fromRGB(255, 232, 0)
local CYAN = Color3.fromRGB(70, 240, 255)
local RED = Color3.fromRGB(255, 40, 40)
local WHITE = Color3.new(1, 1, 1)
local PINK = Color3.fromRGB(255, 150, 170)
local MAGENTA = Color3.fromRGB(255, 60, 220)

-- bolts
local function buildBolt(scale: number): Model
	-- flat zigzag: 5 slanted slabs stepping down, alternating lean, like a classic cartoon bolt
	local m = Instance.new("Model")
	m.Name = "Bolt"
	local segs = {
		{ 0.55,  1.6, -28, Vector3.new(0.7, 1.3, 0.22)},
		{-0.25,  0.6,  28, Vector3.new(0.7, 1.3, 0.22)},
		{ 0.45, -0.4, -28, Vector3.new(0.7, 1.3, 0.22)},
		{-0.30, -1.4,  28, Vector3.new(0.7, 1.3, 0.22)},
		{ 0.25, -2.3, -35, Vector3.new(0.5, 1.0, 0.22)},
	}
	for _, d in segs do
		local p = part(d[4] * scale, YELLOW)
		p.CFrame = CFrame.new(d[1] * scale, d[2] * scale, 0) * CFrame.Angles(0, 0, math.rad(d[3]))
		p.Parent = m
	end
	m.PrimaryPart = m:FindFirstChildWhichIsA("BasePart")
	m.Parent = folder()
	return m
end

function FX.Charge(model: Model, count: number)
	local handle = {}
	local bolts: {Model} = {}
	local alive = true
	local conn: RBXScriptConnection? = nil

	local function spawnBolt()
		local b = buildBolt(1)
		b:ScaleTo(0.05)
		table.insert(bolts, b)
		task.spawn(function()
			for k = 1, 6 do b:ScaleTo(0.05 + (1.2 - 0.05) * k / 6); task.wait(0.025) end
			for k = 1, 4 do b:ScaleTo(1.2 - 0.2 * k / 4); task.wait(0.025) end
		end)
	end

	for _ = 1, count do spawnBolt() end

	local t0 = os.clock()
	conn = RunService.RenderStepped:Connect(function()
		if not alive or not model.Parent then return end
		local c = modelCenter(model)
		local h = modelHeight(model)
		local n = #bolts
		for i, b in bolts do
			local ang = (os.clock() - t0) * math.pi * 1.0 + (i / n) * math.pi * 2
			local r = 2.8 + h * 0.2
			local bob = math.sin((os.clock() - t0) * 3 + i) * 0.4
			local pos = c + Vector3.new(math.cos(ang) * r, h * 0.25 + bob, math.sin(ang) * r)
			local camPos = Workspace.CurrentCamera.CFrame.Position
			b:PivotTo(CFrame.lookAt(pos, Vector3.new(camPos.X, pos.Y, camPos.Z)))
		end
	end)

	function handle.Add(_, n: number)
		for _ = 1, n do spawnBolt() end
	end

	function handle.Consume(_)
		alive = false
		for _, b in bolts do
			task.spawn(function()
				local start = b:GetPivot()
				for k = 1, 9 do
					b:PivotTo(start * CFrame.new(0, k * 0.9, 0) * CFrame.Angles(0, 0, k * 0.3))
					b:ScaleTo(math.max(0.05, 1 - k / 9))
					task.wait(1 / 30)
				end
				b:Destroy()
			end)
		end
		table.clear(bolts)
		task.wait(0.3)
		alive = true
	end

	function handle.Destroy(_)
		alive = false
		if conn then conn:Disconnect() end
		for _, b in bolts do b:Destroy() end
		table.clear(bolts)
	end

	return handle
end

function FX.HitFlash(model: Model, t: number?)
	t = t or 0.25
	local saved = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			saved[d] = {d.Color, d.Material}
			d.Color = RED
			d.Material = Enum.Material.Neon
		end
	end
	task.delay(t, function()
		for p, s in saved do
			if p.Parent then
				p.Color = s[1]
				p.Material = s[2]
			end
		end
	end)
end

function FX.DamageNumber(model: Model, amount: number, color: Color3?)
	local c = modelCenter(model)
	local h = modelHeight(model)
	local anchor = part(Vector3.new(0.1, 0.1, 0.1), WHITE, Enum.Material.SmoothPlastic, CFrame.new(c + Vector3.new(0, h * 0.7, 0)))
	anchor.Transparency = 1
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(6, 2)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Parent = anchor
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.Arcade
	lbl.TextScaled = true
	lbl.TextColor3 = color or RED
	lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
	lbl.TextStrokeTransparency = 0.2
	lbl.Text = (amount >= 0 and "-" or "+") .. tostring(math.abs(amount))
	lbl.Parent = bb
	bb.Size = UDim2.fromScale(7.8, 2.6)
	tween(bb, 0.15, {Size = UDim2.fromScale(6, 2)})
	tween(anchor, 1.0, {CFrame = anchor.CFrame + Vector3.new(0, 2, 0)}, Enum.EasingStyle.Sine)
	task.delay(0.5, function()
		tween(lbl, 0.5, {TextTransparency = 1, TextStrokeTransparency = 1})
	end)
	Debris:AddItem(anchor, 1.1)
end

-- Splash
function FX.Splash(target: Model)
	local c = modelCenter(target)
	local h = modelHeight(target)
	local base = c - Vector3.new(0, h * 0.5, 0)
	FX.HitFlash(target, 0.25)
	-- fountain: 18 flat cyan slabs erupt in a 130 degree fan, scatter outward and up, then fade
	local petals = {}
	for i = 1, 18 do
		local ang = math.rad(-65 + (i - 1) * (130 / 17))
		local p = part(Vector3.new(1.1, 3.2, 0.25), CYAN)
		p.CFrame = CFrame.new(base + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, ang)
		table.insert(petals, {p, ang, 0.8 + math.random() * 0.4})
	end
	task.spawn(function()
		local start = os.clock()
		local camLook = Workspace.CurrentCamera.CFrame.LookVector
		local yaw = math.atan2(-camLook.X, -camLook.Z)
		while os.clock() - start < 1.3 do
			local a = (os.clock() - start) / 1.3
			for _, d in petals do
				local p, ang, k = d[1], d[2], d[3]
				local r = a * 13 * k
				local y = 1 + math.sin(a * math.pi) * 9 * k
				local off = CFrame.Angles(0, yaw, 0) * Vector3.new(math.sin(ang) * r, y, 0)
				p.CFrame = CFrame.new(base + off) * CFrame.Angles(0, yaw, ang + a * 0.5)
				p.Transparency = a > 0.55 and (a - 0.55) / 0.45 or 0
			end
			RunService.RenderStepped:Wait()
		end
		for _, d in petals do d[1]:Destroy() end
	end)

	-- ground rings: 14 cyan ring outlines (each 10 small blocks) spread around the platform and grow
	task.delay(0.25, function()
		for _ = 1, 14 do
			local ang = math.random() * math.pi * 2
			local dist = 2 + math.random() * 11
			local pos = base + Vector3.new(math.cos(ang) * dist, 0.15, math.sin(ang) * dist)
			local pieces = {}
			for k = 1, 10 do
				local b = part(Vector3.new(0.5, 0.12, 0.25), CYAN)
				b.Transparency = 0.1
				table.insert(pieces, b)
			end
			local r0 = 0.6 + math.random() * 0.8
			local r1 = r0 * 2.6
			task.spawn(function()
				local st = os.clock()
				while os.clock() - st < 1.2 do
					local f = (os.clock() - st) / 1.2
					local r = r0 + (r1 - r0) * math.sin(f * math.pi * 0.5)
					for k, b in pieces do
						local th = (k / 10) * math.pi * 2
						local pk = pos + Vector3.new(math.cos(th) * r, 0, math.sin(th) * r)
						b.CFrame = CFrame.lookAt(pk, pk + Vector3.new(-math.sin(th), 0, math.cos(th)))
						b.Size = Vector3.new(0.25, 0.12, r * 0.65)
						b.Transparency = 0.1 + f * 0.9
					end
					RunService.RenderStepped:Wait()
				end
				for _, b in pieces do b:Destroy() end
			end)
			task.wait(0.04)
		end
	end)

	task.delay(0.2, function()
		for _ = 1, 24 do
			local pos = base + Vector3.new((math.random() - 0.5) * 24, 10 + math.random() * 6, (math.random() - 0.5) * 24)
			local s = part(Vector3.new(0.12, 2.5 + math.random() * 2, 0.12), CYAN, nil, CFrame.new(pos))
			s.Transparency = 0.1
			tween(s, 0.6 + math.random() * 0.4, {CFrame = s.CFrame - Vector3.new(0, 14, 0), Transparency = 1}, Enum.EasingStyle.Linear)
			Debris:AddItem(s, 1.1)
			task.wait(0.03)
		end
	end)
	task.wait(2.0)
end

-- Bite
local function buildJaw(): (Model, Model, Model)
	-- Flat cartoon jaw that faces the camera: two gum bars with 6 isoceles teeth each (mirrored wedge pairs).
	local jaw = Instance.new("Model")
	jaw.Name = "Jaw"
	local upper = Instance.new("Model"); upper.Name = "Upper"; upper.Parent = jaw
	local lower = Instance.new("Model"); lower.Name = "Lower"; lower.Parent = jaw
	local pivot = part(Vector3.new(0.2, 0.2, 0.2), WHITE)
	pivot.Transparency = 1
	pivot.Parent = jaw
	jaw.PrimaryPart = pivot
	local TW, TH, TZ = 1.7, 2.3, 0.7
	local function tooth(parentModel: Model, x: number, y: number, pointDown: boolean)
		local flip = pointDown and CFrame.Angles(math.pi, 0, 0) or CFrame.new()
		local yawL = pointDown and -90 or 90
		local l = wedge(Vector3.new(TZ, TH, TW / 2), WHITE, CFrame.new(x - TW / 4, y, 0) * CFrame.Angles(0, math.rad(yawL), 0) * flip)
		local r = wedge(Vector3.new(TZ, TH, TW / 2), WHITE, CFrame.new(x + TW / 4, y, 0) * CFrame.Angles(0, math.rad(-yawL), 0) * flip)
		l.Parent = parentModel; r.Parent = parentModel
	end
	for i = 1, 6 do
		local x = (i - 3.5) * TW
		tooth(upper, x, 2.5 + TH / 2, true)
		tooth(lower, x, -2.5 - TH / 2, false)
	end
	local gu = part(Vector3.new(6 * TW + 0.6, 1.0, TZ), WHITE, nil, CFrame.new(0, 2.5 + TH + 0.5, 0)); gu.Parent = upper
	local gl = part(Vector3.new(6 * TW + 0.6, 1.0, TZ), WHITE, nil, CFrame.new(0, -2.5 - TH - 0.5, 0)); gl.Parent = lower
	upper.PrimaryPart = gu
	lower.PrimaryPart = gl
	jaw.Parent = folder()
	return jaw, upper, lower
end

local function recolor(model: Model, color: Color3)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d.Transparency < 1 then d.Color = color end
	end
end

function FX.Bite(attacker: Model, target: Model)
	local a = modelCenter(attacker) + Vector3.new(0, modelHeight(attacker) + 3, 0)
	local tc = modelCenter(target)
	local jaw, upper, lower = buildJaw()
	local camPos = Workspace.CurrentCamera.CFrame.Position
	local function face(pos: Vector3): CFrame
		local toCam = camPos - pos
		return CFrame.lookAt(pos, pos + Vector3.new(toCam.X, 0, toCam.Z))
	end
	jaw:PivotTo(face(a))
	jaw:ScaleTo(0.1)
	for k = 1, 5 do jaw:ScaleTo(0.1 + 0.9 * k / 5); task.wait(0.02) end
	local mid = (a + tc) * 0.5 + Vector3.new(0, 4, 0)
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 0.6, 0, 1)
		jaw:PivotTo(face(bezier(a, mid, tc, f)))
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	local uStart, lStart = upper:GetPivot(), lower:GetPivot()
	for k = 1, 6 do
		local f = k / 6
		upper:PivotTo(uStart * CFrame.new(0, -2.3 * f, 0))
		lower:PivotTo(lStart * CFrame.new(0, 2.3 * f, 0))
		if k == 2 then recolor(jaw, PINK) end
		if k == 4 then recolor(jaw, RED) end
		task.wait(0.05)
	end
	FX.HitFlash(target, 0.25)
	task.wait(0.35)
	jaw:Destroy()
end

-- ---------------------------------------------------------------- -- Firework
local function buildRocket(): Model
	local m = Instance.new("Model")
	m.Name = "Rocket"
	for i = 0, 4 do
		local col = (i % 2 == 0) and RED or WHITE
		local b = part(Vector3.new(0.9, 0.5, 0.9), col, Enum.Material.SmoothPlastic, CFrame.new(0, i * 0.5, 0))
		b.Parent = m
	end
	local tip = wedge(Vector3.new(0.9, 0.6, 0.9), RED, CFrame.new(0, 2.8, 0))
	tip.Material = Enum.Material.SmoothPlastic
	tip.Parent = m
	local stick = part(Vector3.new(0.15, 2.2, 0.15), Color3.fromRGB(120, 80, 40), Enum.Material.SmoothPlastic, CFrame.new(0.35, -1.2, 0))
	stick.Parent = m
	local tail = part(Vector3.new(0.3, 0.3, 0.3), WHITE, Enum.Material.SmoothPlastic, CFrame.new(0, -0.4, 0))
	tail.Transparency = 1
	tail.Parent = m
	local fire = Instance.new("ParticleEmitter")
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 170, 30), Color3.fromRGB(255, 60, 0))
	fire.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0)})
	fire.Transparency = NumberSequence.new(0.1, 1)
	fire.Lifetime = NumberRange.new(0.25, 0.4)
	fire.Rate = 60
	fire.Speed = NumberRange.new(4, 7)
	fire.SpreadAngle = Vector2.new(15, 15)
	fire.EmissionDirection = Enum.NormalId.Bottom
	fire.LightEmission = 1
	fire.Parent = tail
	local smoke = Instance.new("ParticleEmitter")
	smoke.Color = ColorSequence.new(Color3.fromRGB(190, 190, 190))
	smoke.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2)})
	smoke.Transparency = NumberSequence.new(0.3, 1)
	smoke.Lifetime = NumberRange.new(0.8, 1.2)
	smoke.Rate = 20
	smoke.Speed = NumberRange.new(1, 2)
	smoke.SpreadAngle = Vector2.new(40, 40)
	smoke.EmissionDirection = Enum.NormalId.Bottom
	smoke.Parent = tail
	m.PrimaryPart = tail
	m.Parent = folder()
	return m
end

function FX.Starburst(pos: Vector3, scale: number?)
	scale = scale or 1
	local flash = part(Vector3.new(1, 1, 1) * 2 * scale, WHITE, nil, CFrame.new(pos))
	flash.Shape = Enum.PartType.Ball
	tween(flash, 0.35, {Size = Vector3.new(1, 1, 1) * 10 * scale, Transparency = 1})
	Debris:AddItem(flash, 0.4)
	for i = 1, 12 do
		local col = (i % 2 == 0) and MAGENTA or YELLOW
		local ang = (i / 12) * math.pi * 2
		local len = (4 + math.random() * 4) * scale
		local w = wedge(Vector3.new(0.5 * scale, len, 0.4 * scale), col,
			CFrame.new(pos) * CFrame.Angles(0, 0, ang) * CFrame.new(0, len / 2, 0))
		tween(w, 0.5, {Size = Vector3.new(0.05, len * 1.6, 0.05), Transparency = 1,
			CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, ang) * CFrame.new(0, len * 0.9, 0)}, Enum.EasingStyle.Quart)
		Debris:AddItem(w, 0.55)
	end
end

function FX.SparkleRain(pos: Vector3, t: number)
	local e = part(Vector3.new(30, 1, 30), WHITE, Enum.Material.SmoothPlastic, CFrame.new(pos + Vector3.new(0, 14, 0)))
	e.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(WHITE)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
	pe.Transparency = NumberSequence.new(0, 1)
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Rate = 120
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -4, 0)
	pe.LightEmission = 1
	pe.Parent = e
	task.delay(t, function() pe.Enabled = false end)
	Debris:AddItem(e, t + 3)
end

function FX.Firework(attacker: Model, target: Model)
	local a = modelCenter(attacker) + Vector3.new(0, modelHeight(attacker) * 0.3, 0)
	local tc = modelCenter(target)
	local rocket = buildRocket()
	local function place(pos: Vector3, look: Vector3)
		rocket:PivotTo(CFrame.lookAt(pos, pos + look) * CFrame.Angles(math.rad(-90), 0, 0))
	end
	place(a, (tc - a))
	local mid = (a + tc) * 0.5 + Vector3.new(0, 6, 0)
	local start = os.clock()
	local last = a
	local T = 1.0
	while true do
		local f = math.clamp((os.clock() - start) / T, 0, 1)
		local p = bezier(a, mid, tc, f)
		local look = p - last
		if look.Magnitude < 0.01 then look = tc - a end
		place(p, look)
		last = p
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	rocket:Destroy()
	FX.Starburst(tc, 1.2)
	FX.HitFlash(target, 0.3)
	FX.ScreenFlash(0.45)
	FX.SparkleRain(tc, 1.6)
	task.wait(0.9)
end

-- ghost / recall / faint
function FX.Ghost(model: Model): Model
	local g = model:Clone()
	g.Name = "Ghost"
	for _, d in g:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.Color = WHITE
			d.Material = Enum.Material.Neon
			d.Transparency = 0
			d.CastShadow = false
		elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d:Destroy()
		elseif d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
			d:Destroy()
		end
	end
	g.Parent = folder()
	return g
end

local function fadeModel(model: Model, t: number)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then tween(d, t, {Transparency = 1}) end
	end
	Debris:AddItem(model, t + 0.05)
end

function FX.SendOut(model: Model, at: CFrame)
	local ghost = FX.Ghost(model)
	ghost:PivotTo(at + Vector3.new(0, 7, 0))
	local saved = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then saved[d] = true; d.Transparency = 1 end
	end
	model:PivotTo(at)
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 0.4, 0, 1)
		local e = f * f
		ghost:PivotTo(at + Vector3.new(0, 7 * (1 - e), 0))
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	for k = 1, 3 do ghost:ScaleTo(1 + 0.08 * (3 - k)); task.wait(0.03) end
	ghost:ScaleTo(1)
	task.wait(0.15)
	for p in saved do
		if p.Parent then p.Transparency = (p.Name == "HumanoidRootPart") and 1 or 0 end
	end
	fadeModel(ghost, 0.2)
	task.wait(0.2)
end

function FX.Recall(model: Model)
	local c = modelCenter(model)
	local e = part(Vector3.new(0.5, 0.5, 0.5), WHITE, Enum.Material.SmoothPlastic, CFrame.new(c))
	e.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(CYAN, WHITE)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(0.5, 0.8)
	pe.Speed = NumberRange.new(10, 16)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Drag = 6
	pe.Parent = e
	pe:Emit(120)
	Debris:AddItem(e, 1.5)
	task.wait(0.25)
	for k = 1, 8 do
		model:ScaleTo(math.max(0.05, 1 - k / 8))
		task.wait(0.04)
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency = 1 end
	end
	model:ScaleTo(1)
	task.wait(0.1)
end

function FX.Sparkle(pos: Vector3, count: number?)
	local e = part(Vector3.new(0.5, 0.5, 0.5), WHITE, Enum.Material.SmoothPlastic, CFrame.new(pos))
	e.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(WHITE, CYAN)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0)})
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Speed = NumberRange.new(6, 12)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Drag = 3
	pe.Parent = e
	pe:Emit(count or 60)
	Debris:AddItem(e, 2)
end

function FX.Faint(model: Model)
	local cf = model:GetPivot()
	local h = modelHeight(model)
	local lying = CFrame.new(cf.Position - Vector3.new(0, h * 0.5 - 0.6, 0)) * cf.Rotation * CFrame.Angles(0, 0, math.rad(90))
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 0.4, 0, 1)
		local e = 1 - (1 - f) ^ 2
		model:PivotTo(cf:Lerp(lying, e))
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	model:PivotTo(lying + Vector3.new(0, 0.5, 0)); task.wait(0.06)
	model:PivotTo(lying); task.wait(0.04)
end

function FX.Puff(pos: Vector3, size: number?)
	size = size or 1
	local e = part(Vector3.new(0.5, 0.5, 0.5), WHITE, Enum.Material.SmoothPlastic, CFrame.new(pos))
	e.Transparency = 1
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(WHITE)
	pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5 * size), NumberSequenceKeypoint.new(1, 3.5 * size)})
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Lifetime = NumberRange.new(0.5, 0.8)
	pe.Speed = NumberRange.new(3, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 5
	pe.Parent = e
	pe:Emit(math.floor(14 * size))
	Debris:AddItem(e, 1.5)
end

local function tweenModelRise(model: Model, from: CFrame, dy: number, t: number)
	task.spawn(function()
		local start = os.clock()
		while true do
			local f = math.clamp((os.clock() - start) / t, 0, 1)
			model:PivotTo(from + Vector3.new(0, dy * f, 0))
			if f >= 1 then break end
			RunService.RenderStepped:Wait()
		end
	end)
end

function FX.Vanish(model: Model)
	local g = FX.Ghost(model)
	local start = g:GetPivot()
	tweenModelRise(g, start, 3, 1.0)
	fadeModel(g, 1.0)
	task.wait(0.6)
	FX.Puff(modelCenter(model), 1.5)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency = 1 end
	end
	task.wait(0.6)
end

-- coins
local function buildCoin(): Part
	local c = part(Vector3.new(0.9, 0.25, 0.9), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
	c.Shape = Enum.PartType.Cylinder
	c.Size = Vector3.new(0.25, 0.9, 0.9)
	return c
end

function FX.CoinBurst(pos: Vector3, count: number, guiTarget: GuiObject?, onArrive: ((number) -> ())?)
	local camera = Workspace.CurrentCamera
	local coins: {Part} = {}
	for _ = 1, count do
		local c = buildCoin()
		c.CFrame = CFrame.new(pos)
		table.insert(coins, c)
		task.spawn(function()
			local ang = math.random() * math.pi * 2
			local dist = 1.5 + math.random() * 3
			local land = pos + Vector3.new(math.cos(ang) * dist, 0, math.sin(ang) * dist)
			arcTo(c, pos, land, 3 + math.random() * 2, 0.45, false)
			arcTo(c, land, land, 0.8, 0.2, false)
			c.CFrame = CFrame.new(land) * CFrame.Angles(0, 0, math.rad(90))
		end)
		task.wait(0.03)
	end
	task.wait(0.7)
	local remaining = #coins
	for i, c in coins do
		task.spawn(function()
			local target: Vector3
			if guiTarget then
				local p = guiTarget.AbsolutePosition + guiTarget.AbsoluteSize * 0.5
				local ray = camera:ViewportPointToRay(p.X, p.Y)
				target = ray.Origin + ray.Direction * 6
			else
				target = c.Position + Vector3.new(0, 6, 0)
			end
			local from = c.Position
			local start = os.clock()
			while true do
				local f = math.clamp((os.clock() - start) / 0.4, 0, 1)
				local e = f * f
				c.CFrame = CFrame.new(from:Lerp(target, e)) * CFrame.Angles(0, 0, math.rad(90) + f * 6)
				if f >= 1 then break end
				RunService.RenderStepped:Wait()
			end
			FX.Puff(c.Position, 0.5)
			c:Destroy()
			if onArrive then onArrive(i) end
			remaining -= 1
		end)
		task.wait(0.12)
	end
	while remaining > 0 do task.wait() end
	task.wait(0.3)
end

-- catch box
local function buildBox(): Part
	local b = part(Vector3.new(1.6, 1.6, 1.6), Color3.fromRGB(170, 110, 50), Enum.Material.WoodPlanks)
	for i = -1, 1, 2 do
		local line = part(Vector3.new(1.65, 0.12, 1.65), Color3.fromRGB(110, 70, 30), Enum.Material.SmoothPlastic)
		line.Anchored = false
		line.Parent = b
		local w = Instance.new("Weld"); w.Part0 = b; w.Part1 = line; w.C0 = CFrame.new(0, i * 0.45, 0); w.Parent = b
	end
	return b
end

function FX.CatchBox(fromModel: Model, target: Model): Part
	local a = modelCenter(fromModel) + Vector3.new(0, modelHeight(fromModel) * 0.5, 0)
	local tc = modelCenter(target)
	local land = tc - Vector3.new(0, modelHeight(target) * 0.5 - 0.8, 0)
	local box = buildBox()
	box.CFrame = CFrame.new(a)
	FX.ScreenTint(Color3.fromRGB(255, 205, 190), 1.7) -- light warm tint (was a dark red that hid the scene)
	local mid = (a + land) * 0.5 + Vector3.new(0, 7, 0)
	local start = os.clock()
	while true do
		local f = math.clamp((os.clock() - start) / 1.6, 0, 1)
		box.CFrame = CFrame.new(bezier(a, mid, land, f)) * CFrame.Angles(f * 7, f * 3, 0)
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	box.CFrame = CFrame.new(land)
	FX.Puff(tc, 1.2)
	for _, d in target:GetDescendants() do
		if d:IsA("BasePart") then d.Transparency = 1 end
	end
	task.wait(0.5)
	return box
end

function FX.BoxWobble(box: Part, shakes: number?)
	shakes = shakes or 3
	local base = box.CFrame
	for _ = 1, shakes do
		for _, ang in {-15, 15, -10, 10, 0} do
			tween(box, 0.12, {CFrame = base * CFrame.Angles(0, 0, math.rad(ang))}, Enum.EasingStyle.Sine)
			task.wait(0.12)
		end
		task.wait(1.4)
	end
end

function FX.StarBurst(pos: Vector3)
	for i = 1, 10 do
		local s = part(Vector3.new(0.7, 0.7, 0.2), YELLOW, nil, CFrame.new(pos))
		task.spawn(function()
			local ang = (i / 10) * math.pi * 2
			local land = pos + Vector3.new(math.cos(ang) * (2 + math.random() * 2), -0.5, math.sin(ang) * (2 + math.random() * 2))
			arcTo(s, pos, land, 3, 0.6, false)
			tween(s, 0.4, {Transparency = 1})
			Debris:AddItem(s, 0.5)
		end)
	end
end

-- screen effects
local function cc(): ColorCorrectionEffect
	local c = Lighting:FindFirstChild("BattleFX_CC")
	if not c then
		c = Instance.new("ColorCorrectionEffect")
		c.Name = "BattleFX_CC"
		c.Parent = Lighting
	end
	return c :: ColorCorrectionEffect
end

local function bloom(): BloomEffect
	local b = Lighting:FindFirstChild("BattleFX_Bloom")
	if not b then
		b = Instance.new("BloomEffect")
		b.Name = "BattleFX_Bloom"
		b.Intensity = 0
		b.Size = 24
		b.Threshold = 1.2
		b.Parent = Lighting
	end
	return b :: BloomEffect
end

local function blur(): BlurEffect
	local b = Lighting:FindFirstChild("BattleFX_Blur")
	if not b then
		b = Instance.new("BlurEffect")
		b.Name = "BattleFX_Blur"
		b.Size = 0
		b.Parent = Lighting
	end
	return b :: BlurEffect
end

function FX.ScreenFlash(t: number?)
	t = t or 0.4
	local c = cc()
	local b = bloom()
	c.Brightness = 0.6
	b.Intensity = 1.2
	tween(c, t, {Brightness = 0}, Enum.EasingStyle.Quad)
	tween(b, t, {Intensity = 0}, Enum.EasingStyle.Quad)
end

function FX.ScreenTint(color: Color3, t: number)
	local c = cc()
	tween(c, 0.15, {TintColor = color, Saturation = -0.4})
	task.delay(t, function()
		tween(c, 0.3, {TintColor = Color3.new(1, 1, 1), Saturation = 0})
	end)
end

function FX.Blur(on: boolean)
	tween(blur(), 0.2, {Size = on and 14 or 0})
end

function FX.Fade(toBlack: boolean, t: number?)
	t = t or 0.5
	local gui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local sg = gui:FindFirstChild("BattleFX_Fade") :: ScreenGui?
	if not sg then
		sg = Instance.new("ScreenGui")
		sg.Name = "BattleFX_Fade"
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = 1000
		sg.ResetOnSpawn = false
		local fr = Instance.new("Frame")
		fr.Name = "Black"
		fr.Size = UDim2.fromScale(1, 1)
		fr.BackgroundColor3 = Color3.new(0, 0, 0)
		fr.BackgroundTransparency = 1
		fr.BorderSizePixel = 0
		fr.Parent = sg
		sg.Parent = gui
	end
	local fr = (sg :: ScreenGui):FindFirstChild("Black") :: Frame
	tween(fr, t, {BackgroundTransparency = toBlack and 0 or 1}, Enum.EasingStyle.Linear)
	task.wait(t)
end

function FX.Cleanup()
	local f = Workspace:FindFirstChild("BattleFX")
	if f then f:Destroy() end
	for _, n in {"BattleFX_CC", "BattleFX_Bloom", "BattleFX_Blur"} do
		local e = Lighting:FindFirstChild(n)
		if e then e:Destroy() end
	end
end

return FX
