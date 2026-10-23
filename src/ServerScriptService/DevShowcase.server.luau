-- DevShowcase: TEMPORARY. Puts a Wood spirit in front of spawn so it can be seen right after pressing Play.
-- Turn off by setting Workspace attribute DevShowcase to false, or delete this script.
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
if not Workspace:GetAttribute("DevShowcase") then return end
local Models = require(RS:WaitForChild("SpiritModels"))
local spawn = Workspace:WaitForChild("SpawnLocation")
local p = spawn.Position + Vector3.new(7, 0, -11)
local hit = Workspace:Raycast(p + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0))
local y = hit and hit.Position.Y or (spawn.Position.Y - 3)
local m = Models.Build("Wood", CFrame.new(p.X, y + 0.05, p.Z) * CFrame.Angles(0, math.rad(160), 0))
m.Name = "WoodShowcase"
m:SetAttribute("Ready", true)
m.Parent = Workspace
CollectionService:AddTag(m, "SpiritVisual")

local p2 = spawn.Position + Vector3.new(-1, 0, -13)
local hit2 = Workspace:Raycast(p2 + Vector3.new(0, 20, 0), Vector3.new(0, -60, 0))
local y2 = hit2 and hit2.Position.Y or (spawn.Position.Y - 3)
local b = Models.Build("Breeze", CFrame.new(p2.X, y2 + 0.05, p2.Z) * CFrame.Angles(0, math.rad(175), 0))
b.Name = "BreezeShowcase"
b:SetAttribute("Ready", true)
b.Parent = Workspace
CollectionService:AddTag(b, "SpiritVisual")
