-- BaseServer: one plot per player (6 plots). Delivered spirits sit in 6 slots on the plot and earn cash
-- per second. Players can sell a spirit (60 x its cash per second) with a prompt on its ball.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Data = require(RS:WaitForChild("SpiritData"))
local fn = SS:WaitForChild("TryDeliver")
local CollectionService = game:GetService("CollectionService")
local Models = require(RS:WaitForChild("SpiritModels"))
local remote = RS:FindFirstChild("SpiritDelivered")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "SpiritDelivered"; remote.Parent = RS end
local FLY = 0.9   -- seconds a delivered spirit spends flying to its slot (clients animate it)

local SELL_MULT = 60
local OFFS = { Vector3.new(-18,0,-30), Vector3.new(18,0,-30), Vector3.new(-18,0,0), Vector3.new(18,0,0), Vector3.new(-18,0,30), Vector3.new(18,0,30),
	Vector3.new(0,0,-30), Vector3.new(0,0,0), Vector3.new(0,0,30) }   -- slots 7 to 9 are bought (Plot slots upgrade)
local Up = require(RS:WaitForChild("UpgradeData"))
local BASE_SLOTS, MAX_SLOTS = 6, 9
local function slotCount(plr)
	return BASE_SLOTS + math.clamp(plr:GetAttribute("UpSlots") or 0, 0, MAX_SLOTS - BASE_SLOTS)
end
local grey = Workspace:WaitForChild("GreyBox")
local plots = {}
for i = 1, 6 do plots[i] = grey:WaitForChild("Plot" .. i) end

local slotFolder = Workspace:FindFirstChild("BaseSlots")
if slotFolder then slotFolder:Destroy() end
slotFolder = Instance.new("Folder"); slotFolder.Name = "BaseSlots"; slotFolder.Parent = Workspace

local function slotCF(pad, i)
	return pad.CFrame * CFrame.new(OFFS[i].X, pad.Size.Y / 2, OFFS[i].Z)
end

-- slot markers and a sign per plot
for i, pad in ipairs(plots) do
	for k = 1, MAX_SLOTS do
		local m = Instance.new("Part")
		m:SetAttribute("Slot", k); m:SetAttribute("PlotIdx", i)
		m.Name = "SlotMarker"; m.Shape = Enum.PartType.Cylinder
		m.Size = Vector3.new(0.3, 16, 16)
		m.CFrame = slotCF(pad, k) * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.rad(90))
		m.Anchored = true; m.CanCollide = false; m.CanQuery = false; m.CastShadow = false
		m.Material = Enum.Material.SmoothPlastic; m.Color = Color3.fromRGB(70, 78, 96)
		if k > BASE_SLOTS then m.Transparency = 1 end
		m.Parent = slotFolder
	end
	local sign = pad:FindFirstChild("Sign")
	if sign then sign:Destroy() end
	local bb = Instance.new("BillboardGui"); bb.Name = "Sign"; bb.Adornee = pad
	bb.Size = UDim2.fromOffset(220, 40); bb.StudsOffsetWorldSpace = Vector3.new(0, 22, 0)
	bb.AlwaysOnTop = false; bb.MaxDistance = 150; bb.Parent = pad
	local t = Instance.new("TextLabel"); t.Name = "T"; t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack; t.TextSize = 22; t.TextColor3 = Color3.new(1, 1, 1); t.TextStrokeTransparency = 0.3
	t.Text = "Empty plot"; t.Parent = bb
	pad:SetAttribute("Owner", "")
end

local function showMarkers(plotIdx, n)
	for _, m in ipairs(slotFolder:GetChildren()) do
		if m:GetAttribute("PlotIdx") == plotIdx then m.Transparency = (m:GetAttribute("Slot") <= n) and 0 or 1 end
	end
end

local owner, bases = {}, {}   -- owner[plr] = plot index; bases[plr] = { [slot] = {item=, ball=} }
local lastFull = {}

local function perSec(it)
	local v = Data.RarityCash[it.rarity] or 1
	if it.mutation == "Shiny" then v *= 2 end
	if it.mutation == "Big" then v *= 3 end
	return v
end

local function recalc(plr)
	local b = bases[plr]; if not b then return end
	local total, n = 0, 0
	for i = 1, MAX_SLOTS do if b[i] then total += perSec(b[i].item); n += 1 end end
	local incomeMult = 1 + Up.ById.Income.perLevel * math.clamp(plr:GetAttribute("UpIncome") or 0, 0, Up.ById.Income.maxLevel)
	plr:SetAttribute("CashPerSec", total * incomeMult)
	plr:SetAttribute("BaseCount", n)
end

