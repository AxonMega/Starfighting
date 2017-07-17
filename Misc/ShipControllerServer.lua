--scripted by AxonMega

--DECLARE VARIABLES

local ship = script:WaitForChild("MyShip").Value

while not shared.createCom do wait() end
local com = shared.createCom(script, script:WaitForChild("LocalShipController"))

while not ship.SetupFinished.Value do wait() end

local pilot = ship.Pilot.Value

local controlComputer = ship.ControlComputer
local screen = controlComputer.ControlPanel.Screen

com.canChange = true

com.engineOn = ship.EngineOn
com.cockpitOn = ship.CockpitOn
com.landingGearOn = ship.LandingGearOn
com.health = ship.Health

com.engine = ship.Engine
com.jetPower = com.engine.JetPower
com.rotatePower = com.engine.RotatePower
com.leftHinge = controlComputer.LeftJoystick.Hinge
com.rightHinge = controlComputer.RightJoystick.Hinge

com.maxHealth = ship.Stats.MaxHealth.Value
com.maxSpeed = ship.Stats.MaxSpeed.Value
com.maxTurnSpeed = ship.Stats.MaxTurnSpeed.Value/10

com.acceleration = 0
com.speed = 0
com.turnSpeed = 0
com.targRoll = 0
com.roll = 0

com.lasRotOffset = CFrame.Angles(0, math.pi/2, 0)

local retroOn = false
local hum = com.engine.Hum
local pitchChange = hum.PitchChange
local jetSound = com.engine.JetSound
local retroSound = com.engine.RetroSound

local thrusters, retroThrusters, lightTurrets, heavyTurrets, glowParts = ship.GetObjects:Invoke()

local normColor = ship.Color.Value.Color
local lightColor = Color3.new(normColor.r + 0.4, normColor.g + 0.4, normColor.b + 0.4)
local maxForce = Vector3.new(2000000, 2000000, 2000000)
local noForce = Vector3.new()

local turretStats = {
	heavyOn = ship.Controls.Q.Value ~= "None",
	lightOn = ship.Controls.E.Value ~= "None"
}

local modFolder = game.ServerScriptService.GearModules
local createLaser = require(modFolder:WaitForChild("CreateLaser"))
local enableLaser = require(modFolder:WaitForChild("EnableLaser"))

local projFolder = workspace["-Projectiles-"]

--FLIGHT

local function move(rot, vel, lha, rha) --steers the ship on the server
	com.rotatePower.AngularVelocity = rot
	com.jetPower.Velocity = vel
	com.leftHinge.TargetAngle = lha
	com.rightHinge.TargetAngle = rha
end

local function retroForce() --simulates the force of the retro thrusters
	while com.speed == 0 and retroOn and com.canChange and com.engineOn.Value do
		com.jetPower.Velocity = com.engine.CFrame.upVector*4
		wait(0.1)
	end
end

local function bad(thruster) --checks to see if the the given thruster is missing its glow effect
	return not thruster:FindFirstChild("JetGlow")
end

local function flameOn() --turns on the thrusters' flames
	for i = 1, 3 do
		for _, thruster in ipairs(thrusters) do
			if com.speed == 0 or bad(thruster) or not com.canChange then return end
			thruster.JetGlow.Transparency = 1 - i*0.25
		end
		wait(0.05)
	end
end

local function startMove() --starts the ship's motion
	com:send("startMove")
	com.jetPower.MaxForce = maxForce
	com.rotatePower.MaxTorque = maxForce
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
			if com.acceleration == 1 or bad(thruster) then return end
			thruster.JetGlow.Transparency = 0.25 + i*0.25
		end
		wait(0.05)
	end
end

local function stopMove() --stops the ship's motion
	com.rotatePower.MaxTorque = noForce
	local currentRetroOn = false
	if retroOn then
		currentRetroOn = true
	else
		com.jetPower.MaxForce = noForce
		com.jetPower.Velocity = noForce
	end
	com:send("stopMove")
	com.acceleration = 0
	com.speed = 0
	com.turnSpeed = 0
	com.targRoll = 0
	com.roll = 0
	jetSound:Stop()
	jetSound.PlaybackSpeed = 0.5
	jetSound.Volume = 0.5
	for _, thruster in ipairs(thrusters) do
		if thruster:FindFirstChild("JetGlow") then
			thruster.JetGlow.Flames.Rate = 0
			thruster.JetGlow.Flames.Enabled = false
		end
	end
	coroutine.resume(coroutine.create(flameOff))
	if currentRetroOn then
		retroForce()
	end
end

