-- BattleServer: wild spirits in the test area, the "!" alert, and the server-side battle (all rules come from BattleData).
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Data = require(RS:WaitForChild("BattleData"))
local Models = require(RS:WaitForChild("SpiritModels"))
local RunService = game:GetService("RunService")

local remotes = RS:FindFirstChild("BattleRemotes")
if not remotes then remotes = Instance.new("Folder"); remotes.Name = "BattleRemotes"; remotes.Parent = RS end
local function remote(n)
	local e = remotes:FindFirstChild(n)
	if not e then e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = remotes end
	return e
end
local EvStart, EvEvents, EvEnd, EvMove = remote("Start"), remote("Events"), remote("End"), remote("Move")

-- real model if one exists, otherwise a placeholder orb coloured by element
local function buildSpirit(name, cf)
	if Models.Builders[name] then return Models.Build(name, cf) end
	local m = Models.BuildOrb({ name = name, rarity = "Uncommon" }, cf)
	local orb = m:FindFirstChild("Orb")
	local el = Data.Spirits[name] and Data.Spirits[name].element
	if orb and el and Data.ElementColor[el] then orb.Color = Data.ElementColor[el] end
	return m
end

local battles = {}
local wilds = {}
local slot = 0
local ENGAGE = 9

local function snap(b) return { myHp = b.myHp, myEn = b.myEn, foeHp = b.foeHp, foeEn = b.foeEn } end

-- ===== wild spirits =====
local area = workspace:WaitForChild("TestArea")

local function spawnWild(w)
	if w.model then w.model:Destroy() end
	local cf = CFrame.new(w.spot.Position + Vector3.new(0, 1.7, 0)) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
	local model = buildSpirit(w.species, cf)
	model.Name = "Wild_" .. w.species
	model:ScaleTo(1.6)
	local root = model.PrimaryPart
	local bb = Instance.new("BillboardGui")
	bb.Name = "Alert"; bb.Adornee = root; bb.Size = UDim2.fromOffset(46, 46); bb.StudsOffset = Vector3.new(0, 4.5, 0)
	bb.AlwaysOnTop = true; bb.Enabled = false; bb.Parent = root
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundColor3 = Color3.fromRGB(255, 255, 255); t.Text = "!"
	t.TextColor3 = Color3.fromRGB(220, 30, 30); t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.Parent = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = t
	model.Parent = area
	w.model = model; w.alert = bb; w.busy = false; w.cool = 0
end

for _, spot in ipairs(area:GetChildren()) do
	if spot.Name == "WildSpot" and spot:GetAttribute("Species") then
		local w = { spot = spot, species = spot:GetAttribute("Species") }
		table.insert(wilds, w)
		spawnWild(w)
	end
end