local wired = setmetatable({}, { __mode = "k" })
local function wire(plr)
	if wired[plr] then return end
	wired[plr] = true
	plr:GetAttributeChangedSignal("UpSlots"):Connect(function()
		if owner[plr] then
			plr:SetAttribute("BaseSlots", slotCount(plr))
			showMarkers(owner[plr], slotCount(plr))
		end
	end)
	plr:GetAttributeChangedSignal("UpIncome"):Connect(function() recalc(plr) end)
end

local function sell(plr, i)
	local b = bases[plr]; if not b or not b[i] then return end
	local e = b[i]
	plr:SetAttribute("Cash", (plr:GetAttribute("Cash") or 0) + SELL_MULT * perSec(e.item))
	if e.model then e.model:Destroy() end; b[i] = nil
	recalc(plr)
end

local function place(plr, i, it, delay)
	-- the spirit stands on its slot as its real model; with a delay, it appears when the flying copy lands
	local pad = plots[owner[plr]]
	local e = { item = it }
	bases[plr][i] = e
	local cf = slotCF(pad, i) * CFrame.new(0, 0.42, 0)
	local function build()
		if not (bases[plr] and bases[plr][i] == e) then return end
		local model = Models.Has(it.name) and Models.Build(it.name, cf) or Models.BuildOrb(it, cf)
		model:SetAttribute("Ready", true)
		if it.mutation == "Big" then model:SetAttribute("Scale", 1.3) end
		local first
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p ~= model.PrimaryPart then first = p; break end
		end
		if it.mutation == "Shiny" and first then
			local sp = Instance.new("Sparkles"); sp.SparkleColor = Color3.new(1, 1, 0.6); sp.Parent = first
		end
		local hit = Instance.new("Part")
		hit.Name = "SellPoint"; hit.Size = Vector3.new(3, 3, 3); hit.Transparency = 1
		hit.Anchored = true; hit.CanCollide = false; hit.CanQuery = false; hit.CanTouch = false; hit.CastShadow = false
		hit.CFrame = cf * CFrame.new(0, 1.8, 0)
		hit.Parent = model
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Sell for " .. (SELL_MULT * perSec(it))
		pp.ObjectText = ((it.mutation ~= "None") and (it.mutation .. " ") or "") .. it.name .. " (" .. it.rarity .. ")"
		pp.HoldDuration = 0.5; pp.MaxActivationDistance = 12; pp.RequiresLineOfSight = false
		pp.Parent = hit
		pp.Triggered:Connect(function(who)
			if who == plr then sell(plr, i) end
		end)
		model.Parent = pad
		CollectionService:AddTag(model, "SpiritVisual")
		e.model = model
	end
	if delay and delay > 0 then task.delay(delay, build) else build() end
	return cf.Position
end

-- saving (DataStore). If a load fails we do NOT save, so a bad load can never wipe real progress.
local DSS = game:GetService("DataStoreService")
local okStore, store = pcall(function() return DSS:GetDataStore("StormSpiritsV1") end)
if not okStore then
	-- Not published: use an in-memory stand-in so the save/load logic can still be tested in Studio.
	-- It forgets everything when the server stops. A published game uses the real DataStore.
	warn("[BaseServer] DataStore unavailable (place not published). Using an in-memory test store.")
	local HttpService = game:GetService("HttpService")
	local mem = {}
	store = {
		GetAsync = function(_, k) local v = mem[k]; return v and HttpService:JSONDecode(v) or nil end,
		SetAsync = function(_, k, v) mem[k] = HttpService:JSONEncode(v) end,
	}
end
local loaded = {}
local function keyOf(plr) return "p_" .. plr.UserId end

local function loadData(plr)
	if not store then return false, nil end
	for attempt = 1, 3 do
		local ok, res = pcall(function() return store:GetAsync(keyOf(plr)) end)
		if ok then return true, res end
		warn("[BaseServer] load failed (" .. attempt .. "): " .. tostring(res))
		task.wait(1.5)
	end
	return false, nil
end