local function activateRetro() --turns on the retro thrusters
	if not com.canChange or not com.engineOn.Value or retroOn then return end
	retroOn = true
	retroSound:Play()
	if com.speed == 0 then
		com.jetPower.Velocity = com.engine.CFrame.upVector*4
		com.jetPower.MaxForce = maxForce
	end
	for _, thruster in ipairs(retroThrusters) do
		thruster.JetGlow.Flames.Enabled = true
	end
	for i = 1, 3 do
		for _, thruster in ipairs(retroThrusters) do
			if not retroOn or bad(thruster) or not com.canChange then return end
			thruster.JetGlow.Transparency = 1 - i*0.25
		end
		wait(0.05)
	end
	retroForce()
end

local function deactivateRetro() --turns off the retro thrusters
	if not retroOn then return end
	retroOn = false
	retroSound:Stop()
	if com.speed == 0 then
		com.jetPower.Velocity = noForce
		com.jetPower.MaxForce = noForce
	end
	for _, thruster in ipairs(retroThrusters) do
		thruster.JetGlow.Flames.Enabled = false
	end
	for i = 1, 3 do
		for _, thruster in ipairs(retroThrusters) do
			if retroOn or bad(thruster) or not com.canChange then return end
			thruster.JetGlow.Transparency = 0.25 + i*0.25
		end
		wait(0.05)
	end
end

local function updateThrusters() --changes the magnitude of the thrusters relative to the ship's speed
	for _, thruster in ipairs(thrusters) do
		thruster.JetGlow.Flames.Rate = thruster.JetGlow.Flames.Rate + com.acceleration*5
	end
	jetSound.PlaybackSpeed = 0.5 + (com.speed/com.maxSpeed)*1.5
	jetSound.Volume = 0.5 + (com.speed/com.maxSpeed)*0.5
end

local function accelerate(newAcc) --changes the acceleration of the ship
	if com.acceleration == newAcc or (com.speed == 0 and newAcc == -1) or (com.speed == com.maxSpeed and newAcc == 1)
		or not com.engineOn.Value or not com.canChange then return end
	com.acceleration = newAcc
	if com.acceleration == 0 then return end
	local percent1 = (com.maxSpeed/40)*com.acceleration
	local percent2 = (com.maxTurnSpeed/40)*com.acceleration
	local init = (com.speed == 0)
	com.speed = com.speed + percent1
	com.turnSpeed = com.turnSpeed + percent2
	if init then startMove() end
	updateThrusters()
	while com.acceleration == newAcc and com.speed > 0 and com.speed < com.maxSpeed and com.engineOn.Value and com.canChange do
		wait(0.05)
		com.speed = com.speed + percent1
		com.turnSpeed = com.turnSpeed + percent2
		updateThrusters()
	end
	com.acceleration = 0
	if com.speed == 0  then
		stopMove()
	end
	if not com.engineOn.Value then
		com.speed = 0
	end
end

local function tilt(newTargRoll) --tilts the ship along the X axis
	if com.targRoll == newTargRoll or not com.engineOn.Value or not com.canChange then return end
	com.targRoll = newTargRoll
	local percent = (newTargRoll - com.roll)/10
	for i = 1, 10 do
		if com.targRoll ~= newTargRoll or not com.engineOn.Value or not com.canChange then return end
		com.roll = com.roll + percent
		wait(0.05)
	end
end

--TURRETS

local lTurret1 = lightTurrets[1]
local hTurret1 = heavyTurrets[1]
if lTurret1 then
	local stats = lTurret1.Stats
	turretStats.ld = stats.Damage.Value
	turretStats.lps = stats.ProjectileSpeed.Value
	turretStats.lf = stats.FireRate.Value
	turretStats.lcf = true
	turretStats.lbl, turretStats.lbe = createLaser(pilot.TeamColor, turretStats.ld, turretStats.lps)
end
if hTurret1 then
	local stats = hTurret1.Stats
	turretStats.hd = stats.Damage.Value
	turretStats.hps = stats.ProjectileSpeed.Value
	turretStats.hf = stats.FireRate.Value
	turretStats.hcf = true
	turretStats.hbl, turretStats.hbe = createLaser(pilot.TeamColor, turretStats.hd, turretStats.hps)
end

local function fireTurret(turret, laser, effect, damage, projSpeed) --causes the given turret to fire
	local charge = turret.Charge
	charge.Fire:Play()
	local pos = charge.NozzlePoint.WorldPosition
	local dir = charge.NozzlePoint.WorldAxis
	laser.CFrame = CFrame.new(pos, pos + dir*10)*com.lasRotOffset + dir*(laser.Size.X/2)
	laser:WaitForChild("FlyPower").Velocity = dir*projSpeed
	laser.Parent = projFolder
	laser:SetNetworkOwner(pilot)
	enableLaser(pilot, laser, effect, ship, damage)
