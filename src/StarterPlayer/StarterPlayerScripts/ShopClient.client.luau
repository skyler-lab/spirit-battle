-- ShopClient: TEMPORARY plain shop (upgrades and coils). Plain on purpose, final look comes last.
-- All real work happens on the server (UpgradeServer / CoilServer). This only shows state and sends clicks.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PPS = game:GetService("ProximityPromptService")
local Workspace = game:GetService("Workspace")
local Coils = require(RS:WaitForChild("CoilData"))
local Up = require(RS:WaitForChild("UpgradeData"))
local equipRemote = RS:WaitForChild("CoilEquip")
local buyRemote = RS:WaitForChild("BuyUpgrade")
local plr = Players.LocalPlayer

local function commas(n)
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

local gui = Instance.new("ScreenGui")
gui.Name = "Shop"; gui.ResetOnSpawn = false; gui.DisplayOrder = 20; gui.Enabled = false
gui.Parent = plr:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"; panel.BackgroundColor3 = Color3.fromRGB(30, 30, 40); panel.BorderSizePixel = 0
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5); panel.Size = UDim2.fromScale(0.9, 0.85)
local lim = Instance.new("UISizeConstraint"); lim.MaxSize = Vector2.new(460, 560); lim.Parent = panel
panel.Parent = gui

local function label(parent, text, pos, size, align, maxText)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1; l.Text = text; l.Font = Enum.Font.GothamBold; l.TextColor3 = Color3.new(1, 1, 1)
	l.TextScaled = true; l.TextXAlignment = align or Enum.TextXAlignment.Left; l.Position = pos; l.Size = size
	local c = Instance.new("UITextSizeConstraint"); c.MaxTextSize = maxText or 20; c.Parent = l
	l.Parent = parent
	return l
end

label(panel, "SHOP (prototype)", UDim2.fromScale(0.04, 0.01), UDim2.fromScale(0.5, 0.06))
local cashLabel = label(panel, "Cash: 0", UDim2.fromScale(0.5, 0.01), UDim2.fromScale(0.34, 0.06), Enum.TextXAlignment.Right)
local close = Instance.new("TextButton")
close.Text = "X"; close.Font = Enum.Font.GothamBold; close.TextScaled = true; close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundColor3 = Color3.fromRGB(170, 50, 50); close.BorderSizePixel = 0
close.Position = UDim2.fromScale(0.88, 0.01); close.Size = UDim2.fromScale(0.1, 0.06); close.Parent = panel

local msg = label(panel, "", UDim2.fromScale(0.04, 0.93), UDim2.fromScale(0.92, 0.05), Enum.TextXAlignment.Left, 16)
msg.TextColor3 = Color3.fromRGB(255, 200, 120)

local list = Instance.new("ScrollingFrame")
list.BackgroundTransparency = 1; list.BorderSizePixel = 0
list.Position = UDim2.fromScale(0.03, 0.09); list.Size = UDim2.fromScale(0.94, 0.83)
list.CanvasSize = UDim2.new(0, 0, 0, 0); list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.ScrollBarThickness = 6
local layout = Instance.new("UIListLayout"); layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = list
list.Parent = panel

local rows = {}
local order = 0
local function addRow(key)
	order += 1
	local row = Instance.new("Frame")
	row.BackgroundColor3 = Color3.fromRGB(50, 50, 64); row.BorderSizePixel = 0
	row.Size = UDim2.new(1, -8, 0, 62); row.LayoutOrder = order; row.Parent = list
	local name = label(row, "", UDim2.fromScale(0.03, 0.06), UDim2.fromScale(0.58, 0.46), nil, 20)
	local info = label(row, "", UDim2.fromScale(0.03, 0.52), UDim2.fromScale(0.58, 0.4), nil, 14)
	info.TextColor3 = Color3.fromRGB(190, 190, 205); info.Font = Enum.Font.Gotham
	local btn = Instance.new("TextButton")
	btn.Font = Enum.Font.GothamBold; btn.TextScaled = true; btn.TextColor3 = Color3.new(1, 1, 1); btn.BorderSizePixel = 0
	btn.Position = UDim2.fromScale(0.63, 0.14); btn.Size = UDim2.fromScale(0.35, 0.72); btn.Parent = row
	local bc = Instance.new("UITextSizeConstraint"); bc.MaxTextSize = 18; bc.Parent = btn
	rows[key] = { name = name, info = info, btn = btn }
	return rows[key]
end

local function priceText(price) return price == 0 and "Buy (free)" or ("Buy " .. commas(price)) end

local function owns(id) return string.find(";" .. (plr:GetAttribute("CoilsOwned") or "") .. ";", ";" .. id .. ";", 1, true) ~= nil end

