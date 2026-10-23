--!strict
-- BattleFXPack.BattleMenu : in-battle UI (HP panels, energy pills, FIGHT/BAG/TEAM/RUN, move page, team page, bag page, cursor).
-- Placeholder styling; every live element is a TextLabel you can restyle.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Menu = {}

local FONT = Enum.Font.Arcade
local player = Players.LocalPlayer

local C = {
	fight = Color3.fromRGB(225, 55, 75),
	bag = Color3.fromRGB(235, 165, 50),
	team = Color3.fromRGB(70, 200, 110),
	run = Color3.fromRGB(60, 130, 240),
	back = Color3.fromRGB(120, 120, 125),
	panel = Color3.fromRGB(150, 150, 155),
	panelDark = Color3.fromRGB(70, 70, 75),
	energy = Color3.fromRGB(235, 200, 70),
	coin = Color3.fromRGB(240, 180, 40),
	hpGreen = Color3.fromRGB(90, 230, 70),
	hpYellow = Color3.fromRGB(240, 210, 50),
	hpRed = Color3.fromRGB(230, 60, 50),
	white = Color3.new(1, 1, 1),
	cursor = Color3.fromRGB(240, 70, 90),
}

local sg: ScreenGui? = nil
local root: Frame? = nil
local cursor: TextLabel? = nil
local cursorConn: RBXScriptConnection? = nil
local cursorTarget: GuiObject? = nil
local sides: {[string]: any} = {}

