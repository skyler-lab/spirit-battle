-- BattleClient: plain placeholder battle UI + camera. Battle effects come from ReplicatedStorage.BattleFXPack (USE_FX_PACK below).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Data = require(RS:WaitForChild("BattleData"))
local R = RS:WaitForChild("BattleRemotes")
local EvStart, EvEvents, EvEnd, EvMove = R:WaitForChild("Start"), R:WaitForChild("Events"), R:WaitForChild("End"), R:WaitForChild("Move")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local FONT = Enum.Font.GothamBold

local gui = Instance.new("ScreenGui")
gui.Name = "BattleGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 100
gui.Parent = plr:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = o end
local function frame(parent, name, size, pos, color, anchor)
	local f = Instance.new("Frame"); f.Name = name; f.Size = size; f.Position = pos; f.BackgroundColor3 = color
	f.BorderSizePixel = 0; f.AnchorPoint = anchor or Vector2.new(0, 0); f.Parent = parent; return f
end
local function text(parent, str, size, pos, ts, color, align)
	local t = Instance.new("TextLabel"); t.BackgroundTransparency = 1; t.Size = size; t.Position = pos; t.Text = str
	t.TextSize = ts; t.Font = FONT; t.TextColor3 = color or Color3.new(1, 1, 1); t.TextXAlignment = align or Enum.TextXAlignment.Left
	t.Parent = parent; return t
end

-- HUD root (hidden outside battle)
local hud = frame(gui, "Hud", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(0, 0, 0)); hud.BackgroundTransparency = 1; hud.Visible = false

local function makePanel(name, pos, anchor)
	local p = frame(hud, name, UDim2.fromOffset(250, 62), pos, Color3.fromRGB(235, 235, 235), anchor); corner(p, 8)
	local nm = text(p, "", UDim2.new(1, -16, 0, 20), UDim2.fromOffset(8, 4), 16, Color3.fromRGB(40, 40, 40))
	local bg = frame(p, "BarBg", UDim2.new(1, -16, 0, 16), UDim2.fromOffset(8, 28), Color3.fromRGB(90, 90, 90)); corner(bg, 6)
	local fill = frame(bg, "Fill", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(70, 210, 80)); corner(fill, 6)
	local hp = text(p, "", UDim2.new(1, -16, 0, 14), UDim2.fromOffset(8, 44), 12, Color3.fromRGB(60, 60, 60))
	local en = text(p, "", UDim2.new(1, -16, 0, 14), UDim2.fromOffset(8, 44), 13, Color3.fromRGB(190, 120, 0), Enum.TextXAlignment.Right)
	return { nm = nm, fill = fill, hp = hp, en = en }
end
local foeP = makePanel("FoePanel", UDim2.fromOffset(12, 12))
local meP = makePanel("MePanel", UDim2.new(1, -12, 1, -184), Vector2.new(1, 1))

local msgHolder = frame(hud, "Msgs", UDim2.fromOffset(380, 120), UDim2.new(0, 12, 1, -12), Color3.new(0, 0, 0), Vector2.new(0, 1))
msgHolder.BackgroundTransparency = 1
local lay = Instance.new("UIListLayout"); lay.VerticalAlignment = Enum.VerticalAlignment.Bottom; lay.Padding = UDim.new(0, 4); lay.Parent = msgHolder

local menu = frame(hud, "Menu", UDim2.fromOffset(316, 154), UDim2.new(1, -12, 1, -12), Color3.new(0, 0, 0), Vector2.new(1, 1))
menu.BackgroundTransparency = 1

local fade = frame(gui, "Fade", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(0, 0, 0)); fade.BackgroundTransparency = 1; fade.ZIndex = 50
fade.Active = false

