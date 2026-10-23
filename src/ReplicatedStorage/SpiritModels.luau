-- SpiritModels: builds chunky multi-part spirit models. Parts are named by role so SpiritRig can animate them:
-- Leg*/Arm* swing, Leaf* wobble, everything else moves with the body. Front of a model faces -Z.
local Data = require(script.Parent:WaitForChild("SpiritData"))
local M = {}
local SC = 0.65

local function newRoot(cf)
	local model = Instance.new("Model")
	local root = Instance.new("Part")
	root.Name = "Root"; root.Size = Vector3.new(1, 1, 1); root.Transparency = 1
	root.Anchored = true; root.CanCollide = false; root.CanQuery = false; root.CanTouch = false; root.CastShadow = false
	root.CFrame = cf
	root.Parent = model
	model.PrimaryPart = root
	return model, root
end

local function mk(model, name, size, offset, color, rot, mat)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size * SC
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Color = color
	p.CFrame = model.PrimaryPart.CFrame * CFrame.new(offset * SC) * (rot or CFrame.new())
	p.Parent = model
	return p
end

-- a leaf grows from a bottom point and tilts out from there
local function leaf(model, name, bottom, size, color, yaw, roll)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size * SC
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Material = Enum.Material.SmoothPlastic; p.Color = color
	p.CFrame = model.PrimaryPart.CFrame * CFrame.new(bottom * SC) * CFrame.Angles(0, yaw, roll) * CFrame.new(0, p.Size.Y / 2, 0)
	p.Parent = model
	return p
end

M.Builders = {}

M.Builders.Wood = function(cf)
	local model = newRoot(cf)
	local dark, bark, light = Color3.fromRGB(96, 66, 42), Color3.fromRGB(125, 86, 55), Color3.fromRGB(170, 125, 85)
	local cap, ridge, deep = Color3.fromRGB(214, 176, 126), Color3.fromRGB(70, 46, 30), Color3.fromRGB(60, 38, 26)
	local limb, toe = Color3.fromRGB(150, 106, 70), Color3.fromRGB(120, 84, 56)

	-- body
	mk(model, "BodyLower", Vector3.new(2.4, 1.1, 2.0), Vector3.new(0, 1.65, 0), dark)
	mk(model, "BodyUpper", Vector3.new(2.2, 1.1, 1.9), Vector3.new(0, 2.75, 0), bark)
	mk(model, "BodyCap", Vector3.new(2.0, 0.45, 1.7), Vector3.new(0, 3.52, 0), cap, CFrame.Angles(0, math.rad(45), 0))
	mk(model, "Belly", Vector3.new(1.4, 0.8, 0.08), Vector3.new(0, 1.65, -1.03), light)

	-- bark ridges and a knot
	for _, x in ipairs({ 1.23, -1.23 }) do
		mk(model, "RidgeSide" .. (x > 0 and "A" or "B"), Vector3.new(0.07, 0.9, 0.18), Vector3.new(x, 1.65, -0.5), ridge)
		mk(model, "RidgeSideC" .. (x > 0 and "A" or "B"), Vector3.new(0.07, 0.9, 0.18), Vector3.new(x, 1.65, 0.4), ridge)
	end
	mk(model, "RidgeBack1", Vector3.new(0.18, 0.9, 0.07), Vector3.new(-0.6, 1.65, 1.03), ridge)
	mk(model, "RidgeBack2", Vector3.new(0.18, 0.9, 0.07), Vector3.new(0.5, 1.65, 1.03), ridge)
	mk(model, "RidgeBack3", Vector3.new(0.18, 0.8, 0.07), Vector3.new(0, 2.8, 0.97), ridge)
	mk(model, "KnotOuter", Vector3.new(0.07, 0.55, 0.55), Vector3.new(1.13, 2.85, 0.35), Color3.fromRGB(92, 62, 40))
	mk(model, "KnotInner", Vector3.new(0.09, 0.3, 0.3), Vector3.new(1.145, 2.85, 0.35), deep)

	-- legs with toes
	for _, s in ipairs({ { "L", 0.65 }, { "R", -0.65 } }) do
		local leg = mk(model, "Leg" .. s[1], Vector3.new(0.95, 1.1, 1.05), Vector3.new(s[2], 0.55, 0), Color3.fromRGB(86, 58, 38))
		local t = mk(model, "Toe" .. s[1], Vector3.new(0.9, 0.3, 0.45), Vector3.new(s[2], 0.15, -0.72), toe)
		t:SetAttribute("Follow", "Leg" .. s[1])
	end

	-- arms with hands
	for _, s in ipairs({ { "L", 1.5 }, { "R", -1.5 } }) do
		mk(model, "Arm" .. s[1], Vector3.new(0.7, 1.2, 0.75), Vector3.new(s[2], 2.65, 0), limb)
		local h = mk(model, "Hand" .. s[1], Vector3.new(0.78, 0.4, 0.82), Vector3.new(s[2], 2.05, 0), cap)
		h:SetAttribute("Follow", "Arm" .. s[1])
	end

	-- face: big eyes with shine, rosy cheeks, smile
	local black, white = Color3.fromRGB(28, 28, 34), Color3.fromRGB(255, 255, 255)
	mk(model, "EyeL", Vector3.new(0.5, 0.62, 0.14), Vector3.new(0.58, 2.85, -1.0), black)
	mk(model, "EyeR", Vector3.new(0.5, 0.62, 0.14), Vector3.new(-0.58, 2.85, -1.0), black)
	mk(model, "ShineL", Vector3.new(0.17, 0.17, 0.06), Vector3.new(0.7, 3.03, -1.08), white)
	mk(model, "ShineR", Vector3.new(0.17, 0.17, 0.06), Vector3.new(-0.46, 3.03, -1.08), white)
	mk(model, "ShineL2", Vector3.new(0.09, 0.09, 0.06), Vector3.new(0.5, 2.7, -1.08), white)
	mk(model, "ShineR2", Vector3.new(0.09, 0.09, 0.06), Vector3.new(-0.66, 2.7, -1.08), white)
	local mouth = Color3.fromRGB(70, 36, 30)
	mk(model, "MouthMid", Vector3.new(0.4, 0.1, 0.1), Vector3.new(0, 2.3, -1.0), mouth)
	mk(model, "MouthCornerL", Vector3.new(0.14, 0.1, 0.1), Vector3.new(0.27, 2.38, -1.0), mouth)
	mk(model, "MouthCornerR", Vector3.new(0.14, 0.1, 0.1), Vector3.new(-0.27, 2.38, -1.0), mouth)
	mk(model, "CheekL", Vector3.new(0.4, 0.26, 0.1), Vector3.new(0.98, 2.42, -0.99), Color3.fromRGB(240, 150, 135))
	mk(model, "CheekR", Vector3.new(0.4, 0.26, 0.1), Vector3.new(-0.98, 2.42, -0.99), Color3.fromRGB(240, 150, 135))

	-- sprout with three leaves
	mk(model, "Stem", Vector3.new(0.45, 0.65, 0.45), Vector3.new(0, 4.05, 0), Color3.fromRGB(70, 140, 60))
	leaf(model, "Leaf1", Vector3.new(-0.1, 4.38, 0), Vector3.new(0.25, 1.1, 0.75), Color3.fromRGB(120, 200, 95), 0, math.rad(40))
	leaf(model, "Leaf2", Vector3.new(0.1, 4.38, 0), Vector3.new(0.25, 1.6, 0.95), Color3.fromRGB(96, 176, 80), 0, math.rad(-35))
	leaf(model, "Leaf3", Vector3.new(0, 4.38, 0.05), Vector3.new(0.22, 0.9, 0.65), Color3.fromRGB(140, 214, 105), math.rad(100), math.rad(30))

	-- soft ground shadow
	local sh = mk(model, "Shadow", Vector3.new(0.06, 3.0, 3.0), Vector3.new(0, 0.03, 0), Color3.fromRGB(15, 15, 22), CFrame.Angles(0, 0, math.rad(90)))
	sh.Shape = Enum.PartType.Cylinder
	sh.Transparency = 0.55
	sh.CastShadow = false
	return model
