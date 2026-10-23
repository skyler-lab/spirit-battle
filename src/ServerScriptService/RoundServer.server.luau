-- RoundServer: the one server clock. Every round is ROUND seconds, then it resets.
-- Clients read RoundStart (server time) and work out RoundTime themselves, so the clock is smooth.
-- Also tells each player's attributes which zone they are standing in.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Config = require(RS:WaitForChild("ZoneConfig"))

local ROUND = 300
Workspace:SetAttribute("RoundLength", ROUND)
Workspace:SetAttribute("RoundNumber", 0)

local function startRound()
	Workspace:SetAttribute("RoundNumber", (Workspace:GetAttribute("RoundNumber") or 0) + 1)
	Workspace:SetAttribute("RoundStart", Workspace:GetServerTimeNow())
end
startRound()

while true do
	task.wait(0.25)
	if Workspace:GetServerTimeNow() - Workspace:GetAttribute("RoundStart") >= ROUND then
		startRound()
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root then
			plr:SetAttribute("Zone", Config.WholeZone(root.Position))
			plr:SetAttribute("InHub", Config.InHub(root.Position))
		end
	end
end
