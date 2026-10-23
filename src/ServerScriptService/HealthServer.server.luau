-- HealthServer: health, zone drain, storm damage and knockout. All numbers are starting values to tune.
-- Players get attributes: MaxHealth, Health, BagCount (placeholder for the bag), KnockoutCount.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(RS:WaitForChild("ZoneConfig"))
local Storm = require(RS:WaitForChild("StormController"))

local START_HEALTH = 100
local ROUND = 300

-- Damage per second just for standing in a zone. 0 = hub.
local ZONE_DPS = { [0] = 0, 0, 1, 3, 8, 20 }

-- The round's storm level by time (matches the plan's table), 1 to 10.
local TIME_LEVEL = { {0,1},{30,2},{60,3},{90,4},{120,5},{150,6},{195,7},{240,8},{270,9},{290,10},{300,10} }
-- Extra damage per second outside the hub at each storm level.
local STORM_DPS = { [1]=0, [2]=0, [3]=0, [4]=0.5, [5]=1.5, [6]=3, [7]=5, [8]=9, [9]=16, [10]=40 }

-- Damage per second by the SAME storm level the player sees (StormController.LevelFor).
local DPS_KEYS = { {0,0}, {2.2,0.4}, {3.5,1.5}, {4.5,6.5}, {5.5,9}, {6.5,14}, {8.5,28}, {9.5,40}, {10,55} }
local function dpsAtLevel(lv)
	lv = math.clamp(lv, 0, 10)
	for i = 1, #DPS_KEYS - 1 do
		local a, b = DPS_KEYS[i], DPS_KEYS[i + 1]
		if lv <= b[1] then return a[2] + (b[2] - a[2]) * (lv - a[1]) / (b[1] - a[1]) end
	end
	return DPS_KEYS[#DPS_KEYS][2]
end

local function stormLevel(t)
	t = math.clamp(t, 0, ROUND)
	for i = 1, #TIME_LEVEL - 1 do
		local a, b = TIME_LEVEL[i], TIME_LEVEL[i + 1]
		if t <= b[1] then
			return a[2] + (b[2] - a[2]) * (t - a[1]) / (b[1] - a[1])
		end
	end
	return 10
end

local function stormDps(level)
	local lo = math.clamp(math.floor(level), 1, 10)
	local hi = math.min(lo + 1, 10)
	return STORM_DPS[lo] + (STORM_DPS[hi] - STORM_DPS[lo]) * (level - lo)
end

Workspace:SetAttribute("StormDamageLevel", 1)

local function hubSpawn()
	local s = Workspace:FindFirstChild("SpawnLocation")
	return s and (s.Position + Vector3.new(0, 4, 0)) or Vector3.new(0, 10, 0)
end

local function setup(plr)
	if plr:GetAttribute("MaxHealth") == nil then plr:SetAttribute("MaxHealth", START_HEALTH) end
	plr:SetAttribute("Health", plr:GetAttribute("MaxHealth"))
	plr:SetAttribute("BagCount", 0)
	if plr:GetAttribute("KnockoutCount") == nil then plr:SetAttribute("KnockoutCount", 0) end
end

local function knockout(plr)
	plr:SetAttribute("KnockoutCount", (plr:GetAttribute("KnockoutCount") or 0) + 1)
	plr:SetAttribute("BagCount", 0) -- the bag is lost. Spirits already at base are never lost.
	plr:SetAttribute("Health", plr:GetAttribute("MaxHealth"))
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = CFrame.new(hubSpawn())
	end
end

Players.PlayerAdded:Connect(function(plr)
	setup(plr)
	plr.CharacterAdded:Connect(function() setup(plr) end)
end)
for _, plr in ipairs(Players:GetPlayers()) do setup(plr) end

local TICK = 0.2
while true do
	task.wait(TICK)
	local start = Workspace:GetAttribute("RoundStart")
	local t = start and (Workspace:GetServerTimeNow() - start) or 0
	local level = stormLevel(t)
	Workspace:SetAttribute("StormDamageLevel", level)
	local storm = stormDps(level)
	for _, plr in ipairs(Players:GetPlayers()) do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local max = plr:GetAttribute("MaxHealth") or START_HEALTH
			if Config.InHub(root.Position) then
				plr:SetAttribute("Health", max) -- the hub is always safe and refills you
			else
				local seen = Storm.LevelFor(Config.ZoneAt(root.Position), t)
				local dmg = dpsAtLevel(seen) * TICK
				if (plr:GetAttribute("ShieldUntil") or 0) > Workspace:GetServerTimeNow() then dmg = 0 end  -- storm shield item
				if plr:GetAttribute("InBattle") then dmg = 0 end  -- no storm damage during a battle
				plr:SetAttribute("StormSeen", seen)
				local hp = (plr:GetAttribute("Health") or max) - dmg
				if hp <= 0 then
					knockout(plr)
				else
					plr:SetAttribute("Health", hp)
				end
			end
		end
	end
end
