-- SpeedServer: one place that sets walk speed. Base speed is 24 studs/sec (Roblox default is 16).
-- Later, coils and upgrades only need to set the player attribute SpeedMult (1 = normal, 1.5 = 50% faster).
local Players = game:GetService("Players")
local BASE = 24

local function apply(plr)
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = BASE * (plr:GetAttribute("SpeedMult") or 1) end
end

local function watch(plr)
	if plr:GetAttribute("SpeedMult") == nil then plr:SetAttribute("SpeedMult", 1) end
	plr:GetAttributeChangedSignal("SpeedMult"):Connect(function() apply(plr) end)
	plr.CharacterAdded:Connect(function(char)
		char:WaitForChild("Humanoid")
		apply(plr)
	end)
	apply(plr)
end

Players.PlayerAdded:Connect(watch)
for _, p in ipairs(Players:GetPlayers()) do watch(p) end
