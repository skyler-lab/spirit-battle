-- OwnedSpiritsClient: TEMPORARY plain list of the player's tamed spirits (player attribute OwnedSpirits, saved by BaseServer).
-- Placeholder so taming can be checked. Real team/inventory UI comes later.
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "OwnedSpiritsGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.Name = "Box"; box.AnchorPoint = Vector2.new(0, 0.5); box.Position = UDim2.new(0, 12, 0.5, 0)
box.Size = UDim2.fromOffset(190, 40); box.AutomaticSize = Enum.AutomaticSize.Y
box.BackgroundColor3 = Color3.fromRGB(30, 30, 36); box.BackgroundTransparency = 0.15; box.BorderSizePixel = 0
box.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = box
local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.Parent = box
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 2); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = box

local function label(txt, order, size, color)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.new(1, 0, 0, size + 4); t.Font = Enum.Font.GothamBold
	t.TextSize = size; t.TextColor3 = color; t.TextXAlignment = Enum.TextXAlignment.Left
	t.Text = txt; t.LayoutOrder = order; t.Parent = box
	return t
end

local function refresh()
	for _, ch in ipairs(box:GetChildren()) do if ch:IsA("TextLabel") then ch:Destroy() end end
	local raw = plr:GetAttribute("OwnedSpirits") or ""
	local list = (raw == "") and {} or string.split(raw, ";")
	label("My spirits (" .. #list .. ")", 0, 16, Color3.new(1, 1, 1))
	if #list == 0 then
		label("none yet: tame one in battle", 1, 13, Color3.fromRGB(170, 170, 170))
	else
		for i, name in ipairs(list) do label(i .. ". " .. name, i, 14, Color3.fromRGB(150, 230, 160)) end
	end
end

plr:GetAttributeChangedSignal("OwnedSpirits"):Connect(refresh)
refresh()
