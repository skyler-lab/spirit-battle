-- FollowClient: caught spirits follow their owner. Everyone sees everyone's followers.
-- Also gives spirits lying on the ground a little idle animation.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Models = require(RS:WaitForChild("SpiritModels"))
local Rig = require(RS:WaitForChild("SpiritRig"))
local Data = require(RS:WaitForChild("SpiritData"))
local TweenService = game:GetService("TweenService")

local folder = Instance.new("Folder")
folder.Name = "Followers"
folder.Parent = Workspace

local followers = {}  -- [player] = { [1..3] = rec }
local dying = {}
local changeCount = {}
local MAXF = 3

local function parse(str)
	local t = {}
	if not str or str == "" then return t end
	for entry in string.gmatch(str, "[^;]+") do
		local n, r, m = string.match(entry, "^(.-)|(.-)|(.*)$")
		if n then t[#t + 1] = { name = n, rarity = r, mutation = m } end
	end
	return t
end

local function easeOutBack(x)
	local c = x - 1
	return 1 + 2.70158 * c * c * c + 1.70158 * c * c
end

local function makeRec(item, startPos, owner)
	local cf = CFrame.new(startPos)
	local model = Models.Has(item.name) and Models.Build(item.name, cf) or Models.BuildOrb(item, cf)
	model.Parent = folder
	local rig = Rig.new(model)
	if item.mutation == "Shiny" and rig.parts[1] then
		local sp = Instance.new("Sparkles")
		sp.SparkleColor = Color3.fromRGB(255, 255, 170)
		sp.Parent = rig.parts[1].part
	end
	return {
		owner = owner, item = item, model = model, rig = rig, pos = startPos, yaw = 0, age = 0, speed = 0,
		big = (item.mutation == "Big") and 1.3 or 1, cf = cf, scale = 0.2, dieT = 0,
	}
end

local function sync(plr)
	local items = parse(plr:GetAttribute("BagItems"))
	-- TEMPORARY demo: shows a Wood follower for the local player when nothing real is following
	if plr == Players.LocalPlayer and Workspace:GetAttribute("DevShowcase") and #items == 0 then
		items = { { name = "Wood", rarity = "Common", mutation = "None" }, { name = "Breeze", rarity = "Common", mutation = "None" } }
	end
	local list = followers[plr]
	if not list then list = {}; followers[plr] = list end
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local start = root and (root.Position + Vector3.new(0, 2, 0)) or Vector3.zero
	for i = 1, MAXF do
		local rec, it = list[i], items[i]
		if rec and (not it or rec.item.name ~= it.name or rec.item.mutation ~= it.mutation) then
			table.insert(dying, rec)
			list[i] = nil
		end
		if it and not list[i] then list[i] = makeRec(it, start, plr) end
	end
end

local function watch(plr)
	plr:GetAttributeChangedSignal("BagItems"):Connect(function() changeCount[plr] = (changeCount[plr] or 0) + 1; sync(plr) end)
	sync(plr)
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(function(plr)
	local list = followers[plr]
	if list then for i = 1, MAXF do if list[i] then list[i].model:Destroy() end end end
	followers[plr] = nil
end)

-- spirits on the ground
local groundRigs = {}
local function addVisual(m)
	task.spawn(function()
		local t0 = os.clock()
		while not (m.Parent and m.PrimaryPart and m:GetAttribute("Ready")) and os.clock() - t0 < 5 do task.wait(0.1) end
		if not m.Parent then return end
		groundRigs[m] = Rig.new(m)
		m.AncestryChanged:Connect(function()
			if not m:IsDescendantOf(Workspace) then groundRigs[m] = nil end
		end)
	end)
end
CollectionService:GetInstanceAddedSignal("SpiritVisual"):Connect(addVisual)
for _, m in ipairs(CollectionService:GetTagged("SpiritVisual")) do addVisual(m) end

-- delivery: when spirits are handed in at base, the followers fly to their slots on the plot
local fliers = {}
local function landRing(pos, color)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true; ring.CanCollide = false; ring.CanQuery = false; ring.CanTouch = false; ring.CastShadow = false
	ring.Material = Enum.Material.Neon; ring.Color = color; ring.Transparency = 0.2
	ring.Parent = folder
	local tw = TweenService:Create(ring, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, 11, 11), Transparency = 1 })
	tw:Play()
	task.delay(0.5, function() ring:Destroy() end)
end

local deliverRemote = RS:WaitForChild("SpiritDelivered")
deliverRemote.OnClientEvent:Connect(function(plr, list)
	local flist = followers[plr]
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local start = root and (root.Position + Vector3.new(0, 2, 0)) or Vector3.zero
	for k, d in ipairs(list) do
		local rec
		if flist and flist[k] then
			rec = flist[k]; flist[k] = nil
		else
			-- the bag update may have arrived first and put this follower on its way out
			for di = #dying, 1, -1 do
				local r = dying[di]
				if r.owner == plr and r.item.name == d.name and r.dieT < 1.5 then
					rec = r; table.remove(dying, di); break
				end
			end
		end
		if not rec then rec = makeRec({ name = d.name, rarity = d.rarity, mutation = d.mutation }, start, plr) end
		rec.scale = math.max(rec.scale, 0.2)
		table.insert(fliers, { rec = rec, target = d.pos, t = -(d.delay or 0), dur = d.dur or 0.9, color = Data.RarityColor[d.rarity] or Color3.new(1, 1, 1), landed = false })
	end
	-- make sure the rest of the bag shows up even if the bag update came first
	local n = (changeCount[plr] or 0)
	task.delay(0.5, function()
		if plr.Parent and (changeCount[plr] or 0) == n then sync(plr) end
	end)
end)

