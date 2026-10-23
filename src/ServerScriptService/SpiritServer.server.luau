-- SpiritServer: spawns spirits by zone each round, lets players catch them into a bag, and moves the bag
-- into the base list when they get home. Spirits are shared: if one player takes it, it is gone.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Config = require(RS:WaitForChild("ZoneConfig"))
local Data = require(RS:WaitForChild("SpiritData"))
local Models = require(RS:WaitForChild("SpiritModels"))
local CollectionService = game:GetService("CollectionService")

local rng = Random.new()
local BAG_START = 3
local PICKUP = 4.5
local ROUND = 300

local folder = Workspace:FindFirstChild("Spirits")
if folder then folder:ClearAllChildren() else
	folder = Instance.new("Folder")
	folder.Name = "Spirits"
	folder.Parent = Workspace
end

local bags = {}
local TryDeliver = game:GetService("ServerStorage"):WaitForChild("TryDeliver")
local catchCounter = 0

local function roundFrac()
	local start = Workspace:GetAttribute("RoundStart")
	if not start then return 0 end
	return math.clamp((Workspace:GetServerTimeNow() - start) / ROUND, 0, 1)
end

-- Rarer entries get more likely as the round goes on. boost scales how strongly.
local function pickRarity(zone, boost)
	local list, total = {}, 0
	for i, e in ipairs(Data.ZoneWeights[zone]) do
		local w = e[2] * (1 + roundFrac() * (i - 1) * boost)
		list[i] = w
		total += w
	end
	local r = rng:NextNumber(0, total)
	for i, e in ipairs(Data.ZoneWeights[zone]) do
		r -= list[i]
		if r <= 0 then return e[1] end
	end
	return Data.ZoneWeights[zone][1][1]
end

local function groundAt(x, z)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { folder }
	local hit = Workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), params)
	if hit and hit.Instance.Name ~= "Pillar" then return hit.Position.Y end
	return nil
end

