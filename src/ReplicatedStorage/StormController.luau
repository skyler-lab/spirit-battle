-- StormController: one number (StormLevel 0-10) drives sky, fog, light, rain and hail.
-- Runs on each player's own client so the hub can stay sunny while zones go dark.
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Controller = {}
Controller.__index = Controller

local C = Color3.fromRGB

-- WEATHER BY ZONE AND ROUND TIME.
-- Every zone starts the round at one storm level and climbs to another by 5:00.
-- Zone 1 starts as a light drizzle. Every zone ends the round near death level (damage uses the same number, see HealthServer).
-- Index 0 is the hub: always clear.
local ROUND_SECONDS = 300
local ZONE_START = { [0] = 0, 2.2, 4.5, 6.0, 7.5, 9.0 }
local ZONE_END   = { [0] = 0, 9.5, 9.7, 9.9, 10.0, 10.0 }
-- Climb is slow early and fast late, so the last minute is where it turns dangerous.
local RAMP_POWER = 1.5

---------------------------------------------------------------------------
-- SKY, FOG AND LIGHT. Keyframes by level; values blend smoothly between them.
---------------------------------------------------------------------------
local KEYS = {
	{ level = 0, clock = 14, bright = 3.0, amb = C(110,110,115), outAmb = C(140,150,165),
	  dens = 0.28, off = 0.10, col = C(199,222,255), decay = C(106,112,125), glare = 0.2, haze = 0.4,
	  ccB = 0, ccC = 0, ccS = 0.05, tint = C(255,255,255),
	  cloudCover = 0.25, cloudDens = 0.4, cloudCol = C(255,255,255), glow = 0 },
	{ level = 3, clock = 15.7, bright = 1.9, amb = C(115,125,140), outAmb = C(135,150,170),
	  dens = 0.38, off = 0.05, col = C(150,170,195), decay = C(90,105,125), glare = 0, haze = 3.0,
	  ccB = -0.02, ccC = 0.04, ccS = -0.12, tint = C(222,232,245),
	  cloudCover = 0.95, cloudDens = 0.85, cloudCol = C(135,145,160), glow = 0.2 },
	{ level = 6, clock = 16.0, bright = 1.4, amb = C(100,112,130), outAmb = C(115,130,155),
	  dens = 0.50, off = 0, col = C(130,150,172), decay = C(85,100,122), haze = 4.0, glare = 0,
	  ccB = -0.03, ccC = 0.08, ccS = -0.10, tint = C(215,228,245),
	  cloudCover = 0.9, cloudDens = 0.9, cloudCol = C(100,108,122), glow = 0.5 },
	{ level = 8, clock = 16.8, bright = 0.9, amb = C(85,98,118), outAmb = C(95,112,138),
	  dens = 0.58, off = 0, col = C(110,130,155), decay = C(70,85,108), haze = 6.0, glare = 0,
	  ccB = -0.05, ccC = 0.12, ccS = -0.15, tint = C(200,215,235),
	  cloudCover = 1, cloudDens = 1, cloudCol = C(70,78,92), glow = 0.8 },
	{ level = 10, clock = 17.3, bright = 0.6, amb = C(70,82,100), outAmb = C(80,95,120),
	  dens = 0.66, off = 0, col = C(95,115,140), decay = C(58,72,95), haze = 8.0, glare = 0,
	  ccB = -0.08, ccC = 0.15, ccS = -0.20, tint = C(190,205,228),
	  cloudCover = 1, cloudDens = 1, cloudCol = C(50,56,68), glow = 1.0 },
}

