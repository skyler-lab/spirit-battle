-- SpiritRig: animates a spirit model made of separate parts, entirely in code (no animation files).
-- Walkers: legs swing, body bobs and leans, leaves bounce. Hoverers: smooth float. Idle: slow breathing.
local Rig = {}
Rig.__index = Rig

function Rig.new(model)
	local self = setmetatable({}, Rig)
	self.model = model
	self.root = model.PrimaryPart or model:FindFirstChild("Root")
	self.parts = {}
	self.hover = model:GetAttribute("Hover") == true
	self.seed = math.random() * 10
	self.phase = 0
	self.scale = 1
	local rootCF = self.root.CFrame
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= self.root then
			local n = p.Name
			local role = "Body"
			if n:sub(1, 3) == "Leg" then role = "Leg" elseif n:sub(1, 3) == "Arm" then role = "Arm" elseif n:sub(1, 4) == "Leaf" or n:sub(1, 4) == "Wisp" then role = "Leaf" elseif n:sub(1, 6) == "Shadow" then role = "Ground" end
			local last = n:sub(-1)
			local side = (last == "L") and 1 or ((last == "R") and -1 or 0)
			local pivot = (role == "Leaf") and Vector3.new(0, -p.Size.Y / 2, 0) or Vector3.new(0, p.Size.Y / 2, 0)
			table.insert(self.parts, { part = p, role = role, side = side, base = rootCF:ToObjectSpace(p.CFrame), size = p.Size, pivot = pivot, idx = #self.parts + 1 })
		end
	end
	-- parts marked Follow (hands, toes) swing around the same joint as the part they follow
	local byName = {}
	for _, r in ipairs(self.parts) do byName[r.part.Name] = r end
	for _, r in ipairs(self.parts) do
		local f = r.part:GetAttribute("Follow")
		local m = f and byName[f]
		if m then
			local pivotRoot = m.base:PointToWorldSpace(m.pivot)
			r.pivot = r.base:PointToObjectSpace(pivotRoot)
			r.role = m.role
			r.side = m.side
		end
	end
	return self
end

function Rig:Update(rootCF, speed01, t, dt, scale)
	scale = math.max(scale or 1, 0.05)
	if math.abs(scale - self.scale) > 1e-3 then
		self.scale = scale
		for _, r in ipairs(self.parts) do r.part.Size = r.size * scale end
	end
	local s = self.scale
	self.phase += dt * (3 + speed01 * 7)
	local ph = self.phase
	self.root.CFrame = rootCF

	local bob, lean, roll
	if self.hover then
		bob = math.sin(t * 2.2 + self.seed) * 0.35 * s + speed01 * 0.15 * s
		roll = math.sin(t * 1.5 + self.seed) * 0.05
		lean = -0.15 * speed01
	else
		bob = math.abs(math.sin(ph)) * 0.28 * s * speed01 + math.sin(t * 2 + self.seed) * 0.05 * s * (1 - speed01)
		lean = -0.14 * speed01
		roll = math.sin(ph) * 0.06 * speed01
	end
	local bodyAdj = CFrame.new(0, bob, 0) * CFrame.Angles(lean, 0, roll)

	for _, r in ipairs(self.parts) do
		local bp = r.base.Position * s
		local base = CFrame.new(bp) * (r.base - r.base.Position)
		local pv = r.pivot * s
		local cf
		if r.role == "Ground" then
			cf = rootCF * base
		elseif r.role == "Body" then
			cf = rootCF * bodyAdj * base
		elseif r.role == "Leg" then
			local ang = math.sin(ph + (r.side > 0 and 0 or math.pi)) * 0.85 * speed01
			cf = rootCF * base * CFrame.new(pv) * CFrame.Angles(ang, 0, 0) * CFrame.new(-pv)
		elseif r.role == "Arm" then
			local ang = -math.sin(ph + (r.side > 0 and 0 or math.pi)) * 0.7 * speed01 + math.sin(t * 2 + r.side) * 0.06
			cf = rootCF * bodyAdj * base * CFrame.new(pv) * CFrame.Angles(ang, 0, 0) * CFrame.new(-pv)
		else
			local w = math.sin(t * 3 + self.seed + r.idx) * 0.14 + speed01 * math.sin(ph * 2 + r.idx) * 0.3
			cf = rootCF * bodyAdj * base * CFrame.new(pv) * CFrame.Angles(w * 0.6, 0, w) * CFrame.new(-pv)
		end
		r.part.CFrame = cf
	end
end

return Rig