-- ===== battle =====
-- the wild spirit picks from its own moves: charges when low on energy, likes its big attack, heals when hurt
local function chooseFoe(b)
	local opts = {}
	local function add(id, n) for _ = 1, n do table.insert(opts, id) end end
	add("Charge", (b.foeEn < 2) and 3 or 1)
	for _, id in ipairs(Data.Spirits[b.foeName].moves) do
		local m = Data.Moves[id]
		if b.foeEn >= m.cost then
			if m.kind == "attack" then add(id, (m.cost >= 5) and 3 or 2)
			elseif m.kind == "heal" and b.foeHp < b.foeMax * 0.5 then add(id, 3)
			elseif m.kind == "block" then add(id, 1) end
		end
	end
	return opts[math.random(#opts)]
end

-- one spirit's move as events: its "used X!" line, then its effect. Blocks were already decided for both sides:
-- targetBlockCost is the cost of the other side's block move, or nil when it is not blocking.
local function act(b, side, id, targetBlockCost, push)
	local m = Data.Moves[id]
	local isMe = side == "me"
	local other = isMe and "foe" or "me"
	push({ k = "say", who = side, move = id, text = (isMe and b.myName or b.foeName) .. " used " .. m.name .. "!" })
	if m.kind == "charge" then
		if isMe then b.myEn = math.min(Data.MaxEnergy, b.myEn + m.gain) else b.foeEn = math.min(Data.MaxEnergy, b.foeEn + m.gain) end
		push({ k = "fx", type = "charge", who = side })
	elseif m.kind == "block" then
		push({ k = "fx", type = "block", who = side, move = id })
	elseif m.kind == "heal" then
		local before = isMe and b.myHp or b.foeHp
		if isMe then b.myHp = math.min(b.myMax, b.myHp + m.heal) else b.foeHp = math.min(b.foeMax, b.foeHp + m.heal) end
		push({ k = "heal", who = side, amt = (isMe and b.myHp or b.foeHp) - before, move = id })
	elseif m.kind == "attack" then
		if targetBlockCost then
			-- a block that stops an attack refunds its own cost
			if isMe then b.foeEn = math.min(Data.MaxEnergy, b.foeEn + targetBlockCost) else b.myEn = math.min(Data.MaxEnergy, b.myEn + targetBlockCost) end
			push({ k = "blocked", who = other, by = side, move = id })
		else
			local mult = isMe and Data.multiplier(b.myEl, b.foeEl) or Data.multiplier(b.foeEl, b.myEl)
			local dmg = math.floor(m.power * mult)
			if isMe then b.foeHp = math.max(0, b.foeHp - dmg) else b.myHp = math.max(0, b.myHp - dmg) end
			push({ k = "hit", who = side, dmg = dmg, mult = mult, move = id })
		end
	end
end

local function resolve(b, myId)
	local foeId = chooseFoe(b)
	local mm, fm = Data.Moves[myId], Data.Moves[foeId]
	local evs = {}
	local function push(e) e.s = snap(b); table.insert(evs, e) end
	b.myEn -= mm.cost; b.foeEn -= fm.cost
	local myBlocks, foeBlocks = mm.kind == "block", fm.kind == "block"
	-- blocks go up first, then you act, then the wild spirit. A spirit knocked out before its move does not act.
	local order = {}
	if myBlocks then table.insert(order, "me") end
	if foeBlocks then table.insert(order, "foe") end
	if not myBlocks then table.insert(order, "me") end
	if not foeBlocks then table.insert(order, "foe") end
	for _, side in ipairs(order) do
		if side == "me" and b.myHp > 0 then act(b, "me", myId, foeBlocks and fm.cost or nil, push)
		elseif side == "foe" and b.foeHp > 0 then act(b, "foe", foeId, myBlocks and mm.cost or nil, push) end
	end
	if b.foeHp <= 0 then push({ k = "end", result = "win", text = b.foeName .. " was defeated!" }); return evs, "win" end
	if b.myHp <= 0 then push({ k = "end", result = "lose", text = b.myName .. " fainted!" }); return evs, "lose" end
	b.myEn = math.min(Data.MaxEnergy, b.myEn + Data.TurnEnergy)
	b.foeEn = math.min(Data.MaxEnergy, b.foeEn + Data.TurnEnergy)
	push({ k = "en" })
	return evs, nil
end

local function finish(player, b, result)
	if battles[player] ~= b then return end
	b.over = true
	player:SetAttribute("InBattle", false)
	if b.stage then b.stage:Destroy() end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = false end
	local w = b.wild
	if result == "win" or result == "tame" then
		if w.model then w.model:Destroy(); w.model = nil end
		task.delay(8, function() spawnWild(w) end)
	else
		w.busy = false; w.cool = os.clock() + 4
		if w.alert then w.alert.Enabled = false end
	end
	EvEnd:FireClient(player, result)
	if result == "lose" and hrp then
		task.delay(0.45, function()
			local sp = workspace:FindFirstChild("SpawnLocation")
			if sp and hrp.Parent then hrp.CFrame = sp.CFrame + Vector3.new(0, 4, 0) end
		end)
	end
	battles[player] = nil
end

local function buildStage(player, myName, foeName)
	slot = (slot + 1) % 40
	local P = Vector3.new(4000 + slot * 300, 300, 4000)
	local stage = Instance.new("Model"); stage.Name = "BattleStage_" .. player.UserId; stage.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	local function part(name, size, pos, color)
		local p = Instance.new("Part"); p.Name = name; p.Size = size; p.Position = pos; p.Anchored = true; p.Color = color
		p.Material = Enum.Material.SmoothPlastic; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent = stage; return p
	end
	part("Ground", Vector3.new(120, 2, 120), P - Vector3.new(0, 1, 0), Color3.fromRGB(70, 170, 70))
	local myPlat = P + Vector3.new(-7, 0.5, 8)
	local foePlat = P + Vector3.new(7, 0.5, -8)
	part("PlatMe", Vector3.new(12, 1, 12), myPlat, Color3.fromRGB(235, 160, 50))
	part("PlatFoe", Vector3.new(12, 1, 12), foePlat, Color3.fromRGB(235, 160, 50))
	local function model(name, species, platPos, lookAt)
		local cf = CFrame.lookAt(platPos + Vector3.new(0, 2.7, 0), Vector3.new(lookAt.X, platPos.Y + 2.7, lookAt.Z))
		local m = buildSpirit(species, cf)
		m.Name = name; m:ScaleTo(2)
		-- arena only: a placeholder orb sits on its platform (not floating high) and is not neon, so hits land on it
		local orb = m:FindFirstChild("Orb")
		if orb and m.PrimaryPart then orb.CFrame = m.PrimaryPart.CFrame; orb.Material = Enum.Material.SmoothPlastic end
		m.Parent = stage
		return m
	end
	model("MyModel", myName, myPlat, foePlat)
	model("FoeModel", foeName, foePlat, myPlat)
	stage:SetAttribute("Pos", P)
	stage.Parent = workspace
	return stage
end

local function startBattle(player, w)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	local b = { starting = true, wild = w }
	battles[player] = b
	w.busy = true
	w.alert.Enabled = true
	player:SetAttribute("InBattle", true) -- HealthServer skips storm damage while this is set
	hrp.Anchored = true
	task.wait(0.9)
	if not player.Parent or not hrp.Parent or not w.model then
		w.busy = false; w.alert.Enabled = false; battles[player] = nil; player:SetAttribute("InBattle", false)
		if hrp.Parent then hrp.Anchored = false end
		return
	end
	local myName = player:GetAttribute("BattleSpirit") or "Wood"
	if not Data.Spirits[myName] then myName = "Wood" end
	local foeName = w.species
	b.myName, b.foeName = myName, foeName
	b.myEl, b.foeEl = Data.Spirits[myName].element, Data.Spirits[foeName].element
	b.myHp, b.myMax = Data.Spirits[myName].hp, Data.Spirits[myName].hp
	b.foeHp, b.foeMax = Data.Spirits[foeName].hp, Data.Spirits[foeName].hp
	-- TEST HOOK (Studio only): Workspace attribute TestFoeHpFrac (0 to 1) sets the wild spirit's starting health
	local frac = RunService:IsStudio() and workspace:GetAttribute("TestFoeHpFrac")
	if type(frac) == "number" and frac > 0 and frac <= 1 then b.foeHp = math.max(1, math.floor(b.foeMax * frac)) end
	b.myEn, b.foeEn = Data.StartEnergy, Data.StartEnergy
	b.stage = buildStage(player, myName, foeName)
	b.starting = false
	EvStart:FireClient(player, {
		stage = b.stage.Name, pos = b.stage:GetAttribute("Pos"), myName = myName, foeName = foeName, myEl = b.myEl, foeEl = b.foeEl,
		myMax = b.myMax, foeMax = b.foeMax, s = snap(b), myMoves = Data.movesFor(myName),
	})
	task.delay(1.6, function() if battles[player] == b then b.ready = true end end)
end

local function totalTime(evs)
	local t = 0
	for _, e in ipairs(evs) do t += Data.eventTime(e) end
	-- TEST HOOK (Studio only): Workspace attribute TestEndHold (seconds) holds the last frame of a battle for screenshots
	local hold = RunService:IsStudio() and workspace:GetAttribute("TestEndHold")
	if type(hold) == "number" and evs[#evs] and evs[#evs].k == "end" then t += math.clamp(hold, 0, 15) end
	return t
end

-- ===== taming =====
local function addOwned(player, name)
	local cur = player:GetAttribute("OwnedSpirits") or ""
	local list = (cur == "") and {} or string.split(cur, ";")
	if #list >= Data.Tame.MaxOwned then return false end
	table.insert(list, name)
	player:SetAttribute("OwnedSpirits", table.concat(list, ";"))
	return true
end

local function rollTame(chance)
	-- TEST HOOK (Studio only): Workspace attribute TestTameForce = "success" or "fail" forces the roll
	local force = RunService:IsStudio() and workspace:GetAttribute("TestTameForce")
	if force == "success" then return true elseif force == "fail" then return false end
	return math.random() < chance
end

-- a TAME try uses the player's turn; on a fail the wild spirit still acts
local function tameTurn(player, b)
	local evs = {}
	local function push(e) e.s = snap(b); table.insert(evs, e) end
	local chance = Data.tameChance(b.foeHp, b.foeMax)
	push({ k = "say", who = "me", text = "You tried to tame " .. b.foeName .. "!" })
	local ok = rollTame(chance)
	push({ k = "tame", ok = ok, chance = chance })
	if ok then
		local saved = addOwned(player, b.foeName)
		push({ k = "end", result = "tame", text = saved and ("You tamed " .. b.foeName .. "!") or "Your spirit list is full!" })
		return evs, "tame"
	end
	push({ k = "say", who = "foe", text = b.foeName .. " broke free!" })
	-- the wild spirit's move (the player made no move, so nothing of theirs blocks)
	local foeId = chooseFoe(b)
	b.foeEn -= Data.Moves[foeId].cost
	act(b, "foe", foeId, nil, push)
	if b.myHp <= 0 then push({ k = "end", result = "lose", text = b.myName .. " fainted!" }); return evs, "lose" end
	b.myEn = math.min(Data.MaxEnergy, b.myEn + Data.TurnEnergy)
	b.foeEn = math.min(Data.MaxEnergy, b.foeEn + Data.TurnEnergy)
	push({ k = "en" })
	return evs, nil
end

EvMove.OnServerEvent:Connect(function(player, id)
	local b = battles[player]
	if not b or not b.ready or b.busy or b.over or typeof(id) ~= "string" then return end
	if id == "Run" then
		b.busy = true
		local evs = { { k = "say", who = "me", text = "Got away safely!", s = snap(b) }, { k = "end", result = "run", s = snap(b) } }
		EvEvents:FireClient(player, evs)
		task.delay(totalTime(evs) + 0.2, function() finish(player, b, "run") end)
		return
	end
	if id == "Tame" then
		if Data.tameChance(b.foeHp, b.foeMax) <= 0 then EvEvents:FireClient(player, { { k = "reject", why = "tame", s = snap(b) } }); return end
		b.busy = true
		local evs, result = tameTurn(player, b)
		EvEvents:FireClient(player, evs)
		task.delay(totalTime(evs) + 0.3, function()
			if result then finish(player, b, result) elseif battles[player] == b then b.busy = false end
		end)
		return
	end
	local mv = Data.Moves[id]
	if not mv or not Data.canUse(b.myName, id) then return end
	if b.myEn < mv.cost then EvEvents:FireClient(player, { { k = "reject", s = snap(b) } }); return end
	b.busy = true
	local evs, result = resolve(b, id)
	EvEvents:FireClient(player, evs)
	task.delay(totalTime(evs) + 0.3, function()
		if result then finish(player, b, result) elseif battles[player] == b then b.busy = false end
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	local b = battles[p]
	if b then
		b.over = true
		if b.stage then b.stage:Destroy() end
		b.wild.busy = false
		if b.wild.alert then b.wild.alert.Enabled = false end
		battles[p] = nil
	end
end)

-- walking up to a wild spirit starts the battle
task.spawn(function()
	while true do
		task.wait(0.25)
		for _, p in ipairs(Players:GetPlayers()) do
			if not battles[p] then
				local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					for _, w in ipairs(wilds) do
						if w.model and not w.busy and os.clock() >= w.cool and w.model.PrimaryPart
							and (w.model.PrimaryPart.Position - hrp.Position).Magnitude < ENGAGE then
							task.spawn(startBattle, p, w)
							break
						end
					end
				end
			end
		end
	end
end)

-- teleport pads: a part with a ProximityPrompt and a Dest attribute
local function wirePad(prompt)
	prompt.Triggered:Connect(function(player)
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local dest = prompt.Parent:GetAttribute("Dest")
		if hrp and dest and not battles[player] then hrp.CFrame = CFrame.new(dest) end
	end)
end
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("ProximityPrompt") and d.Parent:GetAttribute("Dest") then wirePad(d) end
end