local function addMsg(str, who)
	local f = frame(msgHolder, "Msg", UDim2.fromOffset(0, 30), UDim2.fromOffset(0, 0), Color3.fromRGB(35, 95, 160)); corner(f, 8)
	local t = text(f, str, UDim2.new(1, -16, 1, 0), UDim2.fromOffset(8, 0), 15, Color3.new(1, 1, 1))
	f.Size = UDim2.fromOffset(math.min(380, 24 + #str * 8.5), 30)
	if who == "foe" then f.BackgroundColor3 = Color3.fromRGB(150, 50, 50) end
	Debris:AddItem(f, 3.2)
	for _, c in ipairs(msgHolder:GetChildren()) do end
end

-- menu buttons
local pages = { main = {}, fight = {} }
local function button(page, label, pos, size, color, onClick)
	local b = Instance.new("TextButton"); b.Text = label; b.Font = FONT; b.TextSize = 16; b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = color; b.Size = size; b.Position = pos; b.AutoButtonColor = true; b.Parent = menu; b.Visible = false
	corner(b, 8)
	b.MouseButton1Click:Connect(function() if onClick then onClick() end end)
	table.insert(pages[page], b); return b
end
local canAct = false
local curPage = "main"
local state = nil
local function showPage(p)
	curPage = p
	for name, list in pairs(pages) do for _, b in ipairs(list) do b.Visible = (name == p) and canAct end end
end
local W, H, G = 154, 46, 8
local function cell(c, r) return UDim2.fromOffset(c * (W + G), r * (H + G)) end
button("main", "FIGHT", cell(0, 0), UDim2.fromOffset(W, H), Color3.fromRGB(200, 50, 50), function() showPage("fight") end)
local bag = button("main", "BAG", cell(1, 0), UDim2.fromOffset(W, H), Color3.fromRGB(110, 110, 110)); bag.Text = "BAG (soon)"
local team = button("main", "TEAM", cell(0, 1), UDim2.fromOffset(W, H), Color3.fromRGB(110, 110, 110)); team.Text = "TEAM (soon)"
button("main", "RUN", cell(1, 1), UDim2.fromOffset(W, H), Color3.fromRGB(50, 110, 210), function()
	if canAct then canAct = false; showPage("main"); EvMove:FireServer("Run") end
end)
-- TAME: only lights up when the wild spirit is at or below the tame threshold (BattleData.Tame)
local tameBtn = button("main", "TAME", cell(0, 2), UDim2.fromOffset(W * 2 + G, H), Color3.fromRGB(60, 160, 90), function()
	if canAct and state and Data.tameChance(state.foeHp, state.foeMax) > 0 then
		canAct = false; showPage("main"); EvMove:FireServer("Tame")
	elseif canAct then
		addMsg("Too strong to tame! Get its health to " .. math.floor(Data.Tame.Threshold * 100) .. "% or less.")
	end
end)
-- the FIGHT page has 4 slots: Charge plus the spirit's own 3 moves (filled in when a battle starts)
local moveSlots = {}
for i = 1, 4 do
	local slot = {}
	slot.b = button("fight", "", cell((i - 1) % 2, math.floor((i - 1) / 2)), UDim2.fromOffset(W, H), Color3.fromRGB(110, 110, 110), function()
		local mv = slot.id and Data.Moves[slot.id]
		if mv and canAct and state and state.myEn >= mv.cost then canAct = false; showPage("fight"); EvMove:FireServer(slot.id) end
	end)
	moveSlots[i] = slot
end
local KIND_COLOR = { attack = Color3.fromRGB(190, 70, 50), block = Color3.fromRGB(60, 120, 190), heal = Color3.fromRGB(60, 160, 90), charge = Color3.fromRGB(200, 160, 40) }
local function setMoves(list)
	for i, slot in ipairs(moveSlots) do
		local mv = list[i] and Data.Moves[list[i]]
		slot.id = mv and list[i] or nil
		slot.b.Text = mv and (mv.name .. ((mv.cost > 0) and ("  (" .. mv.cost .. ")") or ("  (+" .. (mv.gain or 0) .. ")"))) or ""
		slot.b.BackgroundColor3 = mv and KIND_COLOR[mv.kind] or Color3.fromRGB(110, 110, 110)
	end
end
setMoves(Data.movesFor("Wood"))
button("fight", "BACK", cell(0, 2), UDim2.fromOffset(W * 2 + G, H), Color3.fromRGB(80, 80, 80), function() showPage("main") end)
local function refreshMoves()
	for _, slot in ipairs(moveSlots) do
		local ok = slot.id and state and state.myEn >= Data.Moves[slot.id].cost
		slot.b.TextTransparency = ok and 0 or 0.6; slot.b.BackgroundTransparency = ok and 0 or 0.5
	end
	local ch = state and Data.tameChance(state.foeHp, state.foeMax) or 0
	tameBtn.Text = (ch > 0) and ("TAME  (" .. math.floor(ch * 100 + 0.5) .. "% chance)") or ("TAME  (needs " .. math.floor(Data.Tame.Threshold * 100) .. "% HP or less)")
	tameBtn.TextTransparency = (ch > 0) and 0 or 0.5; tameBtn.BackgroundTransparency = (ch > 0) and 0 or 0.5
end

-- bars
local function setBar(p, cur, max, en)
	TS:Create(p.fill, TweenInfo.new(0.4), { Size = UDim2.fromScale(math.clamp(cur / max, 0, 1), 1) }):Play()
	p.fill.BackgroundColor3 = (cur / max > 0.5) and Color3.fromRGB(70, 210, 80) or ((cur / max > 0.2) and Color3.fromRGB(235, 190, 40) or Color3.fromRGB(220, 60, 50))
	p.hp.Text = math.ceil(cur) .. " / " .. max .. " HP"
	p.en.Text = en and ("Energy " .. en .. "/" .. Data.MaxEnergy) or ""
end
local function applySnap(s)
	if not s or not state then return end
	state.myEn, state.foeEn, state.myHp, state.foeHp = s.myEn, s.foeEn, s.myHp, s.foeHp
	setBar(meP, s.myHp, state.myMax, s.myEn); setBar(foeP, s.foeHp, state.foeMax, s.foeEn)
	refreshMoves()
end

-- effects (placeholder shapes)
local function burst(part) end
local function tmp(size, color, cf, shape, trans)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = Enum.Material.Neon; p.Size = size; p.Color = color; p.CFrame = cf; p.Transparency = trans or 0
	if shape then p.Shape = shape end
	p.Parent = workspace; Debris:AddItem(p, 2); return p
end
local function stageModel(who) return state.stage:FindFirstChild(who == "me" and "MyModel" or "FoeModel") end
local function dmgText(model, str, color)
	local at = tmp(Vector3.new(0.2, 0.2, 0.2), color, model:GetPivot() + Vector3.new(0, 4, 0), nil, 1)
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.fromOffset(120, 40); bb.AlwaysOnTop = true; bb.Adornee = at; bb.Parent = at
	local t = text(bb, str, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), 28, color, Enum.TextXAlignment.Center)
	t.TextStrokeTransparency = 0
	TS:Create(at, TweenInfo.new(0.9), { CFrame = at.CFrame + Vector3.new(0, 3, 0) }):Play()
	TS:Create(t, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
end
local function fxCharge(model)
	for i = 1, 4 do
		local off = Vector3.new(math.random(-20, 20) / 10, math.random(0, 20) / 10, math.random(-20, 20) / 10)
		local p = tmp(Vector3.new(0.3, 1, 0.3), Color3.fromRGB(255, 230, 60), model:GetPivot() + off)
		TS:Create(p, TweenInfo.new(0.8), { CFrame = p.CFrame + Vector3.new(0, 3, 0), Transparency = 1 }):Play()
	end
end
local function fxBlock(model)
	local p = tmp(Vector3.new(6, 6, 6), Color3.fromRGB(90, 170, 255), model:GetPivot(), Enum.PartType.Ball, 0.5)
	TS:Create(p, TweenInfo.new(0.8), { Transparency = 1, Size = Vector3.new(8, 8, 8) }):Play()
end
local function fxHit(from, to, color)
	local a, b = from:GetPivot().Position, to:GetPivot().Position
	local p = tmp(Vector3.new(1.4, 1.4, 1.4), color, CFrame.new(a), Enum.PartType.Ball)
	local tw = TS:Create(p, TweenInfo.new(0.45, Enum.EasingStyle.Quad), { Position = b }); tw:Play()
	tw.Completed:Connect(function()
		p.Position = b
		local f = tmp(Vector3.new(2, 2, 2), Color3.new(1, 1, 1), CFrame.new(b), Enum.PartType.Ball, 0.2)
		TS:Create(f, TweenInfo.new(0.35), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
		p:Destroy()
	end)
end

-- camera: behind and to the side of your spirit so both spirits are in view. Distances scale with the gap between them.
local BATTLE_FOV = 40
local normalFov = cam.FieldOfView
local function setCamera()
	local my = state.stage:WaitForChild("MyModel"):GetPivot().Position
	local foe = state.stage:WaitForChild("FoeModel"):GetPivot().Position
	local flat = (foe - my) * Vector3.new(1, 0, 1)
	local d = flat.Magnitude
	local dir = flat.Unit
	local right = dir:Cross(Vector3.new(0, 1, 0))
	local pos = my - dir * (d * 1.05) + right * (d * 0.6) + Vector3.new(0, d * 0.4, 0)
	normalFov = cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	cam.FieldOfView = BATTLE_FOV
	cam.CFrame = CFrame.lookAt(pos, my + (foe - my) * 0.5 + Vector3.new(0, 1.5, 0))
end

local function tweenFade(to, t) local tw = TS:Create(fade, TweenInfo.new(t), { BackgroundTransparency = to }); tw:Play(); tw.Completed:Wait() end

local hidden = {}
local function hideOtherGuis(on)
	if on then
		for _, g in ipairs(plr.PlayerGui:GetChildren()) do
			if g:IsA("ScreenGui") and g ~= gui and g.Enabled then hidden[g] = true; g.Enabled = false end
		end
	else
		for g in pairs(hidden) do if g.Parent then g.Enabled = true end end
		hidden = {}
	end
end

-- ===== BattleFXPack presentation (2026-10-27). Set USE_FX_PACK = false to go back to the old plain effects above. =====
local USE_FX_PACK = true
local RunService = game:GetService("RunService")
local Pack = RS:WaitForChild("BattleFXPack")
local FX = require(Pack:WaitForChild("FX"))
local PackMoves = require(Pack:WaitForChild("Moves"))
local Rig = require(RS:WaitForChild("SpiritRig"))
local MoveFX = require(RS:WaitForChild("BattleMoveFX"))
local FX_FOV = 55
-- step 2 of docs/FIGHT-PLAN-V3.md (2026-10-28): SIMPLE turns off the effects built from plain shapes (Don rejected them),
-- the energy bolts and the camera cuts, so the turns are clear. Spirits still move; glows use Highlight. false = the full look.
local SIMPLE = true
FX.BoltScale = 0.6 -- the pack's bolts are too big up close

local motion = {} -- "me" / "foe" -> { model, home, off, rig, frozen, seed }
local camBase, camPunch, camShake = nil, 0, 0
local loopConn = nil
local catchBox = nil

local function center(m) return (m:GetBoundingBox()).Position end

-- move a spirit's action offset (lunge, jolt) over t seconds; idle motion keeps playing on top
local function lerpOff(mo, to, t)
	local from = mo.off
	local t0 = os.clock()
	while true do
		local f = math.clamp((os.clock() - t0) / t, 0, 1)
		mo.off = from:Lerp(to, f)
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
end

local function camTo(cf, t)
	local from = camBase or cam.CFrame
	local t0 = os.clock()
	while true do
		local f = math.clamp((os.clock() - t0) / t, 0, 1)
		camBase = from:Lerp(cf, 1 - (1 - f) ^ 2)
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
end

local function punch(studs, t, shake)
	task.spawn(function()
		local t0 = os.clock()
		while true do
			local f = math.clamp((os.clock() - t0) / t, 0, 1)
			camPunch = studs * math.sin(f * math.pi)
			camShake = (shake or 0) * (1 - f)
			if f >= 1 then break end
			RunService.RenderStepped:Wait()
		end
		camPunch, camShake = 0, 0
	end)
end

-- camera shots (example from the reference game: your spirit big in the lower-left foreground, the camera cuts per action)
local function shot(name)
	local me, foe = motion.me, motion.foe
	if not me or not foe then return cam.CFrame end
	local my, fo = me.home.Position, foe.home.Position
	local flat = (fo - my) * Vector3.new(1, 0, 1)
	local d = flat.Magnitude
	local dir = flat.Unit
	local right = dir:Cross(Vector3.new(0, 1, 0))
	local up = Vector3.new(0, 1, 0)
	if name == "foe" then -- from beside your spirit to the foe, while the foe acts
		return CFrame.lookAt(my + dir * 6 + right * 6 + up * 3, fo + up)
	elseif name == "onFoe" then -- low and close on the foe, for big hits on it
		return CFrame.lookAt(fo - dir * 16 - right * 6 + up * 2.5, fo + up * 3)
	elseif name == "onMe" then -- facing your spirit, for big hits on it
		return CFrame.lookAt(my + dir * 16 + right * 6 + up * 2.5, my + up * 3)
	end
	-- main: low, behind and well to the right of your spirit, so it sits big in the lower-left and the foe upper-right
	return CFrame.lookAt(my - dir * 8.5 + right * 12.75 + up * 4, my + dir * 4.75 + right * 2.6 + up * 2)
end
local function cut(name) camBase = shot(SIMPLE and "main" or name) end

-- energy shown as lightning bolts orbiting each spirit (example from the reference game); spending makes them fly off
local function setBolts(who, n)
	local mo = motion[who]
	if not mo or not mo.bolts then return end
	n = math.clamp(n or 0, 0, Data.MaxEnergy)
	if n > mo.shown then
		mo.bolts:Add(n - mo.shown)
	elseif n < mo.shown then
		local h = mo.bolts
		task.spawn(function() h:Consume(); h:Add(n) end)
	end
	mo.shown = n
end

local function startMotion()
	motion = {}
	for _, who in ipairs({ "me", "foe" }) do
		local m = stageModel(who)
		if m then
			local ok, r = pcall(Rig.new, m)
			motion[who] = { model = m, home = m:GetPivot(), off = CFrame.new(), rig = ok and r or nil, frozen = false, seed = math.random() * 10,
				bolts = (not SIMPLE) and FX.Charge(m, 0) or nil, shown = 0 }
		end
	end
	if loopConn then loopConn:Disconnect() end
	local t0 = os.clock()
	loopConn = RunService.RenderStepped:Connect(function(dt)
		local t = os.clock() - t0
		for _, mo in pairs(motion) do
			if not mo.frozen and mo.model.Parent then
				-- idle: gentle bob and sway on top of any action offset
				local idle = CFrame.new(0, math.sin(t * 2.4 + mo.seed) * 0.18, 0) * CFrame.Angles(0, math.sin(t * 1.3 + mo.seed) * 0.05, 0)
				local cf = mo.home * mo.off * idle
				if mo.rig then mo.rig:Update(cf, 0, t, dt, 1) else mo.model:PivotTo(cf) end
			end
		end
		if camBase then
			local drift = CFrame.new(math.sin(t * 0.5) * 0.35, math.sin(t * 0.37) * 0.2, 0)
			local shake = CFrame.new()
			if camShake > 0 then shake = CFrame.new((math.random() - 0.5) * camShake, (math.random() - 0.5) * camShake, 0) end
			cam.CFrame = camBase * drift * CFrame.new(0, 0, -camPunch) * shake
		end
	end)
end

local function stopMotion()
	if loopConn then loopConn:Disconnect(); loopConn = nil end
	for _, mo in pairs(motion) do if mo.bolts then mo.bolts:Destroy() end end
	motion = {}
	camBase, camPunch, camShake = nil, 0, 0
	catchBox = nil
end

-- an outline glow on a spirit (Highlight, no shapes). hold = true keeps it until clearGlow; otherwise it fades out
local function glow(who, color, hold)
	local mo = motion[who]
	if not mo then return end
	if mo.glow then mo.glow:Destroy() end
	local h = Instance.new("Highlight")
	h.FillColor = color; h.OutlineColor = color
	h.FillTransparency = 0.45; h.OutlineTransparency = 0
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = mo.model
	mo.glow = h
	if hold then
		task.spawn(function()
			while h.Parent do
				local f = (math.sin(os.clock() * 8) + 1) / 2
				h.FillTransparency = 0.15 + 0.4 * f
				RunService.RenderStepped:Wait()
			end
		end)
	else
		TS:Create(h, TweenInfo.new(0.6), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
		Debris:AddItem(h, 0.65)
	end
end
local function clearGlow(who)
	local mo = motion[who]
	if mo and mo.glow then mo.glow:Destroy(); mo.glow = nil end
end

-- big centre-screen word ("SUPER EFFECTIVE!", "BLOCKED!")
local popLbl = text(hud, "", UDim2.fromOffset(700, 70), UDim2.fromScale(0.5, 0.15), 46, Color3.new(1, 1, 1), Enum.TextXAlignment.Center)
popLbl.AnchorPoint = Vector2.new(0.5, 0.5); popLbl.Font = Enum.Font.GothamBlack; popLbl.TextStrokeTransparency = 0; popLbl.TextTransparency = 1
local popScale = Instance.new("UIScale"); popScale.Parent = popLbl
local popId = 0
local function pop(str, color)
	popId += 1
	local id = popId
	popLbl.Text = str; popLbl.TextColor3 = color; popLbl.TextTransparency = 0; popLbl.TextStrokeTransparency = 0
	popScale.Scale = 1.7
	TS:Create(popScale, TweenInfo.new(0.22, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(0.75, function()
		if popId == id then TS:Create(popLbl, TweenInfo.new(0.3), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play() end
	end)
end

-- "+2" / "-5" energy pops just left of a panel's energy text
local function enPop(who, str, color)
	local p = (who == "me") and meP or foeP
	local l = text(p.en.Parent, str, UDim2.fromOffset(50, 24), UDim2.new(1, -150, 0, 38), 22, color or Color3.fromRGB(255, 200, 0), Enum.TextXAlignment.Right)
	l.TextStrokeTransparency = 0.2
	TS:Create(l, TweenInfo.new(0.9), { Position = l.Position - UDim2.fromOffset(0, 30), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	Debris:AddItem(l, 0.95)
end

-- quick white flash over the screen for big hits (gentler than the pack's ScreenFlash, which washed the view out)
local flashFrame = frame(gui, "HitFlash", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.new(1, 1, 1))
flashFrame.BackgroundTransparency = 1; flashFrame.ZIndex = 40
local function screenFlash()
	flashFrame.BackgroundTransparency = 0.6
	TS:Create(flashFrame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
end

-- flash ball plus rays in the attacker's element colour
local function burstAt(pos, color, scale)
	if SIMPLE then return end
	local flash = tmp(Vector3.new(2, 2, 2) * scale, color, CFrame.new(pos), Enum.PartType.Ball, 0)
	TS:Create(flash, TweenInfo.new(0.35), { Size = Vector3.new(9, 9, 9) * scale, Transparency = 1 }):Play()
	local face = CFrame.lookAt(pos, cam.CFrame.Position)
	for i = 1, 10 do
		local ang = (i / 10) * math.pi * 2
		local len = (3 + math.random() * 3) * scale
		local r = tmp(Vector3.new(0.45 * scale, len, 0.3 * scale), (i % 2 == 0) and color or Color3.new(1, 1, 1), face * CFrame.Angles(0, 0, ang) * CFrame.new(0, len / 2, 0))
		TS:Create(r, TweenInfo.new(0.45, Enum.EasingStyle.Quart), { Size = Vector3.new(0.05, len * 1.6, 0.05), Transparency = 1,
			CFrame = face * CFrame.Angles(0, 0, ang) * CFrame.new(0, len * 1.1, 0) }):Play()
	end
end

local function hitFx(def, color, dmg, mult, power)
	local d = motion[def]
	if not d then return end
	FX.HitFlash(d.model, 0.2)
	burstAt(center(d.model), color, math.min(power, 1.2)) -- bigger flash balls hid the target
	FX.DamageNumber(d.model, dmg, (mult > 1) and Color3.fromRGB(255, 200, 0) or ((mult < 1) and Color3.fromRGB(205, 205, 205) or nil))
	punch(1.5 * power, 0.35, (mult > 1) and 0.7 or 0.25 * power)
	if mult > 1 then pop("SUPER EFFECTIVE!", Color3.fromRGB(255, 205, 40)) elseif mult < 1 then pop("not very effective", Color3.fromRGB(210, 210, 210)) end
	task.spawn(function()
		lerpOff(d, CFrame.new(0, 0.3, 1.8 * power), 0.07)
		lerpOff(d, CFrame.new(), 0.3)
	end)
end

local function shieldUp(who)
	local mo = motion[who]
	if SIMPLE then glow(who, Color3.fromRGB(80, 170, 255), true); return end
	if mo then task.spawn(PackMoves.Shield.play, { attacker = mo.model, target = mo.model }) end
end

local function shieldHit(who)
	local mo = motion[who]
	if not mo then return end
	local c = center(mo.model)
	burstAt(c, Color3.fromRGB(80, 220, 255), 1)
	FX.Puff(c, 1)
	if not SIMPLE then PackMoves.ShieldBreak(mo.model) end
	pop("BLOCKED!", Color3.fromRGB(120, 220, 255))
	punch(0.8, 0.3, 0.2)
end

local function chargeFx(who)
	local mo = motion[who]
	if not mo then return end
	if SIMPLE then
		glow(who, Color3.fromRGB(255, 220, 40))
		task.spawn(function() lerpOff(mo, CFrame.new(0, 1.2, 0), 0.15); lerpOff(mo, CFrame.new(), 0.3) end)
	else
		MoveFX.ChargeFlash(mo.model)
	end
	enPop(who, "+" .. Data.Moves.Charge.gain)
end

-- lunge: wind up, dash most of the way, the element bursts on the target, spring back
local function lungeMove(att, def, color, el, dmg, mult, blocked)
	local a, d = motion[att], motion[def]
	if not a or not d then return end
	local gap = (d.home.Position - a.home.Position).Magnitude
	lerpOff(a, CFrame.new(0, 0, 0.9), 0.12)
	lerpOff(a, CFrame.new(0, 0.5, -gap * 0.6), 0.13)
	if blocked then shieldHit(def) else MoveFX.Impact(d.model, el, color); hitFx(def, color, dmg, mult, 1) end
	task.wait(0.2)
	lerpOff(a, CFrame.new(), 0.25)
end

-- shot: the user gathers power and leans back, the element shot arcs over and lands
local function shotMove(att, def, color, el, dmg, mult, blocked)
	local a, d = motion[att], motion[def]
	if not a or not d then return end
	task.spawn(MoveFX.WindUp, a.model, el, color, 0.3)
	lerpOff(a, CFrame.new(0, 0, 0.8), 0.3)
	task.spawn(function() lerpOff(a, CFrame.new(0, 0, -1.4), 0.08); lerpOff(a, CFrame.new(), 0.25) end)
	MoveFX.Shot(a.model, d.model, el, color, function()
		if blocked then shieldHit(def) else MoveFX.Impact(d.model, el, color); hitFx(def, color, dmg, mult, 1.3) end
	end)
end

-- burst: the user gathers power, the camera cuts to the target, and the element erupts all around it
local function burstMove(att, def, color, el, dmg, mult, blocked)
	local a, d = motion[att], motion[def]
	if not a or not d then return end
	task.spawn(function() lerpOff(a, CFrame.new(0, 1.2, 0), 0.15); lerpOff(a, CFrame.new(), 0.2) end)
	MoveFX.WindUp(a.model, el, color, 0.35)
	task.wait(0.35)
	cut((def == "foe") and "onFoe" or "onMe")
	if blocked then shieldHit(def) else
		MoveFX.Eruption(d.model, el, color, 1)
		screenFlash()
		hitFx(def, color, dmg, mult, 2)
	end
	task.wait(1.1)
	cut("main")
end

-- SIMPLE: every attack is the spirit's own body moving: lean back (longer for bigger moves), dash in, hit, spring back
local function simpleMove(att, def, color, el, dmg, mult, blocked, fx)
	local a, d = motion[att], motion[def]
	if not a or not d then return end
	local gap = (d.home.Position - a.home.Position).Magnitude
	local big = fx == "burst"
	if fx == "lunge" then
		lerpOff(a, CFrame.new(0, 0, 0.9), 0.12)
	else
		lerpOff(a, CFrame.new(0, big and 1.5 or 0.5, 1.4), big and 0.55 or 0.42)
	end
	lerpOff(a, CFrame.new(0, 0.5, -gap * 0.6), 0.13)
	if blocked then shieldHit(def) else
		if big then screenFlash() end
		hitFx(def, color, dmg, mult, big and 2 or 1)
	end
	task.wait(0.2)
	lerpOff(a, CFrame.new(), 0.25)
end

-- Wood's Leaf Storm: the first full attack built from pack B's effects (ReplicatedStorage.BattleVFX, Toolbox, added 2026-10-28).
-- Timing takes example from the reference game's Splash: the light dims while Wood spins up, the camera cuts to the target,
-- a green leaf-wind tornado erupts on it with a red hit flash, a short freeze, shake, knockback and the damage number, then back.
local VFX = RS:WaitForChild("BattleVFX")
local LEAF = ColorSequence.new(Color3.fromRGB(70, 200, 40), Color3.fromRGB(20, 120, 30)) -- deep green: the glow brightens it
local WIND_ONLY = { Windspin1 = true, Windspin2 = true, Windspin3 = true, Windspin4 = true, Windspin5 = true } -- no white flash
local function vfxAt(name, pos, tint, scale)
	local k = VFX[name]:Clone()
	k.CFrame = CFrame.new(pos)
	for _, d in ipairs(k:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			if tint then d.Color = tint end
			if scale and scale ~= 1 then
				local ks = {}
				for _, p in ipairs(d.Size.Keypoints) do table.insert(ks, NumberSequenceKeypoint.new(p.Time, p.Value * scale, p.Envelope * scale)) end
				d.Size = NumberSequence.new(ks)
				d.Speed = NumberRange.new(d.Speed.Min * scale, d.Speed.Max * scale)
			end
		end
	end
	k.Parent = workspace
	return k
end
-- burst the emitters again and again for dur seconds (only = names to use), then clean up
local function pulse(k, dur, every, only)
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < dur and k.Parent do
			for _, d in ipairs(k:GetDescendants()) do
				if d:IsA("ParticleEmitter") and (not only or only[d.Name]) then d:Emit(math.clamp(math.floor(d.Rate * every + 0.5), 1, 12)) end
			end
			task.wait(every)
		end
		Debris:AddItem(k, 2.5)
	end)
end
local function darken(on)
	local L = game:GetService("Lighting")
	local cc = L:FindFirstChild("MoveCC")
	if not cc then cc = Instance.new("ColorCorrectionEffect"); cc.Name = "MoveCC"; cc.Parent = L end
	TS:Create(cc, TweenInfo.new(on and 0.3 or 0.4), { Brightness = on and -0.18 or 0, Saturation = on and -0.25 or 0, Contrast = on and 0.1 or 0 }):Play()
end
local function leafStorm(att, def, color, el, dmg, mult, blocked)
	local a, d = motion[att], motion[def]
	if not a or not d then return end
	darken(true)
	-- wind-up: crouch, then spin up and rise while a small green whirl gathers at its feet
	pulse(vfxAt("Tornado-01", MoveFX.feet(a.model) + Vector3.new(0, 1, 0), LEAF, 0.5), 0.55, 0.12, WIND_ONLY)
	lerpOff(a, CFrame.new(0, -0.5, 0.5), 0.12)
	local t0 = os.clock()
	while os.clock() - t0 < 0.45 do
		local f = (os.clock() - t0) / 0.45
		a.off = CFrame.new(0, 1.2 * f, 0) * CFrame.Angles(0, f * f * math.pi * 4, 0)
		RunService.RenderStepped:Wait()
	end
	a.off = CFrame.new(0, 1.2, 0)
	camBase = shot((def == "foe") and "onFoe" or "onMe")
	task.wait(0.08)
	if blocked then shieldHit(def) else
		pulse(vfxAt("Tornado-01", MoveFX.feet(d.model) + Vector3.new(0, 1, 0), LEAF, 1.4), 0.9, 0.1)
		pulse(vfxAt("Explosion-01", MoveFX.center(d.model), ColorSequence.new(Color3.fromRGB(120, 230, 80)), 1), 0.3, 0.1, { Specks1 = true })
		a.frozen, d.frozen = true, true
		hitFx(def, color, dmg, mult, 2)
		task.wait(0.08)
		a.frozen, d.frozen = false, false
	end
	lerpOff(a, CFrame.new(), 0.3)
	task.wait(0.7)
	cut("main")
	darken(false)
end
-- moves with their own full sequence, and when their hit lands (seconds after the hit event)
local SPECIAL = { LeafStorm = leafStorm }
local SPECIAL_IMPACT = { LeafStorm = 0.65 }
-- Studio-only test switch: set Workspace attribute TestReplayMove to a move id during a battle to replay its look (no damage)
if game:GetService("RunService"):IsStudio() then
	workspace:GetAttributeChangedSignal("TestReplayMove"):Connect(function()
		local id = workspace:GetAttribute("TestReplayMove")
		if id and SPECIAL[id] and state and motion.me then
			task.spawn(SPECIAL[id], "me", "foe", Data.ElementColor[state.myEl] or Color3.new(1, 1, 1), state.myEl, 45, 1, false)
		end
	end)
end

local MOVE_FN = { lunge = lungeMove, shot = shotMove, burst = burstMove }

-- knocked out: tip over; a defeated wild spirit then rises, fades and bursts into sparkles
local function faintFx(who, vanish)
	local mo = motion[who]
	if not mo then return end
	mo.frozen = true
	if mo.bolts then mo.bolts:Destroy(); mo.bolts = nil end
	FX.HitFlash(mo.model, 0.3)
	if mo.model:FindFirstChild("Orb") then
		-- a ball looks the same tipped over, so a placeholder orb drops onto its platform instead
		local cf = mo.model:GetPivot()
		local t0 = os.clock()
		while os.clock() - t0 < 0.3 do
			local f = (os.clock() - t0) / 0.3
			mo.model:PivotTo(cf - Vector3.new(0, 1.2 * f * f, 0))
			RunService.RenderStepped:Wait()
		end
		FX.Puff(mo.model:GetPivot().Position - Vector3.new(0, 1.5, 0), 1)
	else
		FX.Faint(mo.model)
	end
	if not vanish then return end
	task.wait(0.35)
	local c = center(mo.model)
	local startCF = mo.model:GetPivot()
	for _, p in ipairs(mo.model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 1 then TS:Create(p, TweenInfo.new(0.7), { Transparency = 1 }):Play() end
	end
	local t0 = os.clock()
	while os.clock() - t0 < 0.7 do
		mo.model:PivotTo(startCF + Vector3.new(0, 3 * (os.clock() - t0) / 0.7, 0))
		RunService.RenderStepped:Wait()
	end
	FX.Puff(c, 1.5)
	FX.Sparkle(c, 90)
	burstAt(c, Color3.fromRGB(255, 230, 120), 1.2)
end

-- tame try: box flies over, the spirit goes in, two wobbles, then it holds or breaks open
local function tameFx(ok)
	local me, foe = motion.me, motion.foe
	if not me or not foe then return end
	local saved = {}
	for _, p in ipairs(foe.model:GetDescendants()) do if p:IsA("BasePart") then saved[p] = p.Transparency end end
	foe.frozen = true
	local box = FX.CatchBox(me.model, foe.model)
	catchBox = box
	local base = box.CFrame
	for _ = 1, 2 do
		for _, ang in ipairs({ -15, 15, -10, 10, 0 }) do
			TS:Create(box, TweenInfo.new(0.12, Enum.EasingStyle.Sine), { CFrame = base * CFrame.Angles(0, 0, math.rad(ang)) }):Play()
			task.wait(0.12)
		end
		task.wait(0.35)
	end
	if ok then
		FX.StarBurst(box.Position + Vector3.new(0, 1, 0))
		FX.Sparkle(box.Position, 60)
		pop("TAMED!", Color3.fromRGB(120, 255, 140))
	else
		FX.Puff(box.Position, 1.2)
		box:Destroy(); catchBox = nil
		for p, tr in pairs(saved) do if p.Parent then p.Transparency = tr end end
		foe.frozen = false
		pop("IT BROKE FREE!", Color3.fromRGB(255, 120, 90))
	end
end

-- battle start: camera circles the wild spirit, then your spirit drops in and the camera pulls back to the main view
local function introFx(foeName)
	local me, foe = motion.me, motion.foe
	if not me or not foe then return end
	cam.FieldOfView = FX_FOV
	local mainCF = shot("main")
	local fpos = center(foe.model)
	local dir = ((fpos - center(me.model)) * Vector3.new(1, 0, 1)).Unit
	me.frozen = true
	local saved = {}
	for _, p in ipairs(me.model:GetDescendants()) do if p:IsA("BasePart") then saved[p] = p.Transparency; p.Transparency = 1 end end
	local function orbit(f)
		local pos = fpos + CFrame.Angles(0, math.rad(-30 + 40 * f), 0):VectorToWorldSpace(-dir * 16) + Vector3.new(0, 3, 0)
		return CFrame.lookAt(pos, fpos + Vector3.new(0, 0.5, 0))
	end
	camBase = orbit(0)
	tweenFade(1, 0.25)
	addMsg("A wild " .. foeName .. " has appeared!", "foe")
	FX.Sparkle(fpos, 40)
	task.spawn(function() lerpOff(foe, CFrame.new(0, 1.6, 0), 0.12); lerpOff(foe, CFrame.new(), 0.2) end)
	local t0 = os.clock()
	while os.clock() - t0 < 1.0 do
		camBase = orbit((os.clock() - t0) / 1.0)
		RunService.RenderStepped:Wait()
	end
	task.spawn(camTo, mainCF, 0.45)
	-- your spirit drops in from above
	local land = me.home
	for p, tr in pairs(saved) do if p.Parent then p.Transparency = tr end end
	t0 = os.clock()
	while true do
		local f = math.clamp((os.clock() - t0) / 0.35, 0, 1)
		me.model:PivotTo(land + Vector3.new(0, 8 * (1 - f * f), 0))
		if f >= 1 then break end
		RunService.RenderStepped:Wait()
	end
	me.frozen = false
	FX.Puff(land.Position - Vector3.new(0, 2, 0), 1.2)
	FX.Sparkle(center(me.model), 40)
	punch(0.8, 0.25, 0.3)
	task.wait(0.3)
end

local function playEventFx(e)
	local who = e.who
	if e.k == "say" then
		addMsg(e.text, who)
		if who == "foe" then clearGlow("foe") end
		cut((who == "foe") and "foe" or "main")
		local mv = e.move and Data.Moves[e.move]
		if mv and mv.cost > 0 then enPop(who, "-" .. mv.cost, Color3.fromRGB(255, 120, 80)) end
	elseif e.k == "reject" then
		if e.why == "tame" then addMsg("Too strong to tame!") else addMsg("Not enough energy!") end
	elseif e.k == "fx" then
		if e.type == "charge" then chargeFx(who) else shieldUp(who) end
	elseif e.k == "hit" or e.k == "blocked" then
		local att = (e.k == "hit") and who or e.by
		local def = (att == "me") and "foe" or "me"
		local el = (att == "me") and state.myEl or state.foeEl
		local mv = Data.Moves[e.move]
		local fn = SPECIAL[e.move] or (SIMPLE and simpleMove) or MOVE_FN[mv and mv.fx] or lungeMove
		task.spawn(fn, att, def, Data.ElementColor[el] or Color3.new(1, 1, 1), el, e.dmg, e.mult or 1, e.k == "blocked", mv and mv.fx)
		if e.k == "hit" then
			if e.mult > 1 then addMsg("It's super effective!") elseif e.mult < 1 then addMsg("Not very effective...") end
		end
	elseif e.k == "heal" then
		local mo = motion[who]
		if mo and SIMPLE then
			glow(who, Color3.fromRGB(90, 235, 110))
			FX.DamageNumber(mo.model, -(e.amt or 0), Color3.fromRGB(90, 235, 110))
		elseif mo then
			MoveFX.Heal(mo.model)
			FX.DamageNumber(mo.model, -(e.amt or 0), Color3.fromRGB(90, 235, 110))
		end
	elseif e.k == "hint" then
		addMsg(e.text, "foe")
		glow("foe", Color3.fromRGB(255, 120, 30), true)
	elseif e.k == "tame" then
		task.spawn(tameFx, e.ok)
	elseif e.k == "en" and SIMPLE then
		clearGlow("me"); clearGlow("foe")
		enPop("me", "+" .. Data.TurnEnergy); enPop("foe", "+" .. Data.TurnEnergy)
	elseif e.k == "en" then
		if motion.me then PackMoves.ShieldBreak(motion.me.model) end
		if motion.foe then PackMoves.ShieldBreak(motion.foe.model) end
		enPop("me", "+" .. Data.TurnEnergy); enPop("foe", "+" .. Data.TurnEnergy)
	elseif e.k == "end" then
		if e.text then addMsg(e.text) end
		if motion.me then PackMoves.ShieldBreak(motion.me.model) end
		if motion.foe then PackMoves.ShieldBreak(motion.foe.model) end
		if e.result == "win" then task.spawn(faintFx, "foe", true)
		elseif e.result == "lose" then task.spawn(faintFx, "me", false)
		elseif e.result == "tame" and catchBox then FX.Sparkle(catchBox.Position, 40) end
	end
end

-- old plain effects (USE_FX_PACK = false)
local function playEventOld(e)
	if e.k == "say" then addMsg(e.text, e.who)
	elseif e.k == "reject" then
		if e.why == "tame" then addMsg("Too strong to tame!") else addMsg("Not enough energy!") end
	elseif e.k == "tame" then
		local m = stageModel("foe")
		if m then
			local ring = tmp(Vector3.new(7, 7, 7), Color3.fromRGB(80, 220, 120), m:GetPivot(), Enum.PartType.Ball, 0.4)
			TS:Create(ring, TweenInfo.new(1.1), { Size = Vector3.new(1, 1, 1), Transparency = 1 }):Play()
		end
		addMsg(e.ok and "Success!" or ("Failed... (" .. math.floor((e.chance or 0) * 100 + 0.5) .. "% chance)"))
	elseif e.k == "fx" then
		local m = stageModel(e.who)
		if m then if e.type == "charge" then fxCharge(m) else fxBlock(m) end end
	elseif e.k == "blocked" then
		addMsg("Blocked!")
	elseif e.k == "hit" then
		local att, def = stageModel(e.who), stageModel(e.who == "me" and "foe" or "me")
		local el = (e.who == "me") and state.myEl or state.foeEl
		if att and def then
			fxHit(att, def, Data.ElementColor[el] or Color3.new(1, 1, 1))
			task.delay(0.45, function() dmgText(def, "-" .. e.dmg, Color3.fromRGB(255, 70, 60)) end)
		end
		if e.mult > 1 then addMsg("It's super effective!") elseif e.mult < 1 then addMsg("Not very effective...") end
	elseif e.k == "end" then
		if e.text then addMsg(e.text) end
	end
end

-- health bars drop when the hit lands, not when the move starts (seconds after the hit event, by the move's fx)
local IMPACT = SIMPLE and { lunge = 0.25, shot = 0.55, burst = 0.68 } or { lunge = 0.25, shot = 0.8, burst = 0.35 }

local playing = false
local function playEvents(evs)
	playing = true
	local ended = false
	for _, e in ipairs(evs) do
		if USE_FX_PACK and e.k == "hit" then
			local mv = Data.Moves[e.move]
			task.delay(SPECIAL_IMPACT[e.move] or IMPACT[mv and mv.fx] or 0, applySnap, e.s)
		else
			applySnap(e.s)
		end
		if USE_FX_PACK and e.s then setBolts("me", e.s.myEn); setBolts("foe", e.s.foeEn) end
		if e.k == "end" then ended = true end
		if USE_FX_PACK then playEventFx(e) else playEventOld(e) end
		task.wait(Data.eventTime(e))
	end
	playing = false
	if USE_FX_PACK and not ended then cut("main") end
	if not ended then canAct = true; showPage("main"); refreshMoves() end
end

EvStart.OnClientEvent:Connect(function(info)
	canAct = false
	tweenFade(0, 0.25)
	pcall(function() plr:RequestStreamAsync(info.pos) end)
	local stageInst = workspace:WaitForChild(info.stage, 8)
	if stageInst then
		local t0 = os.clock()
		repeat task.wait(0.1) until (stageInst:FindFirstChild("FoeModel") and stageInst.FoeModel:FindFirstChildWhichIsA("BasePart", true) and stageInst:FindFirstChild("MyModel") and stageInst.MyModel:FindFirstChildWhichIsA("BasePart", true)) or os.clock() - t0 > 6
	end
	state = { stage = stageInst, myMax = info.myMax, foeMax = info.foeMax, myEl = info.myEl, foeEl = info.foeEl,
		myEn = info.s.myEn, foeEn = info.s.foeEn, myHp = info.s.myHp, foeHp = info.s.foeHp }
	if not state.stage then fade.BackgroundTransparency = 1; return end
	setCamera()
	foeP.nm.Text = info.foeName .. "  (" .. info.foeEl .. ")"; meP.nm.Text = info.myName .. "  (" .. info.myEl .. ")"
	hud.Visible = true
	hideOtherGuis(true)
	applySnap(info.s)
	setMoves(info.myMoves or Data.movesFor("Wood"))
	if USE_FX_PACK then
		startMotion()
		introFx(info.foeName)
		setBolts("me", state.myEn); setBolts("foe", state.foeEn)
		if info.hint then addMsg(info.hint, "foe"); glow("foe", Color3.fromRGB(255, 120, 30), true) end
	else
		tweenFade(1, 0.3)
		addMsg("A wild " .. info.foeName .. " has appeared!", "foe")
		task.wait(1.2)
	end
	canAct = true; showPage("main"); refreshMoves()
end)

EvEvents.OnClientEvent:Connect(function(data) task.spawn(playEvents, data) end)

EvEnd.OnClientEvent:Connect(function(result)
	canAct = false
	while playing do task.wait(0.1) end
	tweenFade(0, 0.3)
	hud.Visible = false
	hideOtherGuis(false)
	darken(false)
	for _, c in ipairs(msgHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	if USE_FX_PACK then
		stopMotion()
		FX.Cleanup()
		popLbl.TextTransparency = 1; popLbl.TextStrokeTransparency = 1
	end
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = normalFov
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
	state = nil
	task.wait(0.15)
	tweenFade(1, 0.35)
end)
