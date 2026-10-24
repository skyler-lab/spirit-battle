-- OwnedSpiritsClient: TEMPORARY plain list of the player's tamed spirits (player attribute OwnedSpirits) and the
-- spirits on their base (PlacedSpirits). Place / Take back buttons ask the server (ReplicatedStorage.BaseAction);
-- the server decides. Placeholder UI so the flow can be tested. Real team/inventory UI comes later.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local plr = Players.LocalPlayer
local baseAction = RS:WaitForChild("BaseAction")

local gui = Instance.new("ScreenGui")
gui.Name = "OwnedSpiritsGui"; gui.ResetOnSpawn = false
gui.Parent = plr:WaitForChild("PlayerGui")

local box = Instance.new("Frame")
box.Name = "Box"; box.AnchorPoint = Vector2.new(0, 0.5); box.Position = UDim2.new(0, 12, 0.5, 0)
box.Size = UDim2.fromOffset(300, 40); box.AutomaticSize = Enum.AutomaticSize.Y
box.BackgroundColor3 = Color3.fromRGB(30, 30, 36); box.BackgroundTransparency = 0.15; box.BorderSizePixel = 0
box.Parent = gui
local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = box
local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 10); pad.PaddingRight = UDim.new(0, 10); pad.Parent = box
local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0, 3); lay.SortOrder = Enum.SortOrder.LayoutOrder; lay.Parent = box

local status = ""
local order = 0
local function label(txt, size, color)
	order += 1
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.new(1, 0, 0, size + 4); t.Font = Enum.Font.GothamBold
	t.TextSize = size; t.TextColor3 = color; t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextWrapped = true; t.Text = txt; t.LayoutOrder = order; t.Parent = box
	return t
end
local function row(txt, btnText, btnColor, onClick)
	order += 1
	local r = Instance.new("Frame"); r.BackgroundTransparency = 1; r.Size = UDim2.new(1, 0, 0, 22); r.LayoutOrder = order; r.Parent = box
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1; t.Size = UDim2.new(1, -86, 1, 0); t.Font = Enum.Font.GothamBold; t.TextSize = 14
	t.TextColor3 = Color3.fromRGB(220, 230, 220); t.TextXAlignment = Enum.TextXAlignment.Left; t.Text = txt; t.Parent = r
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(82, 20); b.Position = UDim2.new(1, -82, 0, 1); b.BackgroundColor3 = btnColor
	b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.new(1, 1, 1); b.Text = btnText; b.Parent = r
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = b
	b.MouseButton1Click:Connect(onClick)
end

local refresh
local busy = false
local function ask(action, arg)
	if busy then return end
	busy = true
	local ok, okFlag, msg = pcall(function() return baseAction:InvokeServer(action, arg) end)
	busy = false
	status = ok and (okFlag and ("Done: " .. tostring(msg)) or ("Can't: " .. tostring(msg))) or "Can't: no answer"
	refresh()
end

function refresh()
	for _, ch in ipairs(box:GetChildren()) do if ch:IsA("TextLabel") or ch:IsA("Frame") then ch:Destroy() end end
	order = 0
	local raw = plr:GetAttribute("OwnedSpirits") or ""
	local list = (raw == "") and {} or string.split(raw, ";")
	label("My spirits (" .. #list .. ")", 16, Color3.new(1, 1, 1))
	if #list == 0 then
		label("none yet: tame one in battle", 13, Color3.fromRGB(170, 170, 170))
	else
		for i, name in ipairs(list) do
			row(i .. ". " .. name, "Place", Color3.fromRGB(60, 150, 90), function() ask("place", i) end)
		end
	end
	local praw = plr:GetAttribute("PlacedSpirits") or ""
	local placed = (praw == "") and {} or string.split(praw, ";")
	label("On my base (" .. #placed .. ")", 16, Color3.new(1, 1, 1))
	for _, entry in ipairs(placed) do
		local slot, name, rarity = string.match(entry, "^(%d+)|(.-)|(.-)$")
		if slot then
			row("Slot " .. slot .. ": " .. name .. " (" .. rarity .. ")", "Take back", Color3.fromRGB(150, 90, 60), function() ask("take", tonumber(slot)) end)
		end
	end
	if status ~= "" then label(status, 12, Color3.fromRGB(255, 220, 130)) end
end

plr:GetAttributeChangedSignal("OwnedSpirits"):Connect(refresh)
plr:GetAttributeChangedSignal("PlacedSpirits"):Connect(refresh)
refresh()
