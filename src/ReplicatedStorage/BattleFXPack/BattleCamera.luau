--!strict
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Cam = {}

local camera = Workspace.CurrentCamera
local playerPlat: BasePart? = nil
local enemyPlat: BasePart? = nil
local avatarRoot: BasePart? = nil
local conn: RBXScriptConnection? = nil
local baseCF = CFrame.new()
local punch = 0

local function stop()
	if conn then conn:Disconnect(); conn = nil end
end

local function hold(cf: CFrame, drift: boolean, orbit: Vector3?)
	stop()
	camera.CameraType = Enum.CameraType.Scriptable
	baseCF = cf
	local t0 = os.clock()
	conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		local c = baseCF
		if drift then
			c = c * CFrame.new(math.sin(t * 0.5) * 0.6, math.sin(t * 0.37) * 0.3, 0)
		end
		if orbit then
			local ang = math.rad(10) * math.clamp(t / 4, 0, 1)
			local rel = baseCF.Position - orbit
			local rot = CFrame.Angles(0, ang, 0)
			local pos = orbit + rot * rel
			c = CFrame.lookAt(pos, orbit)
		end
		if punch ~= 0 then
			c = c * CFrame.new(0, 0, punch)
		end
		camera.CFrame = c
	end)
end

function Cam.Setup(playerPlatform: BasePart, enemyPlatform: BasePart, playerAvatarRoot: BasePart?)
	playerPlat = playerPlatform
	enemyPlat = enemyPlatform
	avatarRoot = playerAvatarRoot
	camera = Workspace.CurrentCamera
end

function Cam.Main()
	assert(playerPlat and enemyPlat, "Cam.Setup first")
	local p = playerPlat.Position
	local e = enemyPlat.Position
	local dir = (e - p).Unit
	local right = dir:Cross(Vector3.yAxis).Unit
	local mid = (p + e) * 0.5
	local dist = (e - p).Magnitude
	local pos = p - dir * dist * 0.55 - right * dist * 0.55 + Vector3.new(0, dist * 0.6, 0)
	local look = mid + Vector3.new(0, 2, 0) - right * dist * 0.1
	hold(CFrame.lookAt(pos, look), true)
	camera.FieldOfView = 60
end

function Cam.Intro()
	assert(enemyPlat, "Cam.Setup first")
	local e = enemyPlat.Position
	local p = playerPlat and playerPlat.Position or e - Vector3.new(0, 0, 20)
	local dir = (e - p).Unit
	local pos = e - dir * 11 + Vector3.new(0, 4, 0)
	hold(CFrame.lookAt(pos, e + Vector3.new(0, 2.5, 0)), false, e + Vector3.new(0, 2.5, 0))
	camera.FieldOfView = 55
end

function Cam.PlayerCloseup()
	local r = avatarRoot
	if not r then return Cam.Main() end
	local f = r.CFrame.LookVector
	local pos = r.Position + f * 7 + Vector3.new(0, 1.5, 0) - r.CFrame.RightVector * 1.5
	hold(CFrame.lookAt(pos, r.Position + Vector3.new(0, 1, 0)), false)
	camera.FieldOfView = 55
end

function Cam.BehindPlayer()
	assert(playerPlat, "Cam.Setup first")
	local r = avatarRoot
	local target = playerPlat.Position + Vector3.new(0, 2, 0)
	local from = r and r.Position or (playerPlat.Position - Vector3.new(0, 0, 10))
	local back = (from - target).Unit
	local pos = from + back * 6 + Vector3.new(0, 5, 0)
	hold(CFrame.lookAt(pos, target), false)
	camera.FieldOfView = 60
end

function Cam.EnemyPlatform()
	assert(playerPlat and enemyPlat, "Cam.Setup first")
	local e = enemyPlat.Position
	local dir = (e - playerPlat.Position).Unit
	local pos = e - dir * 14 + Vector3.new(0, 7, 0)
	hold(CFrame.lookAt(pos, e + Vector3.new(0, 1, 0)), true)
	camera.FieldOfView = 55
end

function Cam.Zoom(target: BasePart, dist: number?)
	dist = dist or 8
	local dir = (camera.CFrame.Position - target.Position)
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	local pos = target.Position + dir * dist + Vector3.new(0, dist * 0.6, 0)
	hold(CFrame.lookAt(pos, target.Position), false)
end

function Cam.Punch(studs: number?, t: number?)
	studs = studs or 6
	t = t or 0.5
	task.spawn(function()
		local start = os.clock()
		while true do
			local f = math.clamp((os.clock() - start) / t, 0, 1)
			punch = (studs :: number) * math.sin(f * math.pi)
			if f >= 1 then break end
			RunService.RenderStepped:Wait()
		end
		punch = 0
	end)
end

function Cam.Release()
	stop()
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
end

return Cam
