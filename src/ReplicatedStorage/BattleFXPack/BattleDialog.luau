--!strict
-- BattleFXPack.BattleDialog : dialog strip, toasts, energy popups, team XP, level-up. Placeholder styling.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Dialog = {}

local FONT = Enum.Font.Arcade
local player = Players.LocalPlayer

local function gui(): ScreenGui
	local pg = player:WaitForChild("PlayerGui")
	local sg = pg:FindFirstChild("BattleFX_Dialog") :: ScreenGui?
	if not sg then
		sg = Instance.new("ScreenGui")
		sg.Name = "BattleFX_Dialog"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = false
		sg.DisplayOrder = 500
		sg.Parent = pg
	end
	return sg :: ScreenGui
end

local function tween(o: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?): Tween
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function corner(o: GuiObject, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = o
end

local function stroke(o: GuiObject, color: Color3, w: number)
	local s = Instance.new("UIStroke"); s.Color = color; s.Thickness = w; s.Parent = o
end

local function waitForClick()
	local done = false
	local c1 = UserInputService.InputBegan:Connect(function(input, gp)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.Return
			or input.KeyCode == Enum.KeyCode.ButtonA then
			done = true
		end
	end)
	while not done do task.wait() end
	c1:Disconnect()
end

local strip: Frame? = nil
local stripText: TextLabel? = nil
local stripCursor: TextLabel? = nil

local function makeStrip()
	local sg = gui()
	local f = Instance.new("Frame")
	f.Name = "Strip"
	f.AnchorPoint = Vector2.new(0.5, 1)
	f.Position = UDim2.new(0.5, 0, 1, -16)
	f.Size = UDim2.new(1, -32, 0, 84)
	f.BackgroundColor3 = Color3.new(1, 1, 1)
	f.BorderSizePixel = 0
	corner(f, 14)
	stroke(f, Color3.fromRGB(215, 215, 215), 3)
	local m = Instance.new("UISizeConstraint"); m.MaxSize = Vector2.new(980, 84); m.Parent = f
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.new(0, 20, 0, 8)
	t.Size = UDim2.new(1, -90, 1, -16)
	t.Font = FONT
	t.TextSize = 24
	t.TextWrapped = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Top
	t.TextColor3 = Color3.fromRGB(25, 25, 25)
	t.Text = ""
	t.Parent = f
	local c = Instance.new("TextLabel")
	c.Name = "Cursor"
	c.BackgroundTransparency = 1
	c.AnchorPoint = Vector2.new(1, 0.5)
	c.Position = UDim2.new(1, -18, 0.5, 0)
	c.Size = UDim2.fromOffset(34, 34)
	c.Font = Enum.Font.GothamBlack
	c.TextSize = 34
	c.Text = "▼"
	c.TextColor3 = Color3.fromRGB(240, 70, 90)
	c.Visible = false
	c.Parent = f
	f.Parent = sg
	strip = f
	stripText = t
	stripCursor = c
end

-- Auto-continue: if autoSeconds is set, the dialog advances by itself after that many seconds
-- (used by demos and bots). Otherwise waits for a click/tap/space.
Dialog.AutoSeconds = nil :: number?

function Dialog.Say(text: string, charsPerSecond: number?)
	Dialog.ClearToasts()
	if not strip then makeStrip() end
	local f = strip :: Frame
	local t = stripText :: TextLabel
	local c = stripCursor :: TextLabel
	f.Visible = true
	c.Visible = false
	t.Text = ""
	local cps = charsPerSecond or 25
	local skip = false
	local skipConn = UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			skip = true
		end
	end)
	for i = 1, #text do
		if skip then t.Text = text; break end
		t.Text = string.sub(text, 1, i)
		task.wait(1 / cps)
	end
	skipConn:Disconnect()
	task.wait(0.15)
	c.Visible = true
	local blinking = true
	task.spawn(function()
		while blinking do
			c.TextTransparency = 0; task.wait(0.5)
			if not blinking then break end
			c.TextTransparency = 0.6; task.wait(0.5)
		end
	end)
	if Dialog.AutoSeconds then
		task.wait(Dialog.AutoSeconds)
	else
		waitForClick()
	end
	blinking = false
	c.Visible = false
end

function Dialog.Hide()
	if strip then (strip :: Frame).Visible = false end
end

function Dialog.Ask(text: string, choices: {string}): string
	if not strip then makeStrip() end
	local f = strip :: Frame
	local t = stripText :: TextLabel
	f.Visible = true
	t.Text = ""
	for i = 1, #text do t.Text = string.sub(text, 1, i); task.wait(0.04) end
	local sg = gui()
	local holder = Instance.new("Frame")
	holder.AnchorPoint = Vector2.new(0.5, 1)
	holder.Position = UDim2.new(0.5, 0, 1, -112)
	holder.Size = UDim2.fromOffset(200, 40 * #choices + 8)
	holder.BackgroundTransparency = 1
	holder.Parent = sg
	local chosen: string? = nil
	for i, label in choices do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, 0, 0, 36)
		b.Position = UDim2.new(0, 0, 0, (i - 1) * 40)
		b.BackgroundColor3 = Color3.fromRGB(70, 160, 255)
		b.Font = FONT
		b.TextSize = 22
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Text = label
		corner(b, 10)
		stroke(b, Color3.fromRGB(30, 90, 170), 3)
		b.Parent = holder
		b.MouseButton1Click:Connect(function() chosen = label end)
	end
	if Dialog.AutoSeconds then
		task.wait(Dialog.AutoSeconds)
		chosen = choices[1]
	end
	while not chosen do task.wait() end
	holder:Destroy()
	f.Visible = false
	return chosen :: string
end

local toasts: {Frame} = {}