local function spawnSpirit(zone, boost)
	local E = Config.Edges
	for _ = 1, 12 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(E[zone - 1] + 22, E[zone] - 12)
		local x, z = Config.Center.X + math.sin(ang) * r, Config.Center.Z + math.cos(ang) * r
		local gy = groundAt(x, z)
		if gy then
			local rarity = pickRarity(zone, boost or 1)
			local pool = Data.ByRarity[rarity]
			local name = pool[rng:NextInteger(1, #pool)]
			local size = Data.RaritySize[rarity]
			local color = Data.RarityColor[rarity]
			local p = Instance.new("Part")
			p.Name = "Spirit"
			p.Shape = Enum.PartType.Ball
			p.Size = Vector3.new(size, size, size)
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.Material = Enum.Material.Neon
			p.Color = color
			p.Position = Vector3.new(x, gy + size / 2 + 1.6, z)
			p:SetAttribute("SpiritName", name)
			p:SetAttribute("Rarity", rarity)
			p:SetAttribute("Zone", zone)
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 10 + size * 2
			light.Brightness = 1.5
			light.Shadows = false
			light.Parent = p
			if Models.Has(name) then
				local m = Models.Build(name, CFrame.new(x, gy + 0.05, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
				m:SetAttribute("Ready", true)
				m.Parent = p
				CollectionService:AddTag(m, "SpiritVisual")
				p.Transparency = 1
			end
			if rarity == "Mythic" or rarity == "Secret" then
				local beam = Instance.new("Part")
				beam.Name = "Beam"
				beam.Anchored = true
				beam.CanCollide = false
				beam.CanQuery = false
				beam.CanTouch = false
				beam.CastShadow = false
				beam.Material = Enum.Material.Neon
				beam.Color = color
				beam.Transparency = 0.55
				beam.Size = Vector3.new(0.8, 90, 0.8)
				beam.Position = p.Position + Vector3.new(0, 45, 0)
				beam.Parent = p
			end
			p.Parent = folder
			return p
		end
	end
end

local function respawnAll()
	folder:ClearAllChildren()
	for zone = 1, 5 do
		for _ = 1, Data.ZoneCounts[zone] do spawnSpirit(zone, 1) end
	end
end

-- bag helpers
local function bagOf(plr)
	bags[plr] = bags[plr] or {}
	return bags[plr]
end
local function syncBag(plr)
	local bag = bagOf(plr)
	plr:SetAttribute("BagCount", #bag)
	local parts = {}
	for _, it in ipairs(bag) do parts[#parts + 1] = it.name .. "|" .. it.rarity .. "|" .. it.mutation end
	plr:SetAttribute("BagItems", table.concat(parts, ";"))
end
local function setup(plr)
	bags[plr] = {}
	if plr:GetAttribute("BagMax") == nil then plr:SetAttribute("BagMax", BAG_START) end  -- UpgradeServer sets the real value
	syncBag(plr)
end

Players.PlayerAdded:Connect(function(plr)
	setup(plr)
	plr.CharacterAdded:Connect(function() bags[plr] = {}; syncBag(plr) end)
	plr:GetAttributeChangedSignal("KnockoutCount"):Connect(function() bags[plr] = {}; syncBag(plr) end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
	setup(plr)
	plr:GetAttributeChangedSignal("KnockoutCount"):Connect(function() bags[plr] = {}; syncBag(plr) end)
end
Players.PlayerRemoving:Connect(function(plr) bags[plr] = nil end)

local function rollMutation()
	local level = Workspace:GetAttribute("StormDamageLevel") or 1
	local mult = level >= 8 and 2 or 1
	if rng:NextNumber() < (1 / 50) * mult then return "Big" end
	if rng:NextNumber() < (1 / 20) * mult then return "Shiny" end
	return "None"
end

local function catch(plr, spirit)
	local bag = bagOf(plr)
	local item = {
		name = spirit:GetAttribute("SpiritName"),
		rarity = spirit:GetAttribute("Rarity"),
		mutation = rollMutation(),
	}
	table.insert(bag, item)
	spirit:Destroy()
	syncBag(plr)
	catchCounter += 1
	plr:SetAttribute("LastCatch", string.format("%s|%s|%s|%d", item.name, item.rarity, item.mutation, catchCounter))
end

-- new round: fresh spirits
local lastRound = -1
Workspace:GetAttributeChangedSignal("RoundNumber"):Connect(function()
	local n = Workspace:GetAttribute("RoundNumber")
	if n ~= lastRound then lastRound = n; respawnAll() end
end)
repeat task.wait() until Workspace:GetAttribute("RoundStart") and Workspace:GetAttribute("BaseReady")
if lastRound == -1 then lastRound = Workspace:GetAttribute("RoundNumber"); respawnAll() end

-- rare trickle: every 15 s a new spirit appears in each of zones 3 to 5, tilted toward the rarer entries
task.spawn(function()
	while true do
		task.wait(15)
		for zone = 3, 5 do spawnSpirit(zone, 3) end
	end
end)

-- catching and delivering
while true do
	task.wait(0.15)
	for _, plr in ipairs(Players:GetPlayers()) do
		local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local bag = bagOf(plr)
			if Config.InHub(root.Position) then
				if #bag > 0 then
					local n = TryDeliver:Invoke(plr, bag)
					if n and n > 0 then
						for _ = 1, n do table.remove(bag, 1) end
						plr:SetAttribute("LastDeliver", n .. "|" .. tostring(os.clock()))
						syncBag(plr)
					end
				end
			elseif #bag < (plr:GetAttribute("BagMax") or BAG_START) then
				for _, s in ipairs(folder:GetChildren()) do
					if (s.Position - root.Position).Magnitude <= PICKUP + s.Size.X / 2 then
						catch(plr, s)
						if #bagOf(plr) >= (plr:GetAttribute("BagMax") or BAG_START) then break end
					end
				end
			end
		end
	end
end
