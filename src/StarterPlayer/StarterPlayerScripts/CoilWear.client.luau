-- CoilWear: the equipped coil is held in the right hand and winds around the forearm, slowly spinning, with sparkles and a glow.
-- Everyone sees everyone's coil (it follows the replicated player attribute "Coil").
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Coils = require(RS:WaitForChild("CoilData"))
local Models = require(RS:WaitForChild("CoilModels"))

local SCALE = 0.34
local worn = {}  -- [player] = { model, weld, emitter, light, coil }

local function coilById(id)
	for _, c in ipairs(Coils.List) do if c.id == id then return c end end
end

local function rainbowSeq()
	local k = {}
	for i = 0, 6 do k[#k + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 7, 0.8, 1)) end
	k[#k] = ColorSequenceKeypoint.new(1, Color3.fromHSV(0.86, 0.8, 1))
	return ColorSequence.new(k)
end

local function remove(plr)
	local w = worn[plr]
	if w then w.model:Destroy(); worn[plr] = nil end
end

local function wear(plr)
	remove(plr)
	local id = plr:GetAttribute("Coil")
	local coil = id and id ~= "" and coilById(id)
	local char = plr.Character
	if not coil or not char then return end
	local hand = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
	if not hand then return end
	local isR15 = (hand.Name == "RightHand")
	local scl = isR15 and (hand.Size.X * 0.5) or 0.3          -- sized to the hand, so it winds around a thin arm
	local oy = isR15 and (-hand.Size.Y * 0.5) or -0.85         -- where the grip sits on the hand

	local model = Models.Build(coil, CFrame.new())
	model:ScaleTo(scl)
	local root = model.PrimaryPart
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false; p.Massless = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			if p ~= root then
				local wc = Instance.new("WeldConstraint"); wc.Part0 = root; wc.Part1 = p; wc.Parent = p
			end
		end
	end
	-- glow and sparkles around the middle of the spring
	local fx = Instance.new("Part"); fx.Name = "Fx"; fx.Size = Vector3.new(1, 1, 1); fx.Transparency = 1
	fx.Massless = true; fx.CanCollide = false; fx.CanQuery = false; fx.CanTouch = false; fx.CastShadow = false
	fx.CFrame = root.CFrame * CFrame.new(0, 4.6 * scl, 0)
	fx.Parent = model
	local wf = Instance.new("WeldConstraint"); wf.Part0 = root; wf.Part1 = fx; wf.Parent = fx
	local light = Instance.new("PointLight"); light.Color = coil.color; light.Range = 9; light.Brightness = 1.2; light.Shadows = false; light.Parent = fx
	local em = Instance.new("ParticleEmitter")
	em.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	em.Color = coil.rainbow and rainbowSeq() or ColorSequence.new(coil.color:Lerp(Color3.new(1, 1, 1), 0.35))
	em.LightEmission = 0.9; em.Lifetime = NumberRange.new(0.6, 1.1); em.Speed = NumberRange.new(2, 5)
	em.SpreadAngle = Vector2.new(180, 180); em.Rate = 14
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.0), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.2), NumberSequenceKeypoint.new(1, 1) })
	em.Rotation = NumberRange.new(0, 360); em.RotSpeed = NumberRange.new(-90, 90)
	em.Acceleration = Vector3.new(0, 2, 0)
	em.Parent = fx
	-- a streak behind the coil while running
	local a0 = Instance.new("Attachment"); a0.Position = Vector3.new(0, 0.9, 0); a0.Parent = fx
	local a1 = Instance.new("Attachment"); a1.Position = Vector3.new(0, -0.9, 0); a1.Parent = fx
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1
	tr.Color = em.Color; tr.LightEmission = 0.9; tr.Lifetime = 0.5; tr.MinLength = 0.05
	tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	tr.Enabled = false
	tr.Parent = fx

	local weld = Instance.new("Weld")
	weld.Part0 = hand; weld.Part1 = root
	weld.C0 = CFrame.new(0, oy, 0)
	weld.Parent = root
	model:PivotTo(hand.CFrame * CFrame.new(0, oy, 0))  -- move into place BEFORE parenting so the welds keep the right offsets
	model.Parent = char
	worn[plr] = { trail = tr, model = model, weld = weld, em = em, light = light, coil = coil, oy = oy, spin = math.random() * 6 }
end

local function watch(plr)
	plr:GetAttributeChangedSignal("Coil"):Connect(function() wear(plr) end)
	plr.CharacterAdded:Connect(function() task.wait(0.5); wear(plr) end)
	if plr.Character then wear(plr) end
end
Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
Players.PlayerRemoving:Connect(remove)

RunService.RenderStepped:Connect(function(dt)
	for plr, w in pairs(worn) do
		if not w.model.Parent then
			worn[plr] = nil
		else
			local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local speed = root and Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude or 0
			w.spin += dt * (1.2 + speed * 0.12)
			w.weld.C0 = CFrame.new(0, w.oy, 0) * CFrame.Angles(0, w.spin, 0)
			w.em.Rate = 14 + speed * 1.6
			w.trail.Enabled = speed > 6
			w.light.Brightness = 1.0 + math.min(speed / 40, 1) * 1.2
		end
	end
end)
