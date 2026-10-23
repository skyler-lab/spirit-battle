-- BattleFXPack.Demo (LocalScript, disabled by default)
-- Put this in StarterPlayer.StarterPlayerScripts, tick Enabled, press Play.
-- It builds a test arena far away and starts a controllable battle against a bot:
-- FIGHT / BAG / TEAM / RUN, moves with energy costs, catching, swapping, win/lose.
-- After each battle a new wild appears. Pick RUN to end the demo and clean up.

local Players = game:GetService("Players")
local pack = script.Parent
if not pack:FindFirstChild("Sequencer") then
	pack = game:GetService("ReplicatedStorage"):WaitForChild("BattleFXPack")
end
local Play = require(pack:WaitForChild("BattlePlay"))
local Dialog = require(pack:WaitForChild("BattleDialog"))
local Menu = require(pack:WaitForChild("BattleMenu"))

-- dialog waits for your click; set a number of seconds to auto-advance instead
Dialog.AutoSeconds = nil

local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

local ORIGIN = Vector3.new(2000, 200, 2000)

local arena = Instance.new("Folder")
arena.Name = "BattleFX_DemoArena"
arena.Parent = workspace

local function p(size, color, cf, material)
	local x = Instance.new("Part")
	x.Anchored = true
	x.Size = size
	x.Color = color
	x.Material = material or Enum.Material.SmoothPlastic
	x.CFrame = cf
	x.TopSurface = Enum.SurfaceType.Smooth
	x.BottomSurface = Enum.SurfaceType.Smooth
	x.Parent = arena
	return x
end

p(Vector3.new(160, 2, 160), Color3.fromRGB(70, 200, 60), CFrame.new(ORIGIN))
local playerPlat = p(Vector3.new(16, 1.4, 12), Color3.fromRGB(235, 165, 50), CFrame.new(ORIGIN + Vector3.new(-10, 1.7, -8)))
local enemyPlat = p(Vector3.new(16, 1.4, 12), Color3.fromRGB(235, 165, 50), CFrame.new(ORIGIN + Vector3.new(12, 1.7, 14)))
for i = 1, 14 do
	local a = (i / 14) * math.pi * 2
	local base = ORIGIN + Vector3.new(math.cos(a) * 55, 1, math.sin(a) * 55)
	p(Vector3.new(3, 8, 3), Color3.fromRGB(110, 70, 35), CFrame.new(base + Vector3.new(0, 5, 0)))
	p(Vector3.new(10, 8, 10), Color3.fromRGB(40, 150, 40), CFrame.new(base + Vector3.new(0, 12, 0)))
end

local function creature(name: string, color: Color3): Model
	local m = Instance.new("Model")
	m.Name = name
	local body = p(Vector3.new(3, 3.4, 2.4), color, CFrame.new())
	body.Name = "Body"
	body.Parent = m
	local head = p(Vector3.new(2.2, 2, 2), color:Lerp(Color3.new(1, 1, 1), 0.2), CFrame.new(0, 2.6, -0.2))
	head.Parent = m
	for _, s in {-1, 1} do
		local eye = p(Vector3.new(0.5, 0.6, 0.3), Color3.new(0, 0, 0), CFrame.new(s * 0.55, 2.7, -1.15))
		eye.Parent = m
		local leg = p(Vector3.new(0.9, 1.4, 0.9), color:Lerp(Color3.new(0, 0, 0), 0.3), CFrame.new(s * 0.9, -2.3, 0))
		leg.Parent = m
	end
	m.PrimaryPart = body
	m.Parent = arena
	m:PivotTo(CFrame.new(ORIGIN + Vector3.new(0, -50, 0)))
	return m
end

char.Archivable = true
local avatar = char:Clone()
avatar.Name = "DemoAvatar"
for _, d in avatar:GetDescendants() do
	if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false
	elseif d:IsA("Script") or d:IsA("LocalScript") then d:Destroy() end
end
avatar.Parent = arena
avatar:PivotTo(CFrame.lookAt(ORIGIN + Vector3.new(-2, 5, -24), enemyPlat.Position))

local team = {
	{model = creature("Wood", Color3.fromRGB(120, 200, 80)), name = "Wood", level = 6, hp = 110, maxHp = 110,
		moves = {"Charge", "Bite", "Splash", "Firework"}},
	{model = creature("Breeze", Color3.fromRGB(160, 220, 255)), name = "Breeze", level = 5, hp = 90, maxHp = 90,
		moves = {"Charge", "Shoot", "Sword", "Bomb"}},
}
local wilds = {
	{name = "Ember", color = Color3.fromRGB(255, 120, 40), level = 5, hp = 80, moves = {"Charge", "Bite", "Firework"}},
	{name = "Pebble", color = Color3.fromRGB(150, 150, 160), level = 7, hp = 120, moves = {"Charge", "Sword", "Shield", "Bomb"}},
	{name = "Drip", color = Color3.fromRGB(80, 160, 255), level = 4, hp = 70, moves = {"Charge", "Splash", "Shoot"}},
}
local items = {{name = "Box", count = 5}}
local coins = 523

task.wait(1)
local n = 0
while true do
	n += 1
	local w = wilds[(n - 1) % #wilds + 1]
	local wild = {model = creature(w.name, w.color), name = w.name, level = w.level, hp = w.hp, maxHp = w.hp, moves = w.moves}
	local result = Play.Run({
		playerPlatform = playerPlat,
		enemyPlatform = enemyPlat,
		avatar = avatar,
		team = team,
		wild = wild,
		items = items,
		coins = coins,
		onCoins = function(total) coins = total end,
	})
	print("[BattleFXPack] battle result:", result)
	wild.model:Destroy()
	if result == "run" or result == "lose" then break end
	for _, f in team do f.hp = math.min(f.maxHp, f.hp + 40) end
	task.wait(1)
end

Menu.Destroy()
arena:Destroy()
print("[BattleFXPack] demo finished")
