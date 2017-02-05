--scripted by AxonMega

--DEFINE VARIABLES

--essentials
local ship = script:WaitForChild("MyShip").Value
local pilot = game.Players.LocalPlayer
local mouse = pilot:GetMouse()
local cam = workspace.CurrentCamera
--wait for setup to finish
while not ship.SetupFinished.Value do wait() end
--objects
local engineOn = ship.EngineOn
local health = ship.Health
local cockpitOn = ship.CockpitOn
local landingGearOn = ship.LandingGearOn
local controlComputer = ship.ControlComputer
local leftHinge = controlComputer.LeftJoystick.Hinge
local rightHinge = controlComputer.RightJoystick.Hinge
local screen = controlComputer.ControlPanel.Screen
local toggleCockpit = ship.ToggleCockpit
local toggleLandingGear = ship.ToggleLandingGear
local engine = ship.Engine
local jetPower = engine.JetPower
local rotatePower = engine.RotatePower
local hum = engine.Hum
local jetSound = engine.JetSound
local retroSound = engine.RetroSound
local projFolder = workspace["-Projectiles-"]
local guiFolder = game.ReplicatedStorage.Guis
local thrusters, retroThrusters, lightTurrets, heavyTurrets, glowParts = ship.GetObjects:InvokeServer()
--services
local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
--ship stats
local turretStats = {}
local rov = engine:WaitForChild("RotOffset").Value
local rotOffset = CFrame.Angles(rov.X, rov.Y, rov.Z)
local maxHealth = ship.Stats.MaxHealth.Value
local maxSpeed = ship.Stats.MaxSpeed.Value
local maxTurnSpeed = ship.Stats.MaxTurnSpeed.Value/10
local vws = {
	rear = engine:WaitForChild("RearView").CFrame,
	center = engine:WaitForChild("CenterView").CFrame,
	front = engine:WaitForChild("FrontView").CFrame
}
--changing variables
local canChange = true
local camOffset = vws.rear
local controlGuiOn = true
local statsGuiOn = true
local retroOn = false
local acceleration = 0
local speed = 0
local turnSpeed = 0
local targRoll = 0
local roll = 0
--constant variables
local normColor = pilot.TeamColor.Color
local lightColor = Color3.new(normColor.r + 0.4, normColor.g + 0.4, normColor.b + 0.4)
local maxForce = Vector3.new(2000000, 2000000, 2000000)
local noForce = Vector3.new(0, 0, 0)
local camRotOffset = rotOffset*CFrame.Angles(0, math.pi, 0)
local lasRot = CFrame.Angles(0, math.pi/2, 0)
local cx = mouse.ViewSizeX/2
local cy = mouse.ViewSizeY/2
local heavyEnabled = (ship.Controls.Q.Value ~= "None")
local lightEnabled = (ship.Controls.E.Value ~= "None")
local funcNames = {
	EngineOn = "Engine: ",
	CockpitOn = "Cockpit: ",
	LandingGearOn = "Landing Gear: ",
	RetroThrustersOn = "Retro Thrusters: "
}
local keyOrder = {Q = 1, E = 2, R = 3, T = 4, F = 5, G = 6}
--modules
local modFolder = game.ReplicatedStorage.ModuleScripts
local createLaser = require(modFolder.CreateLaser)
local enableLaser = require(modFolder.EnableLaser)
--done

--CAMERA

local function updateCam() --updates the camera's CFrame
	cam.CFrame = engine.CFrame:toWorldSpace(camOffset)*camRotOffset
end

local function toggleCam(camOn) --toggles the ship's camera
	if camOn then
		cam.CameraType = Enum.CameraType.Scriptable
		mouse.TargetFilter = workspace
		rs:BindToRenderStep("ChangeCamera", 199, updateCam)
	else
		rs:UnbindFromRenderStep("ChangeCamera")
		cam.CameraType = Enum.CameraType.Custom
		mouse.TargetFilter = nil
	end
end

if engineOn.Value then
	toggleCam(true)
end

