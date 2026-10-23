-- CoilServer: the coil shop in the middle of the safe zone. A coil only changes the player's SpeedMult
-- (SpeedServer turns that into walk speed). A coil must be bought first (UpgradeServer sets CoilsOwned).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Coils = require(RS:WaitForChild("CoilData"))

local remote = RS:FindFirstChild("CoilEquip")
if not remote then remote = Instance.new("RemoteEvent"); remote.Name = "CoilEquip"; remote.Parent = RS end

local shop = Workspace:WaitForChild("GreyBox"):WaitForChild("CenterShop")
local old = shop:FindFirstChild("ShopPrompt"); if old then old:Destroy() end
local pp = Instance.new("ProximityPrompt")
pp.Name = "ShopPrompt"; pp.ActionText = "Open"; pp.ObjectText = "Shop"
pp.HoldDuration = 0; pp.MaxActivationDistance = 16; pp.RequiresLineOfSight = false
pp.Parent = shop

local old2 = shop:FindFirstChild("ShopSign"); if old2 then old2:Destroy() end
local bb = Instance.new("BillboardGui"); bb.Name = "ShopSign"; bb.Adornee = shop
bb.Size = UDim2.fromOffset(200, 40); bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0); bb.MaxDistance = 150; bb.AlwaysOnTop = false
bb.Parent = shop
local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
t.Font = Enum.Font.GothamBlack; t.TextSize = 24; t.TextColor3 = Color3.new(1, 1, 1); t.TextStrokeTransparency = 0.3
t.Text = "Shop"; t.Parent = bb

local function apply(plr, id)
	local mult = 1
	for _, c in ipairs(Coils.List) do if c.id == id then mult = 1 + c.pct end end
	plr:SetAttribute("Coil", mult > 1 and id or "")
	plr:SetAttribute("SpeedMult", mult)
end

remote.OnServerEvent:Connect(function(plr, id)
	if type(id) ~= "string" then return end
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - shop.Position).Magnitude > 40 then return end  -- must be near the shop
	if id ~= "" and not string.find(";" .. (plr:GetAttribute("CoilsOwned") or "") .. ";", ";" .. id .. ";", 1, true) then return end  -- not owned
	apply(plr, id)
end)

Players.PlayerAdded:Connect(function(plr) plr:SetAttribute("Coil", "") end)
for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("Coil") == nil then p:SetAttribute("Coil", "") end end
