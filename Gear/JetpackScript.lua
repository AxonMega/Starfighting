--scripted by AxonMega

local jetpack = script.Parent
local user = jetpack.Parent.Parent
local stats = jetpack:WaitForChild("Stats")
local setupJetpack= require(game.ServerScriptService:WaitForChild("GearModules"):WaitForChild("SetupJetpack"))
local rotOffset = CFrame.Angles(math.pi/2, 0, math.pi)
local glowLerp = 0

while #stats:GetChildren() < 2 do wait() end
local speed = stats.Speed.Value
while #jetpack:GetChildren() < stats.ChildCount.Value do wait() end
local jetSound, flyPower, rotatePower, jetGlows = setupJetpack(jetpack, user.TeamColor, speed)
local handle = jetpack.Handle
local joinPoint = handle:WaitForChild("JoinPoint").CFrame
while not user.Character or not user.Character.Parent do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")

local function activate()
	flyPower.MaxForce = Vector3.new(20000, 20000, 20000)
	rotatePower.MaxTorque = Vector3.new(20000, 20000, 20000)
	for _, jetGlow in ipairs(jetGlows) do
		jetGlow.Flames.Enabled = true
	end
	jetSound:Play()
	glowLerp = 1
	for i = 1, 3 do
		if glowLerp ~= 1 then break end
		for _, jetGlow in ipairs(jetGlows) do
			jetGlow.Transparency = 1 - i*0.25
			jetSound.PlaybackSpeed = speed/160 + i/6
		end
		wait(0.05)
	end
	if glowLerp == 1 then
		glowLerp = 0
	end
end

local function deactivate()
	flyPower.MaxForce = Vector3.new()
	rotatePower.MaxTorque = Vector3.new()
	for _, jetGlow in ipairs(jetGlows) do
		jetGlow.Flames.Enabled = false
	end
	for i = 1, 3 do
		for _, jetGlow in ipairs(jetGlows) do
			jetGlow.Transparency = 0.25 + i*0.25
			jetSound.PlaybackSpeed = speed/80 - i/6
		end
		wait(0.05)
	end
	jetSound:Stop()
end

local function onBack()
	if user.Character["Right Arm"]:FindFirstChild("RightGrip") then
		user.Character["Right Arm"].RightGrip.Part1 = nil
	end
	local weld = Instance.new("Weld")
	weld.Name = "BackWeld"
	weld.Part0 = handle
	weld.Part1 = user.Character.Torso
	weld.C0 = joinPoint
	weld.Parent = handle
end

local function offBack()
	if handle:FindFirstChild("BackWeld") then
		handle.BackWeld:Destroy()
	end
end

local function receive(mouseP)
	local handleP = handle.Position
	flyPower.Velocity = (mouseP - handleP).unit*speed
	rotatePower.CFrame = CFrame.new(handleP, mouseP)*rotOffset
end

local function receiveWR(task, mouseP)
	if task == "activate" then
		activate()
	elseif task == "deactivate" then
		deactivate()
	elseif task == "onBack" then
		onBack()
	elseif task == "offBack" then
		offBack()
	end
end

while not shared.createCom do wait() end
local com = shared.createCom(script, script:WaitForChild("JetpackInput"), {receive = receive, receiveWR = receiveWR})
com:setVars({handle = handle, flyPower = flyPower, rotatePower = rotatePower, rotOffset = rotOffset, speed = speed})
com.ready = true
