-- CoilModels: builds a speed coil as a real 3D object: one thick wire wound in a spiral (a spring)
-- with a handle at the bottom. Chunky faceted wire (straight segments), like the spirits.
local M = {}

function M.Build(coil, cf)
	cf = cf or CFrame.new()
	local model = Instance.new("Model"); model.Name = coil.id .. "Coil"
	local root = Instance.new("Part"); root.Name = "Root"; root.Size = Vector3.new(1, 1, 1); root.Transparency = 1
	root.Anchored = true; root.CanCollide = false; root.CanQuery = false; root.CanTouch = false; root.CastShadow = false
	root.CFrame = cf; root.Parent = model; model.PrimaryPart = root

	local LOOPS, SEG = 4, 10
	local R0, R1 = 1.7, 1.25     -- radius at bottom and top
	local PITCH = 1.3            -- rise per loop
	local TH = 0.66               -- wire thickness
	local Y0 = 2.4                -- coil starts above the handle
	local total = LOOPS * SEG
	local function pt(n)
		local a = n * 2 * math.pi / SEG
		local k = n / total
		local r = R0 + (R1 - R0) * k
		return Vector3.new(math.cos(a) * r, Y0 + n * PITCH / SEG, math.sin(a) * r)
	end
	local dark = Color3.new(coil.color.R * 0.55, coil.color.G * 0.55, coil.color.B * 0.55)
	for n = 0, total - 1 do
		local a, b = pt(n), pt(n + 1)
		local len = (b - a).Magnitude
		local p = Instance.new("Part"); p.Name = "Wire" .. n
		p.Size = Vector3.new(TH, TH, len + TH * 0.9)
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic
		if coil.rainbow then p.Color = Color3.fromHSV((n / SEG * 0.18) % 1, 0.85, 1) else p.Color = (n % 2 == 0) and coil.color or coil.color:Lerp(Color3.new(1, 1, 1), 0.18) end
		p.CFrame = cf * CFrame.lookAt((a + b) / 2, b)
		p.Parent = model
	end
	-- end caps so the wire ends look rounded
	for _, n in ipairs({ 0, total }) do
		local c = Instance.new("Part"); c.Name = "Cap" .. n; c.Shape = Enum.PartType.Ball; c.Size = Vector3.new(TH * 1.15, TH * 1.15, TH * 1.15)
		c.Anchored = true; c.CanCollide = false; c.CanQuery = false; c.CanTouch = false
		c.Color = coil.rainbow and Color3.fromHSV((n / SEG * 0.18) % 1, 0.85, 1) or coil.color
		c.CFrame = cf * CFrame.new(pt(n)); c.Parent = model
	end
	-- handle: a chunky grip with a collar, and a stem up into the spring
	local function box(name, size, pos, color, shape)
		local p = Instance.new("Part"); p.Name = name; p.Size = size
		p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.Material = Enum.Material.SmoothPlastic; p.Color = color
		if shape then p.Shape = shape end
		p.CFrame = cf * CFrame.new(pos); p.Parent = model
		return p
	end
	box("Stem", Vector3.new(0.6, 2.2, 0.6), Vector3.new(0, 1.4, 0), Color3.fromRGB(60, 64, 80))
	box("Grip", Vector3.new(1.1, 1.4, 1.1), Vector3.new(0, 0.7, 0), Color3.fromRGB(34, 36, 48))
	box("Collar", Vector3.new(1.45, 0.34, 1.45), Vector3.new(0, 1.45, 0), dark)
	box("GripEnd", Vector3.new(1.3, 0.3, 1.3), Vector3.new(0, 0.15, 0), dark)
	return model
end

return M