local function saveData(plr)
	if not store or not loaded[plr] or not bases[plr] then return end
	local slots = {}
	for k = 1, MAX_SLOTS do
		local e = bases[plr][k]
		if e then slots[#slots + 1] = { name = e.item.name, rarity = e.item.rarity, mutation = e.item.mutation } end
	end
	local payload = {
		cash = plr:GetAttribute("Cash") or 0, slots = slots,
		up = { health = plr:GetAttribute("UpHealth") or 0, bag = plr:GetAttribute("UpBag") or 0,
			slots = plr:GetAttribute("UpSlots") or 0, income = plr:GetAttribute("UpIncome") or 0 },
		coils = plr:GetAttribute("CoilsOwned") or "",
		shields = plr:GetAttribute("Shields") or 0,
	}
	for attempt = 1, 3 do
		local ok, err = pcall(function() store:SetAsync(keyOf(plr), payload) end)
		if ok then return true end
		warn("[BaseServer] save failed (" .. attempt .. "): " .. tostring(err))
		task.wait(1.5)
	end
	return false
end

local function assign(plr)
	if owner[plr] then return end
	for i = 1, 6 do
		if plots[i]:GetAttribute("Owner") == "" then
			owner[plr] = i
			plots[i]:SetAttribute("Owner", plr.Name)
			plots[i].Sign.T.Text = plr.DisplayName .. "'s base"
			plr:SetAttribute("Plot", i)
			plr:SetAttribute("BaseSlots", BASE_SLOTS)
			plots[i].Sign.T.Text = plr.DisplayName .. "'s base"
			local ok, data = loadData(plr)
			bases[plr] = {}
			plr:SetAttribute("Cash", 0)
			for _, key in ipairs({ "UpHealth", "UpBag", "UpSlots", "UpIncome" }) do plr:SetAttribute(key, 0) end
			plr:SetAttribute("CoilsOwned", "")
			plr:SetAttribute("Shields", 0)
			plr:SetAttribute("ShieldUntil", 0)
			if ok and type(data) == "table" then
				plr:SetAttribute("Cash", tonumber(data.cash) or 0)
				local u = type(data.up) == "table" and data.up or {}
				plr:SetAttribute("UpHealth", math.clamp(tonumber(u.health) or 0, 0, Up.ById.Health.maxLevel))
				plr:SetAttribute("UpBag", math.clamp(tonumber(u.bag) or 0, 0, Up.ById.Bag.maxLevel))
				plr:SetAttribute("UpSlots", math.clamp(tonumber(u.slots) or 0, 0, Up.ById.Slots.maxLevel))
				plr:SetAttribute("UpIncome", math.clamp(tonumber(u.income) or 0, 0, Up.ById.Income.maxLevel))
				plr:SetAttribute("CoilsOwned", type(data.coils) == "string" and data.coils or "")
				plr:SetAttribute("Shields", math.clamp(tonumber(data.shields) or 0, 0, Up.Items.Shield.max))
				for _, it in ipairs(data.slots or {}) do
					if Data.RarityCash[it.rarity] then
						for k = 1, slotCount(plr) do
							if not bases[plr][k] then place(plr, k, { name = it.name, rarity = it.rarity, mutation = it.mutation or "None" }); break end
						end
					end
				end
			end
			loaded[plr] = ok
			plr:SetAttribute("BaseSlots", slotCount(plr))
			showMarkers(i, slotCount(plr))
			wire(plr)
			plr:SetAttribute("DataLoaded", ok)
			recalc(plr)
			return
		end
	end
end

local function release(plr)
	local i = owner[plr]; if not i then return end
	saveData(plr)
	loaded[plr] = nil
	for k = 1, MAX_SLOTS do local e = bases[plr][k]; if e and e.model then e.model:Destroy() end end
	showMarkers(i, BASE_SLOTS)
	plots[i]:SetAttribute("Owner", ""); plots[i].Sign.T.Text = "Empty plot"
	owner[plr] = nil; bases[plr] = nil; lastFull[plr] = nil
end

fn.OnInvoke = function(plr, items)
	local b = bases[plr]; if not b then return 0 end
	local accepted = 0
	local list = {}
	for _, it in ipairs(items) do
		local free
		for k = 1, slotCount(plr) do if not b[k] then free = k; break end end
		if not free then break end
		local delay = 0.18 * accepted
		local pos = place(plr, free, it, delay + FLY - 0.05)
		list[#list + 1] = { name = it.name, rarity = it.rarity, mutation = it.mutation, pos = pos, delay = delay, dur = FLY }
		accepted += 1
	end
	recalc(plr)
	if #list > 0 then remote:FireAllClients(plr, list) end
	if accepted < #items and os.clock() - (lastFull[plr] or -10) > 3 then
		lastFull[plr] = os.clock()
		plr:SetAttribute("BaseFullAt", os.clock())
	end
	return accepted
end

-- test hook: pretend the player left and came back
local testRejoin = Instance.new("BindableFunction")
testRejoin.Name = "TestRejoin"
testRejoin.Parent = SS
testRejoin.OnInvoke = function(plr) release(plr); assign(plr); return true end

Players.PlayerAdded:Connect(assign)
Players.PlayerRemoving:Connect(release)
for _, p in ipairs(Players:GetPlayers()) do assign(p) end

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do task.spawn(saveData, plr) end
	end
end)
game:BindToClose(function()
	for _, plr in ipairs(Players:GetPlayers()) do task.spawn(saveData, plr) end
	task.wait(3)
end)

Workspace:SetAttribute("BaseReady", true)

while true do
	task.wait(1)
	for _, plr in ipairs(Players:GetPlayers()) do
		local r = plr:GetAttribute("CashPerSec") or 0
		if r > 0 then plr:SetAttribute("Cash", (plr:GetAttribute("Cash") or 0) + r) end
	end
end