---------------------------------------------------------------------------
-- RAIN LOOKS. Each zone gets its own kind of rain, not just more of the same.
--   density   0-1   how many streaks are on screen
--   lenFar / lenNear   streak length as a fraction of screen height
--                      (far = thin soft layer behind, near = bold layer in front)
--   wFar / wNear       streak width in pixels
--   speed      fall speed multiplier
--   slant      lean in degrees. gust = how far gusts swing it, gustSpeed = how fast
--   nearFrac   share of the bold front layer. aFar / aNear = opacity of each layer
--   hail       0-1 amount of hail stones. hailSize = stone size in pixels
--   mist       0-1 haze laid over the whole screen
---------------------------------------------------------------------------
local RAIN_KEYS = {
	-- Hub: dry
	{ level = 0,   density = 0,    lenFar = 0.04, lenNear = 0.04, wFar = 1, wNear = 0.8, speed = 0.7, slant = 0,  gust = 0,  gustSpeed = 0.5, nearFrac = 0.1, aFar = 0.3, aNear = 0.45, hail = 0,    hailSize = 5, mist = 0 },
	-- Zone 1: DRIZZLE. sparse, fine, slow, nearly straight
	{ level = 2.5, density = 0.22, lenFar = 0.04, lenNear = 0.05, wFar = 1, wNear = 1.0, speed = 0.7, slant = 2,  gust = 1,  gustSpeed = 0.4, nearFrac = 0.1, aFar = 0.3, aNear = 0.65, hail = 0,    hailSize = 5, mist = 0.10 },
	-- Zone 2: STEADY RAIN
	{ level = 4.5, density = 0.30, lenFar = 0.06, lenNear = 0.07, wFar = 1, wNear = 1.2, speed = 1.0, slant = 6,  gust = 3,  gustSpeed = 0.5, nearFrac = 0.3, aFar = 0.4, aNear = 0.55, hail = 0,    hailSize = 5, mist = 0.10 },
	-- Zone 3: DRIVING RAIN. long fast streaks, leaning, gusty
	{ level = 6.5, density = 0.55, lenFar = 0.10, lenNear = 0.12, wFar = 1, wNear = 1.8, speed = 1.4, slant = 14, gust = 7,  gustSpeed = 0.9, nearFrac = 0.4, aFar = 0.5, aNear = 0.70, hail = 0,    hailSize = 6, mist = 0.14 },
	-- Zone 4: DOWNPOUR. dense, long, first hail
	{ level = 8.5, density = 0.80, lenFar = 0.15, lenNear = 0.20, wFar = 1, wNear = 2.4, speed = 1.8, slant = 22, gust = 10, gustSpeed = 1.1, nearFrac = 0.55, aFar = 0.55, aNear = 0.80, hail = 0.35, hailSize = 7, mist = 0.22 },
	-- Zone 5: HAIL STORM. maximum density, near sideways, big stones
	{ level = 10,  density = 1.0,  lenFar = 0.20, lenNear = 0.30, wFar = 1, wNear = 3.2, speed = 2.3, slant = 32, gust = 14, gustSpeed = 1.6, nearFrac = 0.7, aFar = 0.6, aNear = 0.90, hail = 1.0,  hailSize = 9, mist = 0.30 },
}

local function mix(a, b, t)
	if typeof(a) == "Color3" then return a:Lerp(b, t) end
	return a + (b - a) * t
end

