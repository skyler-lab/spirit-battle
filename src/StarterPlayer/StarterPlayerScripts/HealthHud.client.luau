-- HealthHud: grey-box HUD (timer, zone, health bar, knockout fade). Real art comes later.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "StormHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name, size, pos, anchor, textSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Size = size
	l.Position = pos
	l.AnchorPoint = anchor
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextSize = textSize
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.4
	l.Parent = gui
	return l
end

local timer = label("Timer", UDim2.fromOffset(300, 40), UDim2.new(0.5, 0, 0, 14), Vector2.new(0.5, 0), 30)
local zoneLabel = label("Zone", UDim2.fromOffset(300, 24), UDim2.new(0.5, 0, 0, 54), Vector2.new(0.5, 0), 18)

local barBack = Instance.new("Frame")
barBack.Name = "HealthBack"
barBack.Size = UDim2.fromOffset(320, 26)
barBack.Position = UDim2.new(0.5, 0, 1, -26)
barBack.AnchorPoint = Vector2.new(0.5, 1)
barBack.BackgroundColor3 = Color3.fromRGB(30, 34, 44)
barBack.BorderSizePixel = 0
barBack.Parent = gui
Instance.new("UICorner", barBack).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", barBack)
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(10, 12, 18)

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(80, 220, 110)
fill.BorderSizePixel = 0
fill.Parent = barBack
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

local hpText = Instance.new("TextLabel")
hpText.Size = UDim2.fromScale(1, 1)
hpText.BackgroundTransparency = 1
hpText.Font = Enum.Font.GothamBlack
hpText.TextSize = 16
hpText.TextColor3 = Color3.new(1, 1, 1)
hpText.TextStrokeTransparency = 0.5
hpText.ZIndex = 3
hpText.Parent = barBack

local fade = Instance.new("Frame")
fade.Name = "KnockoutFade"
fade.Size = UDim2.fromScale(1, 1)
fade.BackgroundColor3 = Color3.new(0, 0, 0)
fade.BackgroundTransparency = 1
fade.BorderSizePixel = 0
fade.ZIndex = 20
fade.Parent = gui
local koText = Instance.new("TextLabel")
koText.Size = UDim2.fromScale(1, 1)
koText.BackgroundTransparency = 1
koText.Font = Enum.Font.GothamBlack
koText.TextSize = 40
koText.Text = "Swept away! Back to base"
koText.TextColor3 = Color3.new(1, 1, 1)
koText.TextTransparency = 1
koText.ZIndex = 21
koText.Parent = fade

local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("SpiritData"))
local bagLabel = label("Bag", UDim2.fromOffset(200, 26), UDim2.new(0.5, -160, 1, -58), Vector2.new(0, 1), 20)
bagLabel.TextXAlignment = Enum.TextXAlignment.Left
local toast = label("Toast", UDim2.fromOffset(420, 34), UDim2.new(0.5, 0, 0.62, 0), Vector2.new(0.5, 0.5), 26)
toast.TextTransparency = 1
toast.TextStrokeTransparency = 1
local toastT = 0
local lastCatch = player:GetAttribute("LastCatch")
local lastDeliver = player:GetAttribute("LastDeliver")

local cashLabel = label("Cash", UDim2.fromOffset(260, 32), UDim2.new(1, -20, 0, 14), Vector2.new(1, 0), 28)
cashLabel.TextXAlignment = Enum.TextXAlignment.Right
cashLabel.TextColor3 = Color3.fromRGB(255, 225, 90)
local rateLabel = label("Rate", UDim2.fromOffset(260, 24), UDim2.new(1, -20, 0, 48), Vector2.new(1, 0), 18)
rateLabel.TextXAlignment = Enum.TextXAlignment.Right
rateLabel.TextColor3 = Color3.fromRGB(150, 255, 170)
local lastFull = player:GetAttribute("BaseFullAt")
local function commas(n)
	local s = tostring(math.floor(n))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local shown = 100
local lastKO = player:GetAttribute("KnockoutCount") or 0

