-- UpgradeServer: buying upgrades with cash. The server checks everything. Levels are player attributes
-- (UpHealth, UpBag, UpSlots, UpIncome) and CoilsOwned ("Chocolate;Red"). BaseServer saves and loads them.
-- BaseServer reacts to UpSlots and UpIncome. This script applies health and follower limit.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Up = require(RS:WaitForChild("UpgradeData"))
local Coils = require(RS:WaitForChild("CoilData"))

local remote = RS:FindFirstChild("BuyUpgrade")
if not remote then remote = Instance.new("RemoteFunction"); remote.Name = "BuyUpgrade"; remote.Parent = RS end
local shop = Workspace:WaitForChild("GreyBox"):WaitForChild("CenterShop")
local Config = require(RS:WaitForChild("ZoneConfig"))
local useShield = RS:FindFirstChild("UseShield")
if not useShield then useShield = Instance.new("RemoteEvent"); useShield.Name = "UseShield"; useShield.Parent = RS end

local function lvl(plr, t) return plr:GetAttribute(t.attr) or 0 end

local function applyAll(plr)
	local h, b = Up.ById.Health, Up.ById.Bag
	local newMax = Up.START.Health + h.perLevel * lvl(plr, h)
	local oldMax = plr:GetAttribute("MaxHealth")
	if oldMax ~= newMax then
		plr:SetAttribute("MaxHealth", newMax)
		if oldMax and newMax > oldMax then plr:SetAttribute("Health", newMax) end
	end
	plr:SetAttribute("BagMax", Up.START.Bag + b.perLevel * lvl(plr, b))
end

local function watch(plr)
	applyAll(plr)
	plr:GetAttributeChangedSignal("UpHealth"):Connect(function() applyAll(plr) end)
	plr:GetAttributeChangedSignal("UpBag"):Connect(function() applyAll(plr) end)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end

local function owns(plr, id)
	return string.find(";" .. (plr:GetAttribute("CoilsOwned") or "") .. ";", ";" .. id .. ";", 1, true) ~= nil
end

local function pay(plr, price)
	local cash = plr:GetAttribute("Cash") or 0
	if cash < price then return false end
	plr:SetAttribute("Cash", cash - price)
	return true
end

remote.OnServerInvoke = function(plr, kind, id)
	if type(kind) ~= "string" or type(id) ~= "string" then return false, "bad request" end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - shop.Position).Magnitude > 40 then return false, "too far from the shop" end
	if plr:GetAttribute("DataLoaded") ~= true then return false, "still loading" end

	if kind == "track" then
		local t = Up.ById[id]
		if not t then return false, "unknown upgrade" end
		local cur = lvl(plr, t)
		if cur >= t.maxLevel then return false, "already maxed" end
		local price = t.prices[cur + 1] or 0
		if not pay(plr, price) then return false, "not enough cash" end
		plr:SetAttribute(t.attr, cur + 1)
		return true, "bought"
	elseif kind == "coil" then
		local found
		for _, c in ipairs(Coils.List) do if c.id == id then found = c end end
		if not found then return false, "unknown coil" end
		if owns(plr, id) then return false, "already owned" end
		local price = Up.CoilPrices[id] or 0
		if not pay(plr, price) then return false, "not enough cash" end
		local cur = plr:GetAttribute("CoilsOwned") or ""
		plr:SetAttribute("CoilsOwned", cur == "" and id or (cur .. ";" .. id))
		return true, "bought"
	end
	if kind == "item" then
		local it = Up.Items[id]
		if not it then return false, "unknown item" end
		local have = plr:GetAttribute(it.attr) or 0
		if have >= it.max then return false, "carrying the most already" end
		if not pay(plr, it.price) then return false, "not enough cash" end
		plr:SetAttribute(it.attr, have + 1)
		return true, "bought"
	end
	return false, "bad request"
end

-- using a shield: only outside the hub, one at a time. HealthServer reads ShieldUntil (server time).
useShield.OnServerEvent:Connect(function(plr)
	local it = Up.Items.Shield
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or Config.InHub(root.Position) then return end
	local now = Workspace:GetServerTimeNow()
	if (plr:GetAttribute("ShieldUntil") or 0) > now then return end
	local have = plr:GetAttribute(it.attr) or 0
	if have <= 0 then return end
	plr:SetAttribute(it.attr, have - 1)
	local untilT = now + it.seconds
	plr:SetAttribute("ShieldUntil", untilT)
	local ff = Instance.new("ForceField"); ff.Name = "StormShield"; ff.Parent = char
	task.delay(it.seconds, function()
		if ff.Parent then ff:Destroy() end
	end)
end)