local function blend(keys, level)
	level = math.clamp(level, keys[1].level, keys[#keys].level)
	local lo, hi = keys[1], keys[2]
	for i = 1, #keys - 1 do
		lo, hi = keys[i], keys[i + 1]
		if level <= hi.level then break end
	end
	local t = (level - lo.level) / (hi.level - lo.level)
	local out = {}
	for k, v in pairs(lo) do
		if k ~= "level" then out[k] = mix(v, hi[k], t) end
	end
	return out
end

-- zone: 0 = hub, 1-5 = zones (a fraction blends two zones, for walking across a border).
-- roundTime: seconds into the 5:00 round.
function Controller.LevelFor(zone, roundTime)
	zone = math.clamp(zone, 0, 5)
	local f = math.clamp(roundTime / ROUND_SECONDS, 0, 1) ^ RAMP_POWER
	local lo = math.floor(zone)
	local hi = math.min(lo + 1, 5)
	local function at(z) return ZONE_START[z] + (ZONE_END[z] - ZONE_START[z]) * f end
	return mix(at(lo), at(hi), zone - lo)
end

local function getOrCreate(parent, class, name)
	local o = parent:FindFirstChild(name)
	if not o then
		o = Instance.new(class)
		o.Name = name
		o.Parent = parent
	end
	return o
end

-- Pool sizes. RainQuality (0.2-1) scales how many of these are used, for weak phones.
local FAR, NEAR, HAIL = 200, 110, 60

function Controller.new()
	local self = setmetatable({}, Controller)
	self.level = 0
	self.t = 0
	self.acc = 0
	self.atmo = getOrCreate(Lighting, "Atmosphere", "StormAtmosphere")
	self.cc = getOrCreate(Lighting, "ColorCorrectionEffect", "StormColor")
	self.clouds = getOrCreate(Workspace.Terrain, "Clouds", "StormClouds")
	self:_buildOverlay()
	return self
end

-- REAL RAIN. Everything below lives in the 3D world around the camera (client only).
-- A rain emitter hangs above the camera, tilted by the wind. A ground emitter makes splashes
-- and low mist where the ground is. Hail is a fast white emitter. No screen overlay.
local RAIN_TEX = "rbxasset://textures/particles/smoke_main.dds"

local function newEmitter(parent, name)
	local e = Instance.new("ParticleEmitter")
	e.Name = name
	e.Texture = RAIN_TEX
	e.Rate = 0
	e.Enabled = true
	e.Parent = parent
	return e
end

local function newPart(parent, name, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size
	p.Parent = parent
	return p
end

function Controller:_buildOverlay()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local old = cam:FindFirstChild("StormRig")
	if old then old:Destroy() end
	local rig = Instance.new("Folder")
	rig.Name = "StormRig"
	rig.Parent = cam
	self.rig = rig
	self.t = 0
	self.groundY = 0
	self.groundT = 0

	self.skyPart = newPart(rig, "RainSky", Vector3.new(90, 1, 90))
	self.groundPart = newPart(rig, "RainGround", Vector3.new(90, 0.2, 90))

	-- Falling rain: thin streaks stretched along their fall direction.
	local rain = newEmitter(self.skyPart, "Rain")
	rain.Orientation = Enum.ParticleOrientation.VelocityParallel
	rain.EmissionDirection = Enum.NormalId.Bottom
	rain.Lifetime = NumberRange.new(0.55, 0.7)
	rain.LightEmission = 0.15
	rain.LightInfluence = 0.7
	rain.Color = ColorSequence.new(C(205, 218, 235))
	rain.SpreadAngle = Vector2.new(2, 2)
	self.rain = rain

	-- Hail stones: small, white, fast.
	local hail = newEmitter(self.skyPart, "Hail")
	hail.Orientation = Enum.ParticleOrientation.VelocityParallel
	hail.EmissionDirection = Enum.NormalId.Bottom
	hail.Lifetime = NumberRange.new(0.5, 0.6)
	hail.LightEmission = 0.4
	hail.LightInfluence = 0.5
	hail.Color = ColorSequence.new(C(245, 250, 255))
	hail.Transparency = NumberSequence.new(0.05)
	hail.SpreadAngle = Vector2.new(3, 3)
	self.hail = hail

	-- Splashes: tiny quick puffs popping up off the ground.
	local splash = newEmitter(self.groundPart, "Splash")
	splash.EmissionDirection = Enum.NormalId.Top
	splash.Lifetime = NumberRange.new(0.15, 0.25)
	splash.Speed = NumberRange.new(3, 7)
	splash.SpreadAngle = Vector2.new(35, 35)
	splash.Acceleration = Vector3.new(0, -40, 0)
	splash.LightEmission = 0.3
	splash.LightInfluence = 0.7
	splash.Color = ColorSequence.new(C(220, 230, 245))
	splash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.45),
	})
	splash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1),
	})
	self.splash = splash

	-- Ground mist: big slow soft haze at foot height.
	local mist = newEmitter(self.groundPart, "Mist")
	mist.EmissionDirection = Enum.NormalId.Top
	mist.Lifetime = NumberRange.new(3, 5)
	mist.Speed = NumberRange.new(0.3, 1)
	mist.SpreadAngle = Vector2.new(60, 60)
	mist.LightEmission = 0
	mist.LightInfluence = 1
	mist.Color = ColorSequence.new(C(170, 185, 205))
	mist.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 18),
	})
	mist.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.9), NumberSequenceKeypoint.new(1, 1),
	})
	mist.RotSpeed = NumberRange.new(-8, 8)
	self.mist = mist
	self:_buildBeams()
end