local function toggleCharTransparency(newTrans) --toggles the local transparency of some of the player's bodyparts
	for _, child in ipairs(pilot.Character:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Head" or child.Name == "Torso" then
			child.LocalTransparencyModifier = newTrans
		elseif child:IsA("Accessory") then
			child.Handle.LocalTransparencyModifier = newTrans
		end
	end
end

local function switchView() --switches the camera offset
	if not engineOn.Value or not canChange then return end
	if camOffset == vws.rear then
		camOffset = vws.center
		toggleCharTransparency(1)
	elseif camOffset == vws.center then
		camOffset = vws.front
		toggleCharTransparency(0)
	elseif camOffset == vws.front then
		camOffset = vws.rear
	end
end

--GUIS

local function sortKeys(a, b) --used to sort the keys that might be added to the control gui
	return keyOrder[a.Name] < keyOrder[b.Name]
end

local controlGui = guiFolder.ShipControls:Clone()
controlGui.Parent = pilot.PlayerGui
local controls = controlGui:WaitForChild("Controls")
local statsGui = guiFolder.ShipStats:Clone()
statsGui.Parent = pilot.PlayerGui
local statsFrame = statsGui:WaitForChild("Stats")
local healthBar = statsFrame:WaitForChild("HealthBar")
local healthLabel = statsFrame:WaitForChild("HealthLabel")
local speedBar = statsFrame:WaitForChild("SpeedBar")
local speedLabel = statsFrame:WaitForChild("SpeedLabel")
local controlVs = ship.Controls:GetChildren()
table.sort(controlVs, sortKeys)
for _, controlV in ipairs(controlVs) do
	if controlV.Value ~= "None" then
		controls.Size = controls.Size + UDim2.new(0, 0, 0, 16)
		local newControl = Instance.new("TextLabel")
		newControl.Name = controlV.Name
		newControl.BackgroundTransparency = 1
		newControl.BorderColor3 = Color3.new(0, 0, 0)
		newControl.BorderSizePixel = 0
		newControl.Position = UDim2.new(0, 0, 0, controls.Size.Y.Offset - 16)
		newControl.Size = UDim2.new(1, 0, 0, 16)
		newControl.Font = Enum.Font.SciFi
		newControl.Text = controlV.Name .. " = " .. controlV.Value
		newControl.TextColor3 = Color3.new(0, 0, 0)
		newControl.TextScaled = true
		newControl.TextWrapped = true
		newControl.Parent = controls
		newControl.TextXAlignment = Enum.TextXAlignment.Left
	end
end

local function removeGuis() --removes the control and stats guis
	controlGui:Destroy()
	statsGui:Destroy()
end

local function toggleControlGui() --toggles the visibility of the control gui
	if controlGuiOn then
		controlGuiOn = false
		controlGui.Controls:TweenPosition(UDim2.new(0, -160, 0.5, -90), Enum.EasingDirection.Out, Enum.EasingStyle.Sine,
			0.5, true)
	else
		controlGuiOn = true
		controlGui.Controls:TweenPosition(UDim2.new(0, 20, 0.5, -90), Enum.EasingDirection.Out, Enum.EasingStyle.Sine,
			0.5, true)
	end
end

local function toggleStatsGui() --toggles the visibility of the stats gui
	if statsGuiOn then
		statsGuiOn = false
		statsGui.Stats:TweenPosition(UDim2.new(1, 20, 0.625, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5, true)
	else
		statsGuiOn = true
		statsGui.Stats:TweenPosition(UDim2.new(1, -180 ,0.625, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5, true)
	end
end

local function updateHealthBar(newHealth) --scales the health bar to match the ship's health
	if health.Value <= 0 then return end
	healthLabel.Text = "Health: " .. tostring(newHealth) .. "/" .. tostring(maxHealth)
	healthBar.Size = UDim2.new(0, (newHealth/maxHealth)*154, 0, 14)
end

local function updateSpeedBar(newSpeed) --scales the speed bar to match the ship's speed
	speedLabel.Text = "Speed: " .. tostring(math.ceil(newSpeed)) .. "/" .. tostring(maxSpeed)
	if newSpeed > 0  then
		speedBar.Size = UDim2.new(0, (newSpeed/maxSpeed)*154, 0, 14)
		speedBar.BackgroundTransparency = 0
	else
		speedBar.BackgroundTransparency = 1
	end
end

local function updateFunction(funcName, newState) --changes the displayed state of the function
	local funcStat = statsFrame[funcName]
	if newState then
		funcStat.Text = funcNames[funcName] .. "On"
		funcStat.TextColor3 = Color3.new(0, 1, 0)
	else
		funcStat.Text = funcNames[funcName] .. "Off"
		funcStat.TextColor3 = Color3.new(1, 0.5, 0)
	end
end

updateHealthBar(health.Value)
updateSpeedBar(0)
updateFunction("EngineOn", engineOn.Value)
updateFunction("CockpitOn", cockpitOn.Value)
updateFunction("LandingGearOn", landingGearOn.Value)

--FLIGHT

local function range(n) --makes sure given number in a range of -1 to 1
	return math.max(math.min(n, 1), -1)
end

local function move() --steers the ship
	if speed == 0 or not canChange then return end
	local c = engine.CFrame
	local vel = (c*rotOffset).lookVector*speed*-1
	if retroOn then 
		vel = vel + c.upVector*4
	end
	local percentY = range((cx - mouse.X)/cx)
	local percentZ = range((mouse.Y - cy)/cy)
	local avy = percentY*c.upVector*turnSpeed
	local avz = percentZ*c.lookVector*turnSpeed
	rotatePower.AngularVelocity = (roll*turnSpeed*c.rightVector) + avy + avz
	jetPower.Velocity = vel
	leftHinge.TargetAngle = percentY*45 - 45
	rightHinge.TargetAngle = percentZ*45 - 45
end

local function retroForce() --simulates the force of the retro thrusters
	while speed == 0 and retroOn and canChange and engineOn.Value do
		jetPower.Velocity = engine.CFrame.upVector*4
		wait(0.1)
	end
end

local function bad(thruster) --checks to see if the the given thruster is missing its glow effect
	return not thruster:FindFirstChild("JetGlow")
end

local function flameOn() --turns on the thrusters' flames
	for i = 1, 3 do
		for _, thruster in ipairs(thrusters) do
			if speed == 0 or bad(thruster) or not canChange then return end
			thruster.JetGlow.Transparency = 1 - i*0.25
		end
		wait(0.05)
	end
end

local function startMove() --starts the ship's motion
	rs:BindToRenderStep("MoveShip", 101, move)
	jetPower.MaxForce = maxForce
	rotatePower.MaxTorque = maxForce
	for _, thruster in ipairs(thrusters) do
		thruster.JetGlow.Flames.Rate = 0
		thruster.JetGlow.Flames.Enabled = true
	end
	jetSound:Play()
	coroutine.resume(coroutine.create(flameOn))
end


local function flameOff() --turns off the thrusters' flames
	for i = 1, 3 do
		for _, thruster in ipairs(thrusters) do
			if acceleration == 1 or bad(thruster) then return end
			thruster.JetGlow.Transparency = 0.25 + i*0.25
		end
		wait(0.05)
	end
end

local function stopMove() --stops the ship's motion
	rotatePower.MaxTorque = noForce
	local currentRetroOn = false
	if retroOn then
		currentRetroOn = true
	else
		jetPower.MaxForce = noForce
		jetPower.Velocity = noForce
	end
	rs:UnbindFromRenderStep("MoveShip")
	acceleration = 0
	speed = 0
	turnSpeed = 0
	targRoll = 0
	roll = 0
	jetSound:Stop()
	jetSound.PlaybackSpeed = 0.5
	jetSound.Volume = 0.5
	for _, thruster in ipairs(thrusters) do
		thruster.JetGlow.Flames.Rate = 0
		thruster.JetGlow.Flames.Enabled = false
	end
	coroutine.resume(coroutine.create(flameOff))
	if currentRetroOn then
		retroForce()
	end
end

local function activateRetro() --turns on the retro thrusters
	if not canChange or not engineOn.Value or retroOn then return end
	retroOn = true
	updateFunction("RetroThrustersOn", true)
	retroSound:Play()
	if speed == 0 then
		jetPower.Velocity = engine.CFrame.upVector*4
		jetPower.MaxForce = maxForce
	end
	for _, thruster in ipairs(retroThrusters) do
		thruster.JetGlow.Flames.Enabled = true
	end
	for i = 1, 3 do
		for _, thruster in ipairs(retroThrusters) do
			if not retroOn or bad(thruster) or not canChange then return end
			thruster.JetGlow.Transparency = 1 - i*0.25
		end
		wait(0.05)
	end
	retroForce()
end

local function deactivateRetro() --turns off the retro thrusters
	if not retroOn then return end
	retroOn = false
	updateFunction("RetroThrustersOn", false)
	retroSound:Stop()
	if speed == 0 then
		jetPower.Velocity = noForce
		jetPower.MaxForce = noForce
	end
	for _, thruster in ipairs(retroThrusters) do
		thruster.JetGlow.Flames.Enabled = false
	end
	for i = 1, 3 do
		for _, thruster in ipairs(retroThrusters) do
			if retroOn or bad(thruster) or not canChange then return end
			thruster.JetGlow.Transparency = 0.25 + i*0.25
		end
		wait(0.05)
	end
end

local function updateThrusters() --changes the magnitude of the thrusters relative to the ship's speed
	local change = acceleration*5
	for _, thruster in ipairs(thrusters) do
		thruster.JetGlow.Flames.Rate = thruster.JetGlow.Flames.Rate + change
	end
	jetSound.PlaybackSpeed = 0.5 + (speed/maxSpeed)*1.5
	jetSound.Volume = 0.5 + (speed/maxSpeed)*0.5
end

local function accelerate(newAcc) --changes the acceleration of the ship
	if acceleration == newAcc or (speed == 0 and newAcc == -1) or (speed == maxSpeed and newAcc == 1)
		or not engineOn.Value or not canChange then return end
	acceleration = newAcc
	if acceleration == 0 then return end
	local percent1 = (maxSpeed/40)*acceleration
	local percent2 = (maxTurnSpeed/40)*acceleration
	local init = (speed == 0)
	speed = speed + percent1
	turnSpeed = turnSpeed + percent2
	updateSpeedBar(speed)
	if init then startMove() end
	updateThrusters()
	while acceleration == newAcc and speed > 0 and speed < maxSpeed and engineOn.Value and canChange do
		wait(0.05)
		speed = speed + percent1
		turnSpeed = turnSpeed + percent2
		updateSpeedBar(speed)
		updateThrusters()
	end
	acceleration = 0
	if speed == 0  then
		stopMove()
	end
end

local function tilt(newTargRoll) --tilts the ship along the X axis
	if targRoll == newTargRoll or not engineOn.Value or not canChange then return end
	targRoll = newTargRoll
	local percent = (newTargRoll - roll)/10
	for i = 1, 10 do
		if targRoll ~= newTargRoll or not engineOn.Value or not canChange then return end
		roll = roll + percent
		wait(0.05)
	end
end

--TURRETS

local lTurret1 = lightTurrets[1]
local hTurret1 = heavyTurrets[1]
if lTurret1 then
	local stats = lTurret1.Stats
	turretStats.ld = stats.Damage.Value
	turretStats.lp = stats.ProjectileSpeed.Value
	turretStats.lf = stats.FireRate.Value
	turretStats.lcf = true
	turretStats.lbl, turretStats.lbe = createLaser(pilot.TeamColor, turretStats.ld, turretStats.lp)
end
if hTurret1 then
	local stats = hTurret1.Stats
	turretStats.hd = stats.Damage.Value
	turretStats.hp = stats.ProjectileSpeed.Value
	turretStats.hf = stats.FireRate.Value
	turretStats.hcf = true
	turretStats.hbl, turretStats.hbe = createLaser(pilot.TeamColor, turretStats.ld, turretStats.lp)
end

local function fireTurret(turret, laser, effect, damage, speed) --causes the given turret to fire
	local charge = turret.Charge
	charge.Fire:Play()
	laser.Parent = projFolder
	local pos = charge.NozzlePoint.WorldPosition
	local dir = charge.NozzlePoint.WorldAxis
	laser.CFrame = CFrame.new(pos, pos + dir*10)*lasRot + dir*(laser.Size.X/2)
	laser:WaitForChild("FlyPower").Velocity = dir*speed
	enableLaser(pilot, laser, effect, ship, damage)
end

local function fireLight() --fires the ship's light turrets
	if not engineOn.Value or not turretStats.lcf then return end
	turretStats.lcf = false
	for _, turret in ipairs(lightTurrets) do
		fireTurret(turret, turretStats.lbl:Clone(), turretStats.lbe:Clone(), turretStats.ld, turretStats.lp)
	end
	wait(1/turretStats.lf)
	turretStats.lcf = true
end

local function fireHeavy() --fires the ship's heavy turrets
	if not engineOn.Value or not turretStats.hcf then return end
	turretStats.hcf = false
	for _, turret in ipairs(lightTurrets) do
		fireTurret(turret, turretStats.hbl:Clone(), turretStats.hbe:Clone(), turretStats.hd, turretStats.hp)
	end
	wait(1/turretStats.hf)
	turretStats.hcf = true
end

--MAIN

local function stopFunctions() --stops the ship's functions when the pilot ejects or the ship is destroyed or turned off
	toggleCam(false)
	toggleCharTransparency(0)
	stopMove()
	deactivateRetro()
	for _, button in ipairs(screen:GetChildren()) do
		button.BackgroundColor3 = normColor
	end
	leftHinge.TargetAngle = 0
	rightHinge.TargetAngle = 0
end

local function togglePower() --toggles whether the ship is on or off
	if engineOn.Value then
		engineOn.Value = false
		updateFunction("EngineOn", false)
		stopFunctions()
		for _, glowPart in ipairs(glowParts) do
			glowPart.Material = Enum.Material.SmoothPlastic
		end
		for i = 1, 40 do
			if engineOn.Value or not canChange then return end
			hum.Volume = 1 - i/40
			hum.PitchChange.Octave = 2 - i/20
			wait(0.05)
		end
		hum:Stop()
	else
		engineOn.Value = true
		updateFunction("EngineOn", true)
		for _, glowPart in ipairs(glowParts) do
			glowPart.Material = Enum.Material.Neon
		end
		camOffset = vws.rear
		toggleCam(true)
		hum:Play()
		for i = 1, 40 do
			if not engineOn.Value or not canChange then return end
			hum.Volume = i/40
			hum.PitchChange.Octave = i/20
			wait(0.05)
		end
	end
end

local function onPowerCutRequest(reason) --called when the pilot ejects or the ship is destroyed
	canChange = false
	if reason == "ejected" then
		if engineOn.Value then
			stopFunctions()
		end
	elseif reason == "destroyed" then
		if engineOn.Value then
			togglePower()
		end
	end
	removeGuis()
	wait(0.2)
	script:Destroy()
end

local function onCockpitToggled(new) --called when the cockpit is toggled
	updateFunction("CockpitOn", new)
end

local function onLandingGearToggled(new)
	updateFunction("LandingGearOn", new)
end

--HANDLING INPUT

local function onInputBegan(input, gpe) --called when user input begins
	if gpe or not canChange then return end
	local key = input.KeyCode
	local button = screen:FindFirstChild("Button" .. key.Name)
	if button then
		button.BackgroundColor3 = lightColor
	end
	if key == Enum.KeyCode.Z then
		togglePower()
	elseif key == Enum.KeyCode.X then
		toggleCockpit:FireServer()
	elseif key == Enum.KeyCode.C then
		toggleLandingGear:FireServer()
	elseif key == Enum.KeyCode.V then
		activateRetro()
	elseif key == Enum.KeyCode.W then
		accelerate(1)
	elseif key == Enum.KeyCode.S then
		accelerate(-1)
	elseif key == Enum.KeyCode.A then
		tilt(-1)
	elseif key == Enum.KeyCode.D then
		tilt(1)
	elseif key == Enum.KeyCode.Q then
		if not heavyEnabled then return end
		fireHeavy()
	elseif key == Enum.KeyCode.E then
		if not lightEnabled then return end
		fireLight()
	elseif key == Enum.KeyCode.LeftShift then
		switchView()
	elseif key == Enum.KeyCode.B then
		toggleControlGui()
	elseif key == Enum.KeyCode.N then
		toggleStatsGui()
	end
end

local function onInputEnded(input, gpe) --called when user input ends
	if gpe or not canChange then return end
	local key = input.KeyCode
	local button = screen:FindFirstChild("Button" .. key.Name)
	if button then
		button.BackgroundColor3 = normColor
	end
	if key == Enum.KeyCode.V then
		if engineOn.Value then
			deactivateRetro()
		end
	elseif key == Enum.KeyCode.W then
		if acceleration == 1 then
			accelerate(0)
		end
	elseif key == Enum.KeyCode.S then
		if acceleration == -1 then
			accelerate(0)
		end
	elseif key == Enum.KeyCode.A then
		if targRoll == -1 then
			tilt(0)
		end
	elseif key == Enum.KeyCode.D then
		if targRoll == 1 then
			tilt(0)
		end
	end
end

--CONNECT EVENTS

uis.InputBegan:Connect(onInputBegan)
uis.InputEnded:Connect(onInputEnded)
ship.CutPower.OnClientEvent:Connect(onPowerCutRequest)
health.Changed:Connect(updateHealthBar)
cockpitOn.Changed:Connect(onCockpitToggled)
landingGearOn.Changed:Connect(onLandingGearToggled)