local function tween(o: Instance, t: number, props: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
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

local function darker(c: Color3, f: number): Color3
	return c:Lerp(Color3.new(0, 0, 0), f)
end

local function label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.TextSize = size
	l.TextColor3 = color or C.white
	l.TextStrokeColor3 = Color3.new(0, 0, 0)
	l.TextStrokeTransparency = 0.4
	l.Text = text
	l.Parent = parent
	return l
end

local function moveCursorTo(target: GuiObject?)
	cursorTarget = target
	if cursor then cursor.Visible = target ~= nil end
end

local function startCursor()
	if cursorConn then return end
	local t0 = os.clock()
	cursorConn = RunService.RenderStepped:Connect(function()
		local c = cursor
		local t = cursorTarget
		if not c or not t or not t.Parent then return end
		local bob = math.sin((os.clock() - t0) * math.pi * 4) * 4
		c.Position = UDim2.fromOffset(
			t.AbsolutePosition.X + t.AbsoluteSize.X * 0.5 - 14,
			t.AbsolutePosition.Y - 30 + bob)
	end)
end

local function build()
	if sg then return end
	local pg = player:WaitForChild("PlayerGui")
	local g = Instance.new("ScreenGui")
	g.Name = "BattleFX_Menu"
	g.ResetOnSpawn = false
	g.DisplayOrder = 400
	g.Parent = pg
	sg = g
	local r = Instance.new("Frame")
	r.Name = "Root"
	r.Size = UDim2.fromScale(1, 1)
	r.BackgroundTransparency = 1
	r.Parent = g
	root = r

	local function sidePanel(name: string, anchor: Vector2, pos: UDim2, pillPos: UDim2)
		local p = Instance.new("Frame")
		p.Name = name .. "Panel"
		p.AnchorPoint = anchor
		p.Position = pos
		p.Size = UDim2.fromOffset(290, 64)
		p.BackgroundColor3 = C.panel
		corner(p, 12)
		stroke(p, darker(C.panel, 0.5), 3)
		p.Parent = r
		local nm = label(p, "NAME", 17)
		nm.Position = UDim2.new(0, 12, 0, 6)
		nm.Size = UDim2.new(1, -90, 0, 20)
		nm.TextXAlignment = Enum.TextXAlignment.Left
		local lv = label(p, "LVL 1", 17)
		lv.Position = UDim2.new(1, -80, 0, 6)
		lv.Size = UDim2.fromOffset(70, 20)
		lv.TextXAlignment = Enum.TextXAlignment.Right
		local back = Instance.new("Frame")
		back.Position = UDim2.new(0, 12, 0, 32)
		back.Size = UDim2.new(1, -24, 0, 20)
		back.BackgroundColor3 = C.panelDark
		corner(back, 10)
		back.Parent = p
		local fill = Instance.new("Frame")
		fill.Size = UDim2.fromScale(1, 1)
		fill.BackgroundColor3 = C.hpGreen
		corner(fill, 10)
		fill.Parent = back
		local hp = label(back, "100 HP", 14)
		hp.Size = UDim2.fromScale(1, 1)
		hp.ZIndex = 3
		local pill = Instance.new("TextLabel")
		pill.Name = name .. "Energy"
		pill.AnchorPoint = anchor
		pill.Position = pillPos
		pill.Size = UDim2.fromOffset(110, 30)
		pill.BackgroundColor3 = C.energy
		pill.Font = FONT
		pill.TextSize = 18
		pill.TextColor3 = Color3.fromRGB(40, 30, 0)
		pill.Text = "E  0"
		corner(pill, 15)
		stroke(pill, darker(C.energy, 0.5), 3)
		pill.Parent = r
		sides[name] = {panel = p, name = nm, level = lv, fill = fill, hp = hp, pill = pill}
	end
	sidePanel("enemy", Vector2.new(0, 0), UDim2.new(0, 16, 0, 16), UDim2.new(0, 16, 0, 88))
	sidePanel("player", Vector2.new(1, 0), UDim2.new(1, -16, 0.5, -20), UDim2.new(1, -16, 0.5, -58))

	local coin = Instance.new("TextLabel")
	coin.Name = "Coin"
	coin.Position = UDim2.new(0, 16, 0, 126)
	coin.Size = UDim2.fromOffset(130, 30)
	coin.BackgroundColor3 = C.coin
	coin.Font = FONT
	coin.TextSize = 18
	coin.TextColor3 = Color3.fromRGB(40, 30, 0)
	coin.Text = "$ 0"
	coin.Visible = false
	corner(coin, 15)
	stroke(coin, darker(C.coin, 0.5), 3)
	coin.Parent = r
	sides.coin = coin

	local cur = Instance.new("TextLabel")
	cur.Name = "Cursor"
	cur.BackgroundTransparency = 1
	cur.Size = UDim2.fromOffset(28, 28)
	cur.Font = Enum.Font.GothamBlack
	cur.TextSize = 28
	cur.Text = "▼"
	cur.TextColor3 = C.cursor
	cur.TextStrokeColor3 = darker(C.cursor, 0.6)
	cur.TextStrokeTransparency = 0
	cur.ZIndex = 20
	cur.Visible = false
	cur.Parent = r
	cursor = cur
	startCursor()
end

export type SideState = {name: string?, level: number?, hp: number?, maxHp: number?, energy: number?}

function Menu.SetSide(side: string, s: SideState)
	build()
	local d = sides[side]
	if not d then return end
	if s.name then d.name.Text = string.upper(s.name) end
	if s.level then d.level.Text = "LVL " .. tostring(s.level) end
	if s.hp and s.maxHp then
		local f = math.clamp(s.hp / math.max(1, s.maxHp), 0, 1)
		tween(d.fill, 0.5, {Size = UDim2.fromScale(f, 1)})
		d.fill.BackgroundColor3 = f > 0.5 and C.hpGreen or (f > 0.25 and C.hpYellow or C.hpRed)
		d.hp.Text = tostring(math.max(0, math.floor(s.hp + 0.5))) .. " HP"
	end
	if s.energy then d.pill.Text = "E  " .. tostring(s.energy) end
end

function Menu.SetCoins(n: number)
	build()
	sides.coin.Visible = true
	sides.coin.Text = "$ " .. tostring(n)
end

function Menu.Pills(): (GuiObject, GuiObject, GuiObject)
	build()
	return sides.player.pill, sides.enemy.pill, sides.coin
end

function Menu.Show()
	build();
	(root :: Frame).Visible = true
end

function Menu.Hide()
	if root then (root :: Frame).Visible = false end
	moveCursorTo(nil)
end

function Menu.Destroy()
	if cursorConn then cursorConn:Disconnect(); cursorConn = nil end
	if sg then sg:Destroy(); sg = nil; root = nil; cursor = nil end
	table.clear(sides)
end

local function button(parent: Instance, text: string, color: Color3, pos: UDim2, size: UDim2, sub: string?): TextButton
	local b = Instance.new("TextButton")
	b.Name = text
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.AutoButtonColor = false
	b.Font = FONT
	b.TextSize = 20
	b.TextColor3 = C.white
	b.TextStrokeColor3 = darker(color, 0.6)
	b.TextStrokeTransparency = 0.2
	b.Text = string.upper(text)
	corner(b, 12)
	stroke(b, darker(color, 0.45), 3)
	b.Parent = parent
	if sub then
		local s = label(b, sub, 12)
		s.AnchorPoint = Vector2.new(0.5, 1)
		s.Position = UDim2.new(0.5, 0, 1, -3)
		s.Size = UDim2.new(1, 0, 0, 14)
		s.TextStrokeTransparency = 0.5
		b.TextYAlignment = Enum.TextYAlignment.Top
		local pad = Instance.new("UIPadding"); pad.PaddingTop = UDim.new(0, 6); pad.Parent = b
	end
	local base = size
	b.MouseEnter:Connect(function()
		tween(b, 0.1, {BackgroundColor3 = color:Lerp(C.white, 0.25), Size = base + UDim2.fromOffset(6, 3)})
		moveCursorTo(b)
	end)
	b.MouseLeave:Connect(function()
		tween(b, 0.1, {BackgroundColor3 = color, Size = base})
	end)
	return b
end

local function page(): Frame
	build()
	local f = Instance.new("Frame")
	f.Name = "Page"
	f.AnchorPoint = Vector2.new(1, 1)
	f.Position = UDim2.new(1, 300, 1, -16)
	f.Size = UDim2.fromOffset(300, 190)
	f.BackgroundTransparency = 1
	f.Parent = root
	tween(f, 0.3, {Position = UDim2.new(1, -16, 1, -16)}, Enum.EasingStyle.Back)
	return f
end

local function closePage(f: Frame)
	moveCursorTo(nil)
	tween(f, 0.15, {Position = UDim2.new(1, 300, 1, -16)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.15)
	f:Destroy()
end

local function waitChoice(buttons: {{any}}): any
	local chosen = nil
	local conns = {}
	for _, pair in buttons do
		local b, v = pair[1], pair[2]
		table.insert(conns, b.MouseButton1Click:Connect(function() chosen = v end))
	end
	if buttons[1] then moveCursorTo(buttons[1][1]) end
	while chosen == nil do task.wait() end
	for _, c in conns do c:Disconnect() end
	return chosen
end

function Menu.MainMenu(): string
	local f = page()
	local fight = button(f, "Fight", C.fight, UDim2.new(0.5, 0, 0, 30), UDim2.fromOffset(190, 46))
	local bag = button(f, "Bag", C.bag, UDim2.new(0.5, -70, 0, 95), UDim2.fromOffset(130, 46))
	local team = button(f, "Team", C.team, UDim2.new(0.5, 70, 0, 95), UDim2.fromOffset(130, 46))
	local run = button(f, "Run", C.run, UDim2.new(0.5, 0, 0, 160), UDim2.fromOffset(190, 46))
	local choice = waitChoice({{fight, "Fight"}, {bag, "Bag"}, {team, "Team"}, {run, "Run"}})
	closePage(f)
	return choice
end

export type MoveInfo = {name: string, cost: number, kind: string?}

function Menu.MovePage(moves: {MoveInfo}, energy: number): string?
	local f = page()
	f.Size = UDim2.fromOffset(300, 200)
	local map: {{any}} = {}
	local colors = {Color3.fromRGB(225, 190, 60), Color3.fromRGB(60, 170, 235), Color3.fromRGB(90, 90, 110), Color3.fromRGB(200, 70, 110)}
	for i, m in moves do
		if i > 4 then break end
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		local sub = m.cost > 0 and ("E " .. tostring(m.cost)) or "FREE"
		local b = button(f, m.name, colors[i], UDim2.new(0.5, (col == 0 and -72 or 72), 0, 32 + row * 58), UDim2.fromOffset(136, 50), sub)
		if m.cost > energy then
			b.BackgroundColor3 = darker(colors[i], 0.5)
			b.TextTransparency = 0.4
			b.Active = false
		else
			table.insert(map, {b, m.name})
		end
	end
	local back = button(f, "Back", C.back, UDim2.new(0.5, 0, 0, 160), UDim2.fromOffset(280, 40))
	table.insert(map, {back, "__back"})
	local c = waitChoice(map)
	closePage(f)
	if c == "__back" then return nil end
	return c
end

export type TeamSlot = {name: string, level: number, hp: number, maxHp: number, active: boolean?}

function Menu.TeamPage(team: {TeamSlot}): number?
	build()
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.BackgroundColor3 = Color3.fromRGB(150, 200, 240)
	corner(f, 16)
	stroke(f, Color3.fromRGB(60, 110, 160), 4)
	f.Parent = root
	f.Size = UDim2.fromOffset(10, 10)
	tween(f, 0.25, {Size = UDim2.fromOffset(520, 330)}, Enum.EasingStyle.Back)
	local selected: number? = nil
	local slotButtons = {}
	for i = 1, 6 do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		local s = team[i]
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.new(0.5, (col == 0 and -125 or 125), 0, 48 + row * 70)
		b.Size = UDim2.fromOffset(236, 60)
		b.BackgroundColor3 = s and Color3.fromRGB(90, 120, 150) or Color3.fromRGB(80, 95, 110)
		b.AutoButtonColor = false
		b.Text = ""
		corner(b, 10)
		b.Parent = f
		if s then
			local nm = label(b, string.upper(s.name) .. (s.active and "  (OUT)" or ""), 14)
			nm.Position = UDim2.new(0, 10, 0, 6)
			nm.Size = UDim2.new(1, -20, 0, 18)
			nm.TextXAlignment = Enum.TextXAlignment.Left
			local lv = label(b, "LVL " .. tostring(s.level), 14)
			lv.Position = UDim2.new(1, -70, 0, 6)
			lv.Size = UDim2.fromOffset(60, 18)
			lv.TextXAlignment = Enum.TextXAlignment.Right
			local back = Instance.new("Frame")
			back.Position = UDim2.new(0, 10, 0, 32)
			back.Size = UDim2.new(1, -20, 0, 14)
			back.BackgroundColor3 = C.panelDark
			corner(back, 7)
			back.Parent = b
			local fill = Instance.new("Frame")
			local fr = math.clamp(s.hp / math.max(1, s.maxHp), 0, 1)
			fill.Size = UDim2.fromScale(fr, 1)
			fill.BackgroundColor3 = fr > 0.5 and C.hpGreen or (fr > 0.25 and C.hpYellow or C.hpRed)
			corner(fill, 7)
			fill.Parent = back
			b.MouseEnter:Connect(function() moveCursorTo(b) end)
			b.MouseButton1Click:Connect(function()
				selected = i
				for j, sb in slotButtons do
					sb.BackgroundColor3 = (j == i) and Color3.fromRGB(120, 200, 120) or Color3.fromRGB(90, 120, 150)
				end
			end)
			slotButtons[i] = b
		end
	end
	local sel = button(f, "Select", Color3.fromRGB(70, 160, 240), UDim2.new(0.5, -110, 1, -32), UDim2.fromOffset(200, 40))
	local back = button(f, "Back", C.back, UDim2.new(0.5, 110, 1, -32), UDim2.fromOffset(200, 40))
	local result: any = nil
	local c1 = sel.MouseButton1Click:Connect(function()
		if selected then result = selected end
	end)
	local c2 = back.MouseButton1Click:Connect(function() result = "__back" end)
	moveCursorTo(slotButtons[1] or back)
	while result == nil do task.wait() end
	c1:Disconnect(); c2:Disconnect()
	moveCursorTo(nil)
	tween(f, 0.15, {Size = UDim2.fromOffset(10, 10)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.15)
	f:Destroy()
	if result == "__back" then return nil end
	return result
end

export type BagItem = {name: string, count: number, catchChance: number?}

function Menu.BagPage(items: {BagItem}): string?
	build()
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(10, 10)
	f.BackgroundColor3 = Color3.fromRGB(235, 110, 125)
	corner(f, 16)
	stroke(f, Color3.fromRGB(150, 40, 60), 4)
	f.Parent = root
	tween(f, 0.25, {Size = UDim2.fromOffset(460, 300)}, Enum.EasingStyle.Back)
	local title = label(f, "BOXES", 24)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.Size = UDim2.new(1, 0, 0, 30)
	local tip = label(f, "", 14)
	tip.Position = UDim2.new(0, 20, 1, -92)
	tip.Size = UDim2.new(1, -40, 0, 40)
	tip.TextWrapped = true
	local map: {{any}} = {}
	for i, it in items do
		local b = button(f, it.name .. "  x" .. tostring(it.count), Color3.fromRGB(200, 140, 60), UDim2.new(0.5, 0, 0, 70 + (i - 1) * 52), UDim2.fromOffset(300, 44))
		b.MouseEnter:Connect(function()
			tip.Text = it.catchChance and ("CATCH CHANCE: " .. tostring(math.floor(it.catchChance * 100 + 0.5)) .. "%   (damage the target to raise it)") or ""
		end)
		if it.count > 0 then table.insert(map, {b, it.name}) else b.Active = false; b.TextTransparency = 0.4 end
	end
	local back = button(f, "Back", C.back, UDim2.new(0.5, 0, 1, -30), UDim2.fromOffset(300, 40))
	table.insert(map, {back, "__back"})
	local c = waitChoice(map)
	moveCursorTo(nil)
	tween(f, 0.15, {Size = UDim2.fromOffset(10, 10)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.15)
	f:Destroy()
	if c == "__back" then return nil end
	return c
end

return Menu