function Controller:_overlay(dt, r, rainScale, hailScale, quality)
	local cam = Workspace.CurrentCamera
	if not self.rig or not self.rig.Parent then
		self:_buildOverlay()
		if not self.rig then return end
	end
	self.t += dt
	local pos = cam.CFrame.Position

	-- Find the ground under the camera a few times a second.
	self.groundT += dt
	if self.groundT > 0.25 then
		self.groundT = 0
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ex = { self.rig }
		local ch = Players.LocalPlayer and Players.LocalPlayer.Character
		if ch then table.insert(ex, ch) end
		params.FilterDescendantsInstances = ex
		local hit = Workspace:Raycast(pos, Vector3.new(0, -300, 0), params)
		self.groundY = hit and hit.Position.Y or (pos.Y - 6)
	end

	-- Wind lean with gusts. Rain is tilted toward +X; the emitter sits upwind so it lands on the player.
	local slant = r.slant
		+ r.gust * math.sin(self.t * r.gustSpeed * 2)
		+ r.gust * 0.5 * math.sin(self.t * r.gustSpeed * 5.3)
	local theta = math.rad(slant)
	local height = 40
	local upwind = -math.tan(theta) * height
	self.skyPart.CFrame = CFrame.new(pos.X + upwind, pos.Y + height, pos.Z) * CFrame.Angles(0, 0, theta)
	self.groundPart.CFrame = CFrame.new(pos.X, self.groundY + 0.1, pos.Z)

	local dens = math.clamp(r.density * rainScale, 0, 1.5) * quality
	local fall = 70 + 55 * r.speed

	local rain = self.rain
	rain.Rate = 0
	rain.Speed = NumberRange.new(fall, fall * 1.15)
	-- streak: width, length grow with severity (lenNear is 0.05-0.36)
	local len = (Workspace:GetAttribute('RainLen') or 1) * (2.5 + r.lenNear * 22)
	local wid = 0.07 + r.wNear * 0.025
	rain.Size = NumberSequence.new(len)
	rain.Squash = NumberSequence.new(Workspace:GetAttribute('RainSquash') or 0.9)
	rain.Transparency = NumberSequence.new(Workspace:GetAttribute('RainTrans') or 0.5)

	local hailAmt = math.clamp(r.hail * hailScale, 0, 1.5) * quality
	local hl = self.hail
	hl.Rate = 0
	hl.Speed = NumberRange.new(fall * 1.3, fall * 1.5)
	hl.Size = NumberSequence.new(0.5 + r.hailSize * 0.08)
	hl.Squash = NumberSequence.new(0.5)

	self.splash.Rate = 900 * dens
	self.mist.Rate = 6 * math.clamp(r.mist * 4, 0, 1.5) * quality
	self:_stepBeams(dt, r, theta, dens, hailAmt, fall)
	self:_stepDebris(dt, slant, quality)
end

-- 3D drops: pooled Beams (thin camera-facing ribbons) falling through the world around the camera.
local RAIN_N, HAIL_N = 600, 50
local RADIUS, TOP = 38, 34

function Controller:_buildBeams()
	local rng = Random.new(7)
	self.brng = rng
	self.bdrops = {}
	local function make(kind)
		local p = newPart(self.rig, kind, Vector3.new(0.2, 0.2, 0.2))
		local a0 = Instance.new("Attachment"); a0.Parent = p
		local a1 = Instance.new("Attachment"); a1.Parent = p
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.FaceCamera = true
		b.LightEmission = kind == "hail" and 0.5 or 0.25
		b.LightInfluence = 0.6
		b.Segments = 1
		b.Color = ColorSequence.new(kind == "hail" and C(245, 250, 255) or C(200, 214, 232))
		b.Enabled = false
		b.Parent = p
		return {
			kind = kind, part = p, a1 = a1, beam = b, on = false,
			x = rng:NextNumber(-RADIUS, RADIUS), z = rng:NextNumber(-RADIUS, RADIUS),
			y = rng:NextNumber(0, TOP), v = rng:NextNumber(0.85, 1.15),
		}
	end
	for _ = 1, RAIN_N do table.insert(self.bdrops, make("rain")) end
	for _ = 1, HAIL_N do table.insert(self.bdrops, make("hail")) end
	self.bacc = 0
	self.cpos = Workspace.CurrentCamera.CFrame.Position
