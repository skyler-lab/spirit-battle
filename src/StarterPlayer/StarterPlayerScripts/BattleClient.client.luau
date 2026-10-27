-- BattleClient: plain placeholder battle UI + camera + simple effects. Real art comes later; the flow is what is being tested.
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
local moveButtons = {}
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
local mi = 0
for _, id in ipairs(Data.MoveOrder) do
	local mv = Data.Moves[id]
	local lbl = mv.name .. (mv.cost > 0 and ("  (" .. mv.cost .. ")") or ("  (+" .. (mv.gain or 0) .. ")"))
	local col = (mv.kind == "attack") and Color3.fromRGB(190, 70, 50) or (mv.kind == "block" and Color3.fromRGB(60, 120, 190) or Color3.fromRGB(200, 160, 40))
	local b = button("fight", lbl, cell(mi % 2, math.floor(mi / 2)), UDim2.fromOffset(W, H), col, function()
		if canAct and state and state.myEn >= mv.cost then canAct = false; showPage("fight"); EvMove:FireServer(id) end
	end)
	moveButtons[id] = b; mi += 1
end
button("fight", "BACK", cell(0, 2), UDim2.fromOffset(W * 2 + G, H), Color3.fromRGB(80, 80, 80), function() showPage("main") end)
local function refreshMoves()
	for id, b in pairs(moveButtons) do
		local ok = state and state.myEn >= Data.Moves[id].cost
		b.TextTransparency = ok and 0 or 0.6; b.BackgroundTransparency = ok and 0 or 0.5
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

local playing = false
local function playEvents(evs)
	playing = true
	local ended = false
	for _, e in ipairs(evs) do
		applySnap(e.s)
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
			ended = true
			if e.text then addMsg(e.text) end
		end
		task.wait(Data.EventTime[e.k] or 0.3)
	end
	playing = false
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
	tweenFade(1, 0.3)
	addMsg("A wild " .. info.foeName .. " has appeared!", "foe")
	task.wait(1.2)
	canAct = true; showPage("main"); refreshMoves()
end)

EvEvents.OnClientEvent:Connect(function(data) task.spawn(playEvents, data) end)

EvEnd.OnClientEvent:Connect(function(result)
	canAct = false
	while playing do task.wait(0.1) end
	tweenFade(0, 0.3)
	hud.Visible = false
	hideOtherGuis(false)
	for _, c in ipairs(msgHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = normalFov
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then cam.CameraSubject = hum end
	state = nil
	task.wait(0.15)
	tweenFade(1, 0.35)
end)
