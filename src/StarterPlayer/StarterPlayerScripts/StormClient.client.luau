-- StormClient: drives this player's own storm from the server round clock and where they stand.
-- Test overrides (Workspace attributes): TestZone, TestRoundTime, StormLevelOverride, RainScale, HailScale, RainQuality.
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Controller = require(ReplicatedStorage:WaitForChild("StormController"))
local Config = require(ReplicatedStorage:WaitForChild("ZoneConfig"))
local player = Players.LocalPlayer

local function roundTime()
	local o = Workspace:GetAttribute("TestRoundTime")
	if type(o) == "number" then return o end
	local start = Workspace:GetAttribute("RoundStart")
	if not start then return 0 end
	return Workspace:GetServerTimeNow() - start
end

local function zoneBlend()
	local o = Workspace:GetAttribute("TestZone")
	if type(o) == "number" then return o end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return 0 end
	return Config.ZoneAt(root.Position)
end

local function targetLevel()
	local override = Workspace:GetAttribute("StormLevelOverride")
	if type(override) == "number" then return override end
	return Controller.LevelFor(zoneBlend(), roundTime())
end

local storm = Controller.new()
RunService.RenderStepped:Connect(function(dt)
	storm:Step(dt, targetLevel(),
		Workspace:GetAttribute("RainScale") or 1,
		Workspace:GetAttribute("HailScale") or 1,
		Workspace:GetAttribute("RainQuality") or 1)
end)
