--scripted by AxonMega

--DECLARE VARIABLES

local controller = script.Parent
local ship = controller:WaitForChild("MyShip").Value

while not shared.createCom do wait() end
local com = shared.createCom(script, script.Parent)

local pilot = game.Players.LocalPlayer
local mouse = pilot:GetMouse()
local cam = workspace.CurrentCamera

local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")

while not ship.SetupFinished.Value do wait() end

local guiFolder = game.ReplicatedStorage.LocalGuis

local toggleCockpit = ship.ToggleCockpit
local toggleLandingGear = ship.ToggleLandingGear

local shipRotOffset = CFrame.Angles(0, -67.54, 0)
local camRotOffset = shipRotOffset*CFrame.Angles(0, math.pi, 0)
local cx = mouse.ViewSizeX/2
local cy = mouse.ViewSizeY/2

local controlGuiOn = true
local statsGuiOn = true

local funcNames = {
	EngineOn = "Engine: ",
	CockpitOn = "Cockpit: ",
	LandingGearOn = "Landing Gear: ",
	RetroThrustersOn = "Retro Thrusters: "
}
local keyOrder = {Q = 1, E = 2, R = 3, T = 4, F = 5, G = 6}

while not com.engine do wait() end

local views = {
	rear = com.engine:WaitForChild("RearView").CFrame,
	center = com.engine:WaitForChild("CenterView").CFrame,
	front = com.engine:WaitForChild("FrontView").CFrame
}
local camOffset = views.rear

--CAMERA

local function updateCam() --updates the camera's CFrame
	cam.CFrame = com.engine.CFrame:toWorldSpace(camOffset)*camRotOffset
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


if ship.EngineOn.Value then
	toggleCam(true)
end

local function toggleCharTransparency(newTrans) --toggles the local transparency of some of the player's bodyparts
	for _, child in ipairs(pilot.Character:GetChildren()) do
		if child:IsA("BasePart") and child.Name == "Head" or child.Name == "Torso" then
			child.Transparency = newTrans
		elseif child:IsA("Accessory") then
			child.Handle.Transparency = newTrans
		end
	end
end

local function switchView() --switches the camera offset
	if not com.engineOn.Value or not com.canChange then return end
	if camOffset == views.rear then
		camOffset = views.center
		toggleCharTransparency(1)
	elseif camOffset == views.center then
		camOffset = views.front
		toggleCharTransparency(0)
	elseif camOffset == views.front then
		camOffset = views.rear
	end
end

--GUIS

local function sortKeys(a, b) --used to sort the keys that might be added to the control gui
	return keyOrder[a.Name] < keyOrder[b.Name]
end

local controlGui = guiFolder.ShipControls:Clone()
controlGui.Parent = pilot.PlayerGui
local controlFrame = controlGui:WaitForChild("Controls")
local controlToggleKey = controlGui:WaitForChild("ToggleKey")

local statsGui = guiFolder.ShipStats:Clone()
statsGui.Parent = pilot.PlayerGui
local statsFrame = statsGui:WaitForChild("Stats")
local statsToggleKey = statsGui:WaitForChild("ToggleKey")

local healthBar = statsFrame:WaitForChild("HealthBar")
local healthLabel = statsFrame:WaitForChild("HealthLabel")
local speedBar = statsFrame:WaitForChild("SpeedBar")
local speedLabel = statsFrame:WaitForChild("SpeedLabel")

local controlVs = ship.Controls:GetChildren()
table.sort(controlVs, sortKeys)

for _, controlV in ipairs(controlVs) do
	if controlV.Value ~= "None" then
		controlFrame.Size = controlFrame.Size + UDim2.new(0, 0, 0, 16)
		local newControl = Instance.new("TextLabel")
		newControl.Name = controlV.Name
		newControl.BackgroundTransparency = 1
		newControl.BorderColor3 = Color3.new(0, 0, 0)
		newControl.BorderSizePixel = 0
		newControl.Position = UDim2.new(0, 0, 0, controlFrame.Size.Y.Offset - 16)
		newControl.Size = UDim2.new(1, 0, 0, 16)
		newControl.Font = Enum.Font.SciFi
		newControl.Text = controlV.Name .. " = " .. controlV.Value
		newControl.TextColor3 = Color3.new(0, 0, 0)
		newControl.TextScaled = true
		newControl.TextWrapped = true
		newControl.TextXAlignment = Enum.TextXAlignment.Left
		newControl.Parent = controlFrame
	end