local function mmss(s)
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end

RunService.RenderStepped:Connect(function(dt)
	-- round timer
	local start = Workspace:GetAttribute("RoundStart")
	local len = Workspace:GetAttribute("RoundLength") or 300
	if start then
		local t = Workspace:GetServerTimeNow() - start
		if t < 240 then
			timer.Text = "Siren in " .. mmss(240 - t)
			timer.TextColor3 = Color3.new(1, 1, 1)
		else
			timer.Text = "SIREN! " .. mmss(len - t)
			timer.TextColor3 = Color3.fromRGB(255, 90, 90)
		end
	end
	-- zone
	local z = player:GetAttribute("Zone") or 0
	zoneLabel.Text = (z == 0) and "Safe at base" or ("Zone " .. z)
	-- health
	local max = math.max(1, player:GetAttribute("MaxHealth") or 100)
	local hp = player:GetAttribute("Health") or max
	shown += (hp - shown) * math.min(1, dt * 10)
	fill.Size = UDim2.fromScale(math.clamp(shown / max, 0, 1), 1)
	local frac = hp / max
	fill.BackgroundColor3 = frac > 0.5 and Color3.fromRGB(80, 220, 110) or (frac > 0.25 and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(235, 70, 70))
	hpText.Text = string.format("%d / %d", math.ceil(hp), max)
	-- bag
	local bc, bm = player:GetAttribute("BagCount") or 0, player:GetAttribute("BagMax") or 3
	bagLabel.Text = string.format("Bag %d/%d", bc, bm)
	bagLabel.TextColor3 = bc >= bm and Color3.fromRGB(255, 120, 120) or Color3.new(1, 1, 1)
	-- cash
	cashLabel.Text = "$" .. commas(player:GetAttribute("Cash") or 0)
	rateLabel.Text = "+" .. commas(player:GetAttribute("CashPerSec") or 0) .. " / sec"
	local bf = player:GetAttribute("BaseFullAt")
	if bf ~= lastFull then
		lastFull = bf
		toast.Text = "Base full! Sell a spirit first"
		toast.TextColor3 = Color3.fromRGB(255, 170, 90)
		toast.TextTransparency = 0
		toast.TextStrokeTransparency = 0.3
		toastT = 2.4
	end
	-- catch toast
	local lc = player:GetAttribute("LastCatch")
	if lc ~= lastCatch then
		lastCatch = lc
		local name, rarity, mut = string.match(lc or "", "^(.-)|(.-)|(.-)|")
		if name then
			toast.Text = (mut ~= "None" and (mut .. " ") or "") .. name .. " (" .. rarity .. ")"
			toast.TextColor3 = Data.RarityColor[rarity] or Color3.new(1, 1, 1)
			toast.TextTransparency = 0
			toast.TextStrokeTransparency = 0.3
			toastT = 1.6
		end
	end
	local ld = player:GetAttribute("LastDeliver")
	if ld ~= lastDeliver then
		lastDeliver = ld
		local n = tonumber(string.match(ld or "", "^(%d+)"))
		if n then
			toast.Text = "Home safe! " .. n .. " spirit" .. (n == 1 and "" or "s") .. " delivered"
			toast.TextColor3 = Color3.fromRGB(150, 255, 170)
			toast.TextTransparency = 0
			toast.TextStrokeTransparency = 0.3
			toastT = 2.2
		end
	end
	if toastT > 0 then
		toastT -= dt
		if toastT < 0.5 then
			toast.TextTransparency = 1 - toastT / 0.5
			toast.TextStrokeTransparency = 1 - toastT / 0.5 * 0.7
		end
	end
	-- knockout fade
	local ko = player:GetAttribute("KnockoutCount") or 0
	if ko ~= lastKO then
		lastKO = ko
		fade.BackgroundTransparency = 0
		koText.TextTransparency = 0
		TweenService:Create(fade, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(koText, TweenInfo.new(1.4), { TextTransparency = 1 }):Play()
	end
end)