local OFFS = {
	{ back = 5, side = 0 },
	{ back = 8, side = -3 },
	{ back = 8, side = 3 },
}

RunService.RenderStepped:Connect(function(dt)
	dt = math.min(dt, 0.1)
	local t = os.clock()

	local ex = { folder }
	local sp = Workspace:FindFirstChild("Spirits")
	if sp then ex[#ex + 1] = sp end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then ex[#ex + 1] = p.Character end end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ex
	params.RespectCanCollide = true

	for plr, list in pairs(followers) do
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local look = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
			look = (look.Magnitude < 0.1) and Vector3.new(0, 0, -1) or look.Unit
			local right = Vector3.new(-look.Z, 0, look.X)
			for i = 1, MAXF do
				local rec = list[i]
				if rec then
					local o = OFFS[i]
					local target = root.Position - look * o.back + right * o.side
					local hit = Workspace:Raycast(target + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), params)
					target = Vector3.new(target.X, hit and hit.Position.Y or (root.Position.Y - 3), target.Z)

					local newPos = rec.pos:Lerp(target, 1 - math.exp(-dt * 6))
					local vel = (newPos - rec.pos) / math.max(dt, 1e-3)
					local hv = Vector3.new(vel.X, 0, vel.Z)
					rec.speed += (hv.Magnitude - rec.speed) * math.min(1, dt * 8)
					rec.pos = newPos
					if (rec.pos - target).Magnitude > 50 then rec.pos = target end

					local desired
					if rec.speed > 1.5 then desired = math.atan2(-hv.X, -hv.Z) else desired = math.atan2(-look.X, -look.Z) end
					local diff = ((desired - rec.yaw + math.pi) % (2 * math.pi)) - math.pi
					rec.yaw += diff * math.min(1, dt * 8)

					rec.age += dt
					local pop = math.min(rec.age / 0.4, 1)
					local arc = math.sin(pop * math.pi) * 3
					local scale = (0.2 + 0.8 * easeOutBack(pop)) * rec.big
					rec.cf = CFrame.new(rec.pos + Vector3.new(0, arc, 0)) * CFrame.Angles(0, rec.yaw, 0)
					rec.scale = scale
					rec.rig:Update(rec.cf, math.clamp(rec.speed / 10, 0, 1), t, dt, scale)
				end
			end
		end
	end

	for i = #fliers, 1, -1 do
		local f = fliers[i]
		local rec = f.rec
		f.t += dt
		if f.t < 0 then
			rec.rig:Update(rec.cf, 0, t, dt, rec.scale)
		else
			if not f.from then
				f.from = rec.pos
				local d = Vector3.new(f.target.X - f.from.X, 0, f.target.Z - f.from.Z)
				f.dist = d.Magnitude
				f.yaw = (d.Magnitude > 0.1) and math.atan2(-d.X, -d.Z) or rec.yaw
			end
			local k = math.clamp(f.t / f.dur, 0, 1)
			local e = k * k * (3 - 2 * k)
			local arc = math.sin(k * math.pi) * (4 + f.dist * 0.08)
			local pos = f.from:Lerp(f.target, e) + Vector3.new(0, arc, 0)
			rec.yaw += (((f.yaw - rec.yaw + math.pi) % (2 * math.pi)) - math.pi) * math.min(1, dt * 10)
			local s = rec.big * (1 + 0.12 * math.sin(k * math.pi))
			rec.pos = pos
			rec.cf = CFrame.new(pos) * CFrame.Angles(0, rec.yaw, 0)
			rec.rig:Update(rec.cf, (k < 1) and 0.9 or 0, t, dt, s)
			if k >= 1 and not f.landed then
				f.landed = true
				landRing(f.target, f.color)
			end
			if f.t >= f.dur + 0.2 then
				rec.model:Destroy()
				table.remove(fliers, i)
			end
		end
	end

	for i = #dying, 1, -1 do
		local rec = dying[i]
		rec.dieT += dt
		local k = math.clamp(rec.dieT / 0.3, 0, 1)
		rec.rig:Update(rec.cf + Vector3.new(0, k * 2, 0), 0, t, dt, math.max(rec.scale * (1 - k), 0.05))
		if k >= 1 then
			rec.model:Destroy()
			table.remove(dying, i)
		end
	end

	for m, rig in pairs(groundRigs) do
		if m.Parent and m.PrimaryPart then
			rig:Update(m.PrimaryPart.CFrame, 0, t, dt, m:GetAttribute("Scale") or 1)
		else
			groundRigs[m] = nil
		end
	end
end)