end

function Controller:_stepBeams(dt, r, slantRad, dens, hailAmt, fall)
	if not self.bdrops then return end
	local cam = Workspace.CurrentCamera.CFrame.Position
	local gy = self.groundY
	self.bacc += dt
	local refresh = self.bacc > 0.1
	if refresh then self.bacc = 0 end

	local rainOn = math.floor(RAIN_N * math.clamp(dens, 0, 1))
	local hailOn = math.floor(HAIL_N * math.clamp(hailAmt, 0, 1))
	local dirX, dirY = math.sin(slantRad), -math.cos(slantRad)
	local rl = (Workspace:GetAttribute("RainLen") or 1) * (1.6 + r.lenNear * 14)
	local rw = (Workspace:GetAttribute("RainWidth") or 1) * (0.03 + r.wNear * 0.02)
	local nr, nh = 0, 0
	local parts, cfs = {}, {}
	for _, d in ipairs(self.bdrops) do
		local isHail = d.kind == "hail"
		local on
		if isHail then nh += 1; on = nh <= hailOn else nr += 1; on = nr <= rainOn end
		if not on then
			if d.on then d.on = false; d.beam.Enabled = false end
		else
			local sp = fall * d.v * (isHail and 1.3 or 1) * 0.5
			d.x += dirX * sp * dt
			d.y += dirY * sp * dt
			-- wrap sideways around the camera
			local rx = d.x - (cam.X - (self.cpos.X - cam.X) * 0)
			d.worldX = d.worldX or (cam.X + d.x)
			d.worldZ = d.worldZ or (cam.Z + d.z)
			d.worldX += dirX * sp * dt
			if d.worldX - cam.X > RADIUS then d.worldX -= RADIUS * 2 elseif d.worldX - cam.X < -RADIUS then d.worldX += RADIUS * 2 end
			if d.worldZ - cam.Z > RADIUS then d.worldZ -= RADIUS * 2 elseif d.worldZ - cam.Z < -RADIUS then d.worldZ += RADIUS * 2 end
			if d.y + gy < gy then
				d.y = TOP + self.brng:NextNumber(0, 6)
				d.worldX = cam.X + self.brng:NextNumber(-RADIUS, RADIUS) - dirX * TOP
				d.worldZ = cam.Z + self.brng:NextNumber(-RADIUS, RADIUS)
			end
			table.insert(parts, d.part)
			table.insert(cfs, CFrame.new(d.worldX, gy + d.y, d.worldZ))
			if refresh or not d.on then
				local len = isHail and 0.9 or rl * (0.8 + d.v * 0.3)
				local w = isHail and (0.25 + r.hailSize * 0.03) or rw
				d.a1.Position = Vector3.new(-dirX * len, -dirY * len, 0)
				d.beam.Width0 = w
				d.beam.Width1 = w * 0.7
				local t = isHail and 0.05 or (Workspace:GetAttribute("RainTrans") or (1 - r.aNear * 0.9))
				d.beam.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, t), NumberSequenceKeypoint.new(1, math.min(1, t + 0.25)),
				})
			end
			if not d.on then d.on = true; d.beam.Enabled = true end
		end
	end
	if #parts > 0 then Workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end

-- WIND DEBRIS. Chunky low-poly leaf chips and dust flakes blown sideways near the ground.
local DEBRIS_N = 70
local DEBRIS_COLORS = { C(86,104,60), C(110,92,58), C(70,86,52), C(128,110,70), C(150,150,140) }