end

local yPos = controlFrame.Size.Y.Offset/-2
controlFrame.Position = UDim2.new(0, 20, 0.5, yPos)
controlToggleKey.Position = UDim2.new(0, 2, 0.5, yPos)

local function removeGuis() --removes the control and stats guis
	controlGui:Destroy()
	statsGui:Destroy()
end

local function toggleControlGui() --toggles the visibility of the control gui
	if controlGuiOn then
		controlGuiOn = false
		controlGui.Controls:TweenPosition(UDim2.new(0, -160, 0.5, yPos), Enum.EasingDirection.Out, Enum.EasingStyle.Sine,
			0.5, true)
		wait(0.5)
		if not controlGuiOn then controlToggleKey.Visible = true end
	else
		controlGuiOn = true
		controlToggleKey.Visible = false
		controlGui.Controls:TweenPosition(UDim2.new(0, 20, 0.5, yPos), Enum.EasingDirection.Out, Enum.EasingStyle.Sine,
			0.5, true)
	end
end

local function toggleStatsGui() --toggles the visibility of the stats gui
	if statsGuiOn then
		statsGuiOn = false
		statsGui.Stats:TweenPosition(UDim2.new(1, 20, 0.625, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5, true)
		wait(0.5)
		if not statsGuiOn then statsToggleKey.Visible = true end
	else
		statsGuiOn = true
		statsToggleKey.Visible = false
		statsGui.Stats:TweenPosition(UDim2.new(1, -180 ,0.625, -70), Enum.EasingDirection.Out, Enum.EasingStyle.Sine, 0.5, true)
	end
end

local function updateHealthBar(newHealth) --scales the health bar to match the ship's health
	if com.health.Value <= 0 then return end
	healthLabel.Text = "Health: " .. tostring(newHealth) .. "/" .. tostring(com.maxHealth)
	healthBar.Size = UDim2.new(0, (newHealth/com.maxHealth)*154, 0, 14)
end

local function updateSpeedBar(newSpeed) --scales the speed bar to match the ship's speed
	speedLabel.Text = "Speed: " .. tostring(math.ceil(newSpeed)) .. "/" .. tostring(com.maxSpeed)
	if newSpeed > 0  then
		speedBar.Size = UDim2.new(0, (newSpeed/com.maxSpeed)*154, 0, 14)
		speedBar.BackgroundTransparency = 0
	else
		speedBar.BackgroundTransparency = 1
	end
end

local function updateFunction(funcName, newState) --changes the displayed state of the function
	local funcStat = statsFrame:FindFirstChild(funcName)
	if not funcStat then return end
	if newState then
		funcStat.Text = funcNames[funcName] .. "On"
		funcStat.TextColor3 = Color3.new(0, 1, 0)
	else
		funcStat.Text = funcNames[funcName] .. "Off"
		funcStat.TextColor3 = Color3.new(1, 0.5, 0)
	end
end

updateHealthBar(com.health.Value)
updateSpeedBar(0)
updateFunction("EngineOn", com.engineOn.Value)
updateFunction("CockpitOn", com.cockpitOn.Value)
updateFunction("LandingGearOn", com.landingGearOn.Value)

--LOCALIZED RENDERING

local function range(n) --makes sure given number in a range of -1 to 1
	return math.clamp(n, -1, 1)
end

local function moveClient() --steers the ship on the client
	if com.speed == 0 or not com.canChange then return end
	local c = com.engine.CFrame
	local vel = (c*shipRotOffset).lookVector*-com.speed
	if com.retroOn then 
		vel = vel + c.upVector*4
	end
	local percentY = range((cx - mouse.X)/cx)
	local percentZ = range((mouse.Y - cy)/cy)
	local avy = percentY*c.upVector*com.turnSpeed
	local avz = percentZ*c.lookVector*com.turnSpeed
	com.rotatePower.AngularVelocity = (com.roll*com.turnSpeed*c.rightVector) + avy + avz
	com.jetPower.Velocity = vel
	com.leftHinge.TargetAngle = percentY*45 - 45
	com.rightHinge.TargetAngle = percentZ*45 - 45
end

local function positionLasersClient(lasers, nozzlePoints, projSpeed) --positions the fired lasers on the client
	if not lasers then return end
	for i, laser in ipairs(lasers) do
		local pos = nozzlePoints[i].WorldPosition
		local dir = nozzlePoints[i].WorldAxis
		laser.CFrame = CFrame.new(pos, pos + dir*10)*com.lasRotOffset + dir*(laser.Size.X/2)
		laser.FlyPower.Velocity = dir*projSpeed
	end
end

--CLIENT MAIN

local function stopFunctionsClient() --stops the ship's client-sided functions
	toggleCam(false)
	toggleCharTransparency(0)
	updateFunction("RetroThrustersOn", false)
end

local function togglePowerClient(on) --turns the ship off on the client
	if on then
		stopFunctionsClient()
		updateFunction("EngineOn", false)
	else
		updateFunction("EngineOn", true)
		camOffset = views.rear
		toggleCam(true)
	end
end

--HANDLING INPUT

local function onInputBegan(input, gpe) --called when user input begins
	if gpe or not com.canChange then return end
	local key = input.KeyCode.Name
	com:send("buttonDown", key)
	if key == "Z" then
		local on = com.engineOn.Value
		com:send("togglePower")
		togglePowerClient(on)
	elseif key == "X" then
		local on = not com.cockpitOn.Value
		toggleCockpit:FireServer()
		updateFunction("CockpitOn", on)
	elseif key == "C" then
		local on = not com.landingGearOn.Value
		toggleLandingGear:FireServer()
		updateFunction("LandingGearOn", on)
	elseif key == "V" then
		com:send("activateRetro")
		updateFunction("RetroThrustersOn", true)
	elseif key == "W" then
		com:send("accelerate", 1)
	elseif key == "S" then
		com:send("accelerate", -1)
	elseif key == "A" then
		com:send("tilt", -1)
	elseif key == "D" then
		com:send("tilt", 1)
	elseif key == "Q" then
		positionLasersClient(com:sendWR("fireHeavy"))
	elseif key == "E" then
		positionLasersClient(com:sendWR("fireLight"))
	end
end

local function onInputEnded(input, gpe) --called when user input ends
	if gpe or not com.canChange then return end
	local key = input.KeyCode.Name
	com:send("buttonUp", key)
	if key == "W" then
		if com.acceleration == 1 then
			com:send("accelerate", 0)
		end
	elseif key == "S" then
		if com.acceleration == -1 then
			com:send("accelerate", 0)
		end
	elseif key == "A" then
		if com.targRoll == -1 then
			com:send("tilt", 0)
		end
	elseif key == "D" then
		if com.targRoll == 1 then
			com:send("tilt", 0)
		end
	elseif key == "V" then
		com:send("deactivateRetro")
		updateFunction("RetroThrustersOn", false)
	elseif key == "LeftShift" then
		switchView()
	elseif key == "B" then
		toggleControlGui()
	elseif key == "N" then
		toggleStatsGui()
	end
end

--COMMUNICATION

local function receive(task, ...) --receives messages from the server
	if task == "startMove" then
		rs:BindToRenderStep("MoveShip", 101, moveClient)
	elseif task == "stopMove" then
		rs:UnbindFromRenderStep("MoveShip")
	elseif task == "crash" then
		togglePowerClient(true)
	elseif task == "eject" then
		removeGuis()
		if ... then
			stopFunctionsClient()
		end
	end
end

local function onVarChanged(var, newVal) --called when a shared variable is changed
	if var == "speed" then
		updateSpeedBar(newVal)
	end
end

com:setReceive(receive)
com:setOnVarChanged(onVarChanged)
com.clientReady = true
while not com.serverReady do wait() end

uis.InputBegan:Connect(onInputBegan)
uis.InputEnded:Connect(onInputEnded)
com.health.Changed:Connect(updateHealthBar)