local function say(t) msg.Text = t end
local busy = false
local function purchase(kind, id)
	if busy then return end
	busy = true
	local ok, res, why = pcall(function() return buyRemote:InvokeServer(kind, id) end)
	busy = false
	if not ok then say("Something went wrong.") return end
	if res then say("") else say("Can't buy: " .. tostring(why)) end
end

-- upgrade rows
local descr = {
	Health = function(t, lv) return ("max health %d -> %d"):format(Up.START.Health + t.perLevel * lv, Up.START.Health + t.perLevel * (lv + 1)) end,
	Bag = function(t, lv) return ("followers %d -> %d"):format(Up.START.Bag + t.perLevel * lv, Up.START.Bag + t.perLevel * (lv + 1)) end,
	Slots = function(t, lv) return ("plot slots %d -> %d"):format(Up.START.Slots + t.perLevel * lv, Up.START.Slots + t.perLevel * (lv + 1)) end,
	Income = function(t, lv) return ("base income +%d%% -> +%d%%"):format(t.perLevel * lv * 100 + 0.5, t.perLevel * (lv + 1) * 100 + 0.5) end,
}
for _, t in ipairs(Up.Tracks) do
	local r = addRow("track_" .. t.id)
	r.btn.MouseButton1Click:Connect(function() purchase("track", t.id) end)
end
for _, c in ipairs(Coils.List) do
	local r = addRow("coil_" .. c.id)
	r.btn.MouseButton1Click:Connect(function()
		if owns(c.id) then
			local cur = plr:GetAttribute("Coil") or ""
			equipRemote:FireServer(cur == c.id and "" or c.id)
		else
			purchase("coil", c.id)
		end
	end)
end

local shieldRow = addRow("item_Shield")
shieldRow.btn.MouseButton1Click:Connect(function() purchase("item", "Shield") end)

local function refresh()
	cashLabel.Text = "Cash: " .. commas(plr:GetAttribute("Cash") or 0)
	for _, t in ipairs(Up.Tracks) do
		local r = rows["track_" .. t.id]
		local lv = plr:GetAttribute(t.attr) or 0
		r.name.Text = ("%s  (%d/%d)"):format(t.name, lv, t.maxLevel)
		if lv >= t.maxLevel then
			r.info.Text = "maxed"
			r.btn.Text = "MAX"; r.btn.BackgroundColor3 = Color3.fromRGB(90, 90, 105); r.btn.Active = false
		else
			r.info.Text = descr[t.id](t, lv)
			r.btn.Text = priceText(t.prices[lv + 1] or 0); r.btn.BackgroundColor3 = Color3.fromRGB(60, 150, 70); r.btn.Active = true
		end
	end
	do
		local it = Up.Items.Shield
		local have = plr:GetAttribute(it.attr) or 0
		shieldRow.name.Text = ("%s  (carrying %d/%d)"):format(it.name, have, it.max)
		shieldRow.info.Text = ("no storm damage for %d s. Press F outside the hub"):format(it.seconds)
		if have >= it.max then
			shieldRow.btn.Text = "FULL"; shieldRow.btn.BackgroundColor3 = Color3.fromRGB(90, 90, 105)
		else
			shieldRow.btn.Text = priceText(it.price); shieldRow.btn.BackgroundColor3 = Color3.fromRGB(60, 150, 70)
		end
	end
	local cur = plr:GetAttribute("Coil") or ""
	for _, c in ipairs(Coils.List) do
		local r = rows["coil_" .. c.id]
		r.name.Text = c.name
		r.info.Text = "+" .. math.floor(c.pct * 100 + 0.5) .. "% speed"
		if owns(c.id) then
			local on = (cur == c.id)
			r.btn.Text = on and "Take off" or "Equip"
			r.btn.BackgroundColor3 = on and Color3.fromRGB(110, 110, 130) or Color3.fromRGB(60, 120, 190)
		else
			r.btn.Text = priceText(Up.CoilPrices[c.id] or 0)
			r.btn.BackgroundColor3 = Color3.fromRGB(60, 150, 70)
		end
	end
end
for _, a in ipairs({ "Cash", "Coil", "CoilsOwned", "UpHealth", "UpBag", "UpSlots", "UpIncome", "Shields" }) do
	plr:GetAttributeChangedSignal(a):Connect(refresh)
end
refresh()

local function setOpen(v) gui.Enabled = v; if v then say(""); refresh() end end
close.MouseButton1Click:Connect(function() setOpen(false) end)
PPS.PromptTriggered:Connect(function(prompt, who)
	if who == plr and prompt.Name == "ShopPrompt" then setOpen(not gui.Enabled) end
end)

local shop = Workspace:WaitForChild("GreyBox"):WaitForChild("CenterShop")
RunService.RenderStepped:Connect(function()
	if not gui.Enabled then return end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - shop.Position).Magnitude > 30 then setOpen(false) end
end)