function Controller:_buildDebris()
	local rng = Random.new(21)
	self.drng = rng
	self.debris = {}
	for i = 1, DEBRIS_N do
		local p = newPart(self.rig, "Debris", Vector3.new(0.5, 0.08, 0.38) * rng:NextNumber(0.7, 1.5))
		p.Transparency = 0
		p.Material = Enum.Material.SmoothPlastic
		p.Color = DEBRIS_COLORS[rng:NextInteger(1, #DEBRIS_COLORS)]
		table.insert(self.debris, {
			part = p, on = false,
			x = rng:NextNumber(-30, 30), z = rng:NextNumber(-30, 30), y = rng:NextNumber(0.4, 7),
			spd = rng:NextNumber(0.7, 1.3), ph = rng:NextNumber(0, 6.28),
			rx = rng:NextNumber(-1, 1), ry = rng:NextNumber(-1, 1), rz = rng:NextNumber(-1, 1),
			ang = CFrame.Angles(rng:NextNumber(0, 6), rng:NextNumber(0, 6), rng:NextNumber(0, 6)),
		})
	end
end

function Controller:_stepDebris(dt, slant, quality)
	if not self.debris then self:_buildDebris() end
	local cam = Workspace.CurrentCamera.CFrame.Position
	local gy = self.groundY
	local amount = math.clamp((slant - 4) / 28, 0, 1) * quality
	local on = math.floor(DEBRIS_N * amount)
	local wind = 10 + math.max(slant, 0) * 1.4
	local parts, cfs = {}, {}
	for i, d in ipairs(self.debris) do
		if i > on then
			if d.on then d.on = false; d.part.Transparency = 1 end
		else
			if not d.on then d.on = true; d.part.Transparency = 0 end
			d.x += wind * d.spd * dt
			d.y += math.sin(self.t * 2.2 + d.ph) * 1.6 * dt
			d.y = math.clamp(d.y, 0.3, 9)
			if d.x > 32 then d.x -= 64; d.z = self.drng:NextNumber(-32, 32) end
			d.ang = d.ang * CFrame.Angles(d.rx * 6 * dt, d.ry * 6 * dt, d.rz * 6 * dt)
			table.insert(parts, d.part)
			table.insert(cfs, CFrame.new(cam.X + d.x, gy + d.y, cam.Z + d.z) * d.ang)
		end
	end
	if #parts > 0 then Workspace:BulkMoveTo(parts, cfs, Enum.BulkMoveMode.FireCFrameChanged) end
end

-- LIGHTNING. Chunky angular bolt out in the storm plus a sky flash. Starts around level 4.5, gets frequent by 10.
function Controller:_strike()
	local cam = Workspace.CurrentCamera
	local look = cam.CFrame.LookVector
	local base = math.atan2(look.X, look.Z) + self.lrng:NextNumber(-0.9, 0.9)
	local dist = self.lrng:NextNumber(110, 190)
	local gy = self.groundY
	local top = Vector3.new(cam.CFrame.Position.X + math.sin(base) * dist, gy + 200, cam.CFrame.Position.Z + math.cos(base) * dist)
	local pts = { top }
	local steps = 7
	for i = 1, steps do
		local t = i / steps
		local prev = pts[#pts]
		local jitter = (1 - t * 0.4) * 22
		pts[#pts + 1] = Vector3.new(
			top.X + self.lrng:NextNumber(-jitter, jitter),
			gy + 200 * (1 - t),
			top.Z + self.lrng:NextNumber(-jitter, jitter))
	end
	pts[#pts] = Vector3.new(pts[#pts].X, gy, pts[#pts].Z)
	local folder = Instance.new("Folder")
	folder.Name = "Bolt"
	folder.Parent = self.rig
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local len = (b - a).Magnitude
		local seg = newPart(folder, "Seg", Vector3.new(2.2, 2.2, len))
		seg.Transparency = 0
		seg.Material = Enum.Material.Neon
		seg.Color = C(225, 235, 255)
		seg.CFrame = CFrame.lookAt((a + b) / 2, b)
	end
	-- a short side branch
	local k = self.lrng:NextInteger(2, 4)
	local from = pts[k]
	local to = from + Vector3.new(self.lrng:NextNumber(-30, 30), -55, self.lrng:NextNumber(-30, 30))
	local br = newPart(folder, "Branch", Vector3.new(1.4, 1.4, (to - from).Magnitude))
	br.Transparency = 0
	br.Material = Enum.Material.Neon
	br.Color = C(200, 215, 255)
	br.CFrame = CFrame.lookAt((from + to) / 2, to)

	self.flashT = 0
	task.delay(0.12, function() for _, p in ipairs(folder:GetChildren()) do p.Transparency = 0.6 end end)
	task.delay(0.2, function() for _, p in ipairs(folder:GetChildren()) do p.Transparency = 0 end end)
	task.delay(0.34, function() folder:Destroy() end)
end

function Controller:_lightning(dt, quality)
	self.lrng = self.lrng or Random.new(33)
	self.nextStrike = self.nextStrike or 6
	local lv = self.level
	if Workspace:GetAttribute("StrikeNow") then Workspace:SetAttribute("StrikeNow", nil); self:_strike() end
	if lv >= 4.5 and (Workspace:GetAttribute("Lightning") ~= false) then
		self.nextStrike -= dt
		if self.nextStrike <= 0 then
			local k = math.clamp((lv - 4.5) / 5.5, 0, 1)
			self.nextStrike = (16 - 12.5 * k) * self.lrng:NextNumber(0.6, 1.4)
			self:_strike()
		end
	end
	if self.flashT then
		self.flashT += dt
		local t = self.flashT
		local f
		if t < 0.07 then f = 1
		elseif t < 0.13 then f = 0.15
		elseif t < 0.22 then f = 0.8
		else f = math.exp(-(t - 0.22) * 7) * 0.8 end
		if t > 1.2 then self.flashT = nil; f = 0 end
		local k = math.clamp(lv / 10, 0.4, 1)
		Lighting.Brightness += 2.8 * f * k
		Lighting.Ambient = Lighting.Ambient:Lerp(C(210, 220, 255), 0.55 * f)
		Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(C(210, 220, 255), 0.55 * f)
		self.cc.Brightness += 0.12 * f
	end
end

-- WET GROUND. Parts tagged "StormWet" get darker and a bit glossy as the local storm level rises.
function Controller:_wet(dt)
	self.wetAcc = (self.wetAcc or 0) + dt
	if self.wetAcc < 0.3 then return end
	self.wetAcc = 0
	local wet = math.clamp(self.level / 6, 0, 1)
	if self.lastWet and math.abs(wet - self.lastWet) < 0.015 then return end
	self.lastWet = wet
	self.wetOrig = self.wetOrig or {}
	for _, p in ipairs(CollectionService:GetTagged("StormWet")) do
		if p:IsA("BasePart") then
			local o = self.wetOrig[p]
			if not o then o = { color = p.Color, refl = p.Reflectance }; self.wetOrig[p] = o end
			local dark = o.color:Lerp(Color3.new(o.color.R * 0.55, o.color.G * 0.6, o.color.B * 0.7), wet * 0.85)
			p.Color = dark
			p.Reflectance = math.clamp(o.refl + 0.22 * wet, 0, 0.5)
		end
	end
end

function Controller:_glow(s)
	local plr = Players.LocalPlayer
	local char = plr and plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local light = root:FindFirstChild("StormGlow")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "StormGlow"
		light.Range = 22
		light.Color = C(255, 236, 205)
		light.Shadows = false
		light.Parent = root
	end
	light.Brightness = s.glow * 1.6
end

-- target: 0-10 storm level.
-- rainScale / hailScale: extra dials (1 = normal, 0 = off, 2 = double).
-- quality: 0.2-1, fewer rain pieces for weak devices.
function Controller:Step(dt, target, rainScale, hailScale, quality)
	self.level += (target - self.level) * math.min(1, dt * 1.2)
	local s = blend(KEYS, self.level)
	local r = blend(RAIN_KEYS, self.level)

	Lighting.ClockTime = s.clock
	Lighting.Brightness = s.bright
	Lighting.Ambient = s.amb
	Lighting.OutdoorAmbient = s.outAmb

	local a = self.atmo
	a.Density, a.Offset, a.Color, a.Decay, a.Glare, a.Haze = s.dens, s.off, s.col, s.decay, s.glare, s.haze

	local cc = self.cc
	cc.Brightness, cc.Contrast, cc.Saturation, cc.TintColor = s.ccB, s.ccC, s.ccS, s.tint

	local cl = self.clouds
	cl.Cover, cl.Density, cl.Color = s.cloudCover, s.cloudDens, s.cloudCol

	self:_overlay(dt, r, rainScale or 1, hailScale or 1, math.clamp(quality or 1, 0.2, 1))
	self:_glow(s)
	self:_lightning(dt, quality)
	self:_wet(dt)
end

function Controller:Destroy()
	if self.rig then self.rig:Destroy() end
end

return Controller