end

local function delayHeavy() --causes a delay before the heavy turrets can fire again
	wait(1/turretStats.hf)
	turretStats.hcf = true
end

local function fireHeavy() --fires the ship's heavy turrets
	if not com.engineOn.Value or not turretStats.hcf then return end
	local lasers = {}
	local nozzlePoints = {}
	turretStats.hcf = false
	for _, turret in ipairs(lightTurrets) do
		local laser = turretStats.hbl:Clone()
		fireTurret(turret, laser, turretStats.hbe:Clone(), turretStats.hd, turretStats.hps)
		table.insert(lasers, laser)
		table.insert(nozzlePoints, turret.Charge.NozzlePoint)
	end
	coroutine.resume(coroutine.create(delayHeavy))
	return lasers, nozzlePoints, turretStats.hps
end

local function delayLight() --causes a delay before the light turrets can fire again
	wait(1/turretStats.lf)
	turretStats.lcf = true
end

local function fireLight() --fires the ship's light turrets
	if not com.engineOn.Value or not turretStats.lcf then return end
	local lasers = {}
	local nozzlePoints = {}
	turretStats.lcf = false
	for _, turret in ipairs(lightTurrets) do
		local laser = turretStats.lbl:Clone()
		fireTurret(turret, laser, turretStats.lbe:Clone(), turretStats.ld, turretStats.lps)
		table.insert(lasers, laser)
		table.insert(nozzlePoints, turret.Charge.NozzlePoint)
	end
	coroutine.resume(coroutine.create(delayLight))
	return lasers, nozzlePoints, turretStats.lps
end

--MAIN

local function resetButtons() --sets all the buttons back to the normal color
	for _, button in ipairs(screen:GetChildren()) do
		button.BackgroundColor3 = normColor
	end
end

local function stopFunctions() --stops the ship's functions when the pilot ejects or the ship is destroyed or turned off
	if com.speed > 0 then
		stopMove()
	end
	deactivateRetro()
	resetButtons()
	com.leftHinge.TargetAngle = 0
	com.rightHinge.TargetAngle = 0
end

local function togglePower() --toggles whether the ship is on or off
	if com.engineOn.Value then
		com.engineOn.Value = false
		stopFunctions()
		for _, glowPart in ipairs(glowParts) do
			glowPart.Material = Enum.Material.SmoothPlastic
		end
		for i = 1, 40 do
			if com.engineOn.Value or not com.canChange then break end
			hum.Volume = 1 - i/40
			pitchChange.Octave = 2 - i/20
			wait(0.05)
		end
		hum:Stop()
	else
		com.engineOn.Value = true
		for _, glowPart in ipairs(glowParts) do
			glowPart.Material = Enum.Material.Neon
		end
		hum:Play()
		for i = 1, 40 do
			if not com.engineOn.Value or not com.canChange then break end
			hum.Volume = i/40
			pitchChange.Octave = i/20
			wait(0.05)
		end
	end
end

local function onPowerCutRequest(reason) --called when the pilot ejects or the ship is destroyed
	if reason == "crashed" then
		if com.engineOn.Value and com.canChange then
			com:send("crash")
			togglePower()
		end
		return
	elseif reason == "ejected" then
		if com.engineOn.Value then
			com:send("eject", true)
			stopFunctions()
		else
			com:send("eject", false)
			resetButtons()
		end
	elseif reason == "destroyed" then
		if com.engineOn.Value then
			togglePower()
		else
			resetButtons()
		end
	end
	com:send("removeGuis")
	wait(0.2)
	script:Destroy()
end

--COMMUNICATION

local function receive(task, ...)
	if task == "move" then
		move(...)
	elseif task == "buttonDown" then
		local button = screen:FindFirstChild("Button" .. ...)
		if button then
			button.BackgroundColor3 = lightColor
		end
	elseif task == "buttonUp" then
		local button = screen:FindFirstChild("Button" .. ...)
		if button then
			button.BackgroundColor3 = normColor
		end
	elseif task  == "accelerate" then
		accelerate(...)
	elseif task == "tilt" then
		tilt(...)
	elseif task == "togglePower" then
		togglePower()
	elseif task == "activateRetro" then
		activateRetro()
	elseif task == "deactivateRetro" then
		deactivateRetro()
	end
end

local function receiveWR(task)
	if task == "fireHeavy" then
		return fireHeavy()
	elseif task == "fireLight" then
		return fireLight()
	end
end

com:setReceive(receive)
com:setReceiveWR(receiveWR)
com.serverReady = true
while not com.clientReady do wait() end

ship.CutPower.Event:Connect(onPowerCutRequest)