local function layoutToasts()
	for i, t in toasts do
		tween(t, 0.15, {Position = UDim2.new(0, 16, 1, -16 - (i - 1) * 40)})
	end
end

function Dialog.Toast(text: string)
	local sg = gui()
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0, 1)
	f.Position = UDim2.new(0, -400, 1, -16)
	f.AutomaticSize = Enum.AutomaticSize.X
	f.Size = UDim2.fromOffset(0, 34)
	f.BackgroundColor3 = Color3.fromRGB(70, 150, 255)
	f.BorderSizePixel = 0
	corner(f, 8)
	stroke(f, Color3.fromRGB(30, 80, 170), 3)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AutomaticSize = Enum.AutomaticSize.X
	l.Size = UDim2.fromOffset(0, 34)
	l.Font = FONT
	l.TextSize = 20
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextStrokeTransparency = 0.5
	l.Text = "  " .. string.upper(text) .. "  "
	l.Parent = f
	f.Parent = sg
	table.insert(toasts, 1, f)
	f.Position = UDim2.new(0, -400, 1, -16)
	layoutToasts()
end

function Dialog.ClearToasts()
	for _, t in toasts do
		tween(t, 0.2, {Position = UDim2.new(0, -400, t.Position.Y.Scale, t.Position.Y.Offset)})
		game:GetService("Debris"):AddItem(t, 0.25)
	end
	table.clear(toasts)
end

function Dialog.EnergyPop(anchor: GuiObject, text: string, color: Color3?)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.new(0, anchor.AbsolutePosition.X + anchor.AbsoluteSize.X * 0.5, 0, anchor.AbsolutePosition.Y - 10)
	l.Size = UDim2.fromOffset(80, 30)
	l.Font = FONT
	l.TextSize = 24
	l.TextColor3 = color or Color3.fromRGB(90, 255, 120)
	l.TextStrokeTransparency = 0.3
	l.Text = text
	l.ZIndex = 50
	l.Parent = gui()
	tween(l, 0.9, {Position = l.Position - UDim2.fromOffset(0, 40), TextTransparency = 1, TextStrokeTransparency = 1}, Enum.EasingStyle.Sine)
	game:GetService("Debris"):AddItem(l, 1)
end

function Dialog.EnergyCost(pill: GuiObject, amount: number)
	local orig = pill.BackgroundColor3
	pill.BackgroundColor3 = Color3.fromRGB(230, 40, 40)
	tween(pill, 0.4, {BackgroundColor3 = orig})
	Dialog.EnergyPop(pill, "-" .. tostring(amount), Color3.fromRGB(255, 70, 70))
end

export type TeamRow = {name: string, level: number, xp: number, gain: number}

function Dialog.TeamXP(rows: {TeamRow})
	local sg = gui()
	local holder = Instance.new("Frame")
	holder.Position = UDim2.new(0, -360, 0.5, -(#rows * 48) / 2)
	holder.Size = UDim2.fromOffset(320, #rows * 48)
	holder.BackgroundTransparency = 1
	holder.Parent = sg
	local bars = {}
	for i, r in rows do
		local row = Instance.new("Frame")
		row.Position = UDim2.new(0, 0, 0, (i - 1) * 48)
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		row.BackgroundTransparency = 0.35
		corner(row, 8)
		row.Parent = holder
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.new(0, 12, 0, 2)
		name.Size = UDim2.new(1, -90, 0, 18)
		name.Font = FONT; name.TextSize = 16
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = r.name
		name.Parent = row
		local lvl = name:Clone()
		lvl.Position = UDim2.new(1, -80, 0, 2)
		lvl.Size = UDim2.fromOffset(70, 18)
		lvl.TextXAlignment = Enum.TextXAlignment.Right
		lvl.Text = "LVL " .. tostring(r.level)
		lvl.Parent = row
		local back = Instance.new("Frame")
		back.Position = UDim2.new(0, 12, 0, 24)
		back.Size = UDim2.new(1, -24, 0, 12)
		back.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		corner(back, 6)
		back.Parent = row
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(math.clamp(r.xp, 0, 1), 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
		corner(fill, 6)
		fill.Parent = back
		table.insert(bars, {fill, r})
	end
	tween(holder, 0.3, {Position = UDim2.new(0, 16, 0.5, -(#rows * 48) / 2)}, Enum.EasingStyle.Back)
	task.wait(0.5)
	for _, b in bars do
		local fill, r = b[1], b[2]
		tween(fill, 1.0, {Size = UDim2.new(math.clamp(r.xp + r.gain, 0, 1), 0, 1, 0)}, Enum.EasingStyle.Sine)
	end
	task.wait(4)
	tween(holder, 0.3, {Position = UDim2.new(0, -360, 0.5, -(#rows * 48) / 2)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.35)
	holder:Destroy()
end

function Dialog.LevelUp(level: number)
	local sg = gui()
	local l = Instance.new("TextLabel")
	l.AnchorPoint = Vector2.new(0.5, 0.5)
	l.Position = UDim2.fromScale(0.5, 0.4)
	l.Size = UDim2.fromOffset(10, 10)
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextScaled = true
	l.TextColor3 = Color3.fromRGB(190, 250, 255)
	l.TextStrokeColor3 = Color3.fromRGB(20, 80, 120)
	l.TextStrokeTransparency = 0
	l.Text = "LVL " .. tostring(level)
	l.Parent = sg
	tween(l, 0.25, {Size = UDim2.fromOffset(420, 150)}, Enum.EasingStyle.Back)
	task.wait(0.25)
	tween(l, 0.1, {Size = UDim2.fromOffset(360, 128)})
	task.wait(2)
	tween(l, 0.3, {TextTransparency = 1, TextStrokeTransparency = 1})
	task.wait(0.3)
	l:Destroy()
end

return Dialog
