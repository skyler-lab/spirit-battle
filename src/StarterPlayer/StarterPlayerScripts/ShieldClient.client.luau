-- ShieldClient: TEMPORARY plain button and F key to use a storm shield. Final look comes last.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Config = require(RS:WaitForChild("ZoneConfig"))
local remote = RS:WaitForChild("UseShield")
local plr = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "ShieldButton"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
gui.Parent = plr:WaitForChild("PlayerGui")

local btn = Instance.new("TextButton")
btn.AnchorPoint = Vector2.new(0, 1); btn.Position = UDim2.new(0, 12, 0.72, 0); btn.Size = UDim2.fromOffset(110, 44)
btn.Font = Enum.Font.GothamBold; btn.TextSize = 16; btn.TextColor3 = Color3.new(1, 1, 1)
btn.BackgroundColor3 = Color3.fromRGB(50, 110, 190); btn.BorderSizePixel = 0; btn.Parent = gui

local function inHub()
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	return not root or Config.InHub(root.Position)
end

local function refresh()
	local have = plr:GetAttribute("Shields") or 0
	local left = (plr:GetAttribute("ShieldUntil") or 0) - Workspace:GetServerTimeNow()
	btn.Visible = have > 0 or left > 0
	if left > 0 then
		btn.Text = ("Shield %.0fs"):format(left); btn.BackgroundColor3 = Color3.fromRGB(60, 150, 70)
	else
		btn.Text = ("Shield x%d (F)"):format(have); btn.BackgroundColor3 = Color3.fromRGB(50, 110, 190)
	end
end

local function use()
	if inHub() then return end
	remote:FireServer()
end
btn.MouseButton1Click:Connect(use)
UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then use() end
end)
game:GetService("RunService").Heartbeat:Connect(refresh)