end

-- Breeze: a chunky cloud puff that floats. Hover spirit: no legs, tail wisps wobble, small puff arms.
M.Builders.Breeze = function(cf)
	local model = newRoot(cf)
	model:SetAttribute("Hover", true)
	local white, soft, sky, deepSky = Color3.fromRGB(250, 252, 255), Color3.fromRGB(150, 200, 246), Color3.fromRGB(92, 148, 218), Color3.fromRGB(255, 255, 255)
	local main = Color3.fromRGB(122, 180, 240)
	local black, shine = Color3.fromRGB(28, 32, 48), Color3.fromRGB(255, 255, 255)

	-- body: stacked puffs, lighter on top, bluer underneath
	mk(model, "BodyBase", Vector3.new(1.9, 0.8, 1.7), Vector3.new(0, 2.0, 0), sky)
	mk(model, "BodyMain", Vector3.new(2.7, 1.5, 2.3), Vector3.new(0, 3.0, 0), main)
	mk(model, "BodyMid", Vector3.new(2.3, 0.5, 2.0), Vector3.new(0, 2.5, 0), soft)
	mk(model, "PuffTopA", Vector3.new(1.5, 1.0, 1.4), Vector3.new(-0.65, 4.0, 0.05), white)
	mk(model, "PuffTopB", Vector3.new(1.3, 0.9, 1.2), Vector3.new(0.7, 3.95, -0.05), soft)
	mk(model, "PuffTopC", Vector3.new(0.9, 0.7, 0.9), Vector3.new(0.0, 4.5, 0.0), white)
	mk(model, "Belly", Vector3.new(1.5, 0.55, 0.08), Vector3.new(0, 2.5, -1.17), white)
	-- wind swirl marks on the sides
	for _, x in ipairs({ 1.38, -1.38 }) do
		local k = x > 0 and "A" or "B"
		mk(model, "SwirlTop" .. k, Vector3.new(0.07, 0.16, 0.9), Vector3.new(x, 3.2, 0.0), deepSky)
		mk(model, "SwirlBot" .. k, Vector3.new(0.07, 0.16, 0.6), Vector3.new(x, 2.8, 0.25), deepSky)
	end

	-- face
	mk(model, "EyeL", Vector3.new(0.5, 0.62, 0.14), Vector3.new(0.6, 3.2, -1.17), black)
	mk(model, "EyeR", Vector3.new(0.5, 0.62, 0.14), Vector3.new(-0.6, 3.2, -1.17), black)
	mk(model, "ShineL", Vector3.new(0.17, 0.17, 0.06), Vector3.new(0.72, 3.38, -1.25), shine)
	mk(model, "ShineR", Vector3.new(0.17, 0.17, 0.06), Vector3.new(-0.48, 3.38, -1.25), shine)
	mk(model, "ShineL2", Vector3.new(0.09, 0.09, 0.06), Vector3.new(0.52, 3.05, -1.25), shine)
	mk(model, "ShineR2", Vector3.new(0.09, 0.09, 0.06), Vector3.new(-0.68, 3.05, -1.25), shine)
	local mouth = Color3.fromRGB(70, 60, 90)
	mk(model, "MouthMid", Vector3.new(0.38, 0.1, 0.1), Vector3.new(0, 2.65, -1.17), mouth)
	mk(model, "MouthCornerL", Vector3.new(0.14, 0.1, 0.1), Vector3.new(0.26, 2.73, -1.17), mouth)
	mk(model, "MouthCornerR", Vector3.new(0.14, 0.1, 0.1), Vector3.new(-0.26, 2.73, -1.17), mouth)
	mk(model, "CheekL", Vector3.new(0.4, 0.26, 0.1), Vector3.new(1.0, 2.8, -1.16), Color3.fromRGB(246, 176, 190))
	mk(model, "CheekR", Vector3.new(0.4, 0.26, 0.1), Vector3.new(-1.0, 2.8, -1.16), Color3.fromRGB(246, 176, 190))

	-- small puff arms
	for _, s in ipairs({ { "L", 1.6 }, { "R", -1.6 } }) do
		mk(model, "Arm" .. s[1], Vector3.new(0.75, 0.9, 0.8), Vector3.new(s[2], 2.95, 0), soft)
		local h = mk(model, "Hand" .. s[1], Vector3.new(0.82, 0.5, 0.86), Vector3.new(s[2], 2.45, 0), white)
		h:SetAttribute("Follow", "Arm" .. s[1])
	end

	-- curling tail of wisps (wobble)
	mk(model, "TailRoot", Vector3.new(1.0, 0.8, 0.9), Vector3.new(0, 2.15, 1.2), soft)
	leaf(model, "WispA", Vector3.new(0, 1.9, 1.6), Vector3.new(0.7, 0.7, 0.8), sky, 0, math.rad(80))
	leaf(model, "WispB", Vector3.new(0.5, 2.0, 2.1), Vector3.new(0.5, 0.55, 0.6), sky, 0, math.rad(60))
	leaf(model, "WispC", Vector3.new(0.9, 2.3, 2.5), Vector3.new(0.35, 0.4, 0.45), white, 0, math.rad(40))

	-- soft ground shadow (stays on the ground while it floats)
	local sh = mk(model, "Shadow", Vector3.new(0.06, 2.8, 2.8), Vector3.new(0, 0.03, 0), Color3.fromRGB(15, 15, 22), CFrame.Angles(0, 0, math.rad(90)))
	sh.Shape = Enum.PartType.Cylinder
	sh.Transparency = 0.62
	sh.CastShadow = false
	return model
end

function M.Has(name) return M.Builders[name] ~= nil end

function M.Build(name, cf)
	local model = M.Builders[name](cf or CFrame.new())
	model.Name = name
	return model
end

-- stand-in for spirits that have no model yet: a glowing orb that hovers
function M.BuildOrb(item, cf)
	local model, root = newRoot(cf or CFrame.new())
	local size = math.clamp((Data.RaritySize[item.rarity] or 2) * 0.8, 1.2, 3.5)
	local orb = Instance.new("Part")
	orb.Name = "Orb"; orb.Shape = Enum.PartType.Ball; orb.Size = Vector3.new(size, size, size)
	orb.Anchored = true; orb.CanCollide = false; orb.CanQuery = false; orb.CanTouch = false
	orb.Material = Enum.Material.Neon
	orb.Color = Data.RarityColor[item.rarity] or Color3.new(1, 1, 1)
	orb.CFrame = root.CFrame * CFrame.new(0, size / 2 + 1.6, 0)
	orb.Parent = model
	local light = Instance.new("PointLight")
	light.Color = orb.Color; light.Range = 9; light.Brightness = 1.2; light.Shadows = false
	light.Parent = orb
	model:SetAttribute("Hover", true)
	model.Name = item.name
	return model
end

return M
