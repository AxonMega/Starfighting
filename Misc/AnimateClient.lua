--scripted by AxonMega

local character = script.Parent
local mouse = game.Players.LocalPlayer:GetMouse()
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("Torso")
local hrp = character:WaitForChild("HumanoidRootPart")
local head = character:WaitForChild("Head")
local neck = torso:WaitForChild("Neck")
local leftShoulder = torso:WaitForChild("Left Shoulder")
local rightShoulder = torso:WaitForChild("Right Shoulder")
local rootJoint = hrp:WaitForChild("RootJoint")
local uis = game:GetService("UserInputService")
local sprinting = false
local canChange = true
local currentAnim = nil
local currentTool = nil
local lastTool = nil
local currentMoveAnim = nil
local currentIdleAnim = nil
local currentToolAnim = nil
local cState = "none"
local pi = math.pi
local r1 = CFrame.Angles(pi/-2, pi/-2, pi/-2)
local r2 = CFrame.Angles(pi/-2, pi/2, pi/2)
local neckP = CFrame.new(neck.C0.p)
local leftP = CFrame.new(leftShoulder.C0.p)
local rightP = CFrame.new(rightShoulder.C0.p)
local rEvent = script:WaitForChild("Event")
local rFunction = script:WaitForChild("Function")
local lookPoint = torso:WaitForChild("LookPoint")

local function change(a, ...)
	if a == "get" then
		return rFunction:InvokeServer(...)
	else
		rEvent:FireServer(a, ...)
	end
end

local function loadAnim(name, id)
	local animation = Instance.new("Animation")
	animation.Name = name
	animation.AnimationId = "http://www.roblox.com/asset/?id=" .. id
	animation.Parent = script
	return humanoid:LoadAnimation(animation)
end

local jumpTrack = loadAnim("JumpAnim", "125750702")
local fallTrack = loadAnim("FallAnim", "180436148")
local runTrack = loadAnim("RunAnim", "180426354")
local climbTrack = loadAnim("ClimbAnim", "180436334")
local sitTrack = loadAnim("SitAnim", "178130996")
local idleTrack = loadAnim("IdleAnim", "180435571")
local crouchMoveTrack = loadAnim("CrouchMoveAnim", "441961434")
local crouchIdleTrack = loadAnim("CrouchIdleAnim", "441962317")
local crawlMoveTrack = loadAnim("CrawlMoveAnim", "441963017")
local crawlIdleTrack = loadAnim("CrawlIdleAnim", "441963517")
local sprintTrack = loadAnim("SprintAnim", "441958933")
local toolTrack1 = loadAnim("ToolAnim1", "480289237")
local toolTrack2 = loadAnim("ToolAnim2", "441960015")

currentMoveAnim = runTrack
currentIdleAnim = idleTrack
currentAnim = idleTrack
currentToolAnim = toolTrack1
idleTrack:Play()

local rotatePower = change("get", "createGyro")

local function togglePack(enabled)
	if not enabled then
		change("unequipTools")
	end
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, enabled)
end

local function isGoodState(state)
	return (not(state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll or
		state == Enum.HumanoidStateType.Seated or state == Enum.HumanoidStateType.Dead or
		state == Enum.HumanoidStateType.Physics))
end

local function isGreatState(state)
	return not(state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Swimming)
end

local function isMoveKeyDown()
	return uis:IsKeyDown(Enum.KeyCode.W) or uis:IsKeyDown(Enum.KeyCode.A) or uis:IsKeyDown(Enum.KeyCode.S) or
		uis:IsKeyDown(Enum.KeyCode.D)
end

local function rotate()
	if isGoodState(humanoid:GetState()) then
		local p = mouse.Hit.p
		local distance = (p - lookPoint.WorldPosition).magnitude
		local rotation = math.acos((lookPoint.WorldPosition.Y - mouse.Hit.y)/(distance + 1)) - pi/2
		if rotation ~= rotation then
			rotation = 0
		end
		if cState == "crawling" then
			if rotation > 0.8 then
				rotation = 0.8
			elseif rotation < -0.4 or rotation ~= rotation then
				rotation = -0.4
			end
		end
		local rotateC = CFrame.new(hrp.Position, p)
		local neckC0 = neckP*CFrame.Angles(pi/2, pi, 0)*CFrame.Angles(rotation*-1, 0, 0)
		local leftC0 = nil
		local rightC0 = nil
		if cState == "crouching" and currentTool then
			leftC0 = leftP*r1*CFrame.Angles(0, 0, rotation*-1 - pi/8)
			rightC0 = rightP*r2*CFrame.Angles(0, 0, rotation + pi/8)
		elseif cState == "crawling" and currentTool then
			if currentToolAnim == toolTrack2 then
				leftC0 = leftP*r1*CFrame.Angles(0, 0, rotation*-1 - pi/2)
			else
				leftC0 = leftP*r1*CFrame.Angles(0, 0, rotation*-1)
			end
			rightC0 = rightP*r2*CFrame.Angles(0, 0, rotation + pi/2)
		else
			leftC0 = leftP*r1*CFrame.Angles(0, 0, rotation*-1)
			rightC0 = rightP*r2*CFrame.Angles(0, 0, rotation)
		end
		change("rotate", rotateC, neckC0, leftC0, rightC0)
	end
end

local moveEvent = mouse.Move:Connect(rotate)

local function playAnim(track)
	currentAnim:Stop(0.2)
	currentAnim = track
	track:Play(0.1)
end

local function cNone()
	cState = "none"
	sprinting = false
	currentMoveAnim = runTrack
	currentIdleAnim = idleTrack
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	if not hrp:FindFirstChild("RootJoint") then
		rootJoint = change("get", "cNone", true)
	else
		change("cNone", false)
	end
	rotate()
	if humanoid:GetState() ~= Enum.HumanoidStateType.Seated then
		playAnim(currentIdleAnim)
	end
end

local function onFalling(active)
	if active and humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
		if cState ~= "none" then
			cNone()
		end
		playAnim(fallTrack)
	else
		playAnim(currentIdleAnim)
	end
end

local function onJumping(active)
	if active then
		playAnim(jumpTrack)
		if sprinting and currentTool then
			currentToolAnim:Stop(0.2)
		end
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		wait(1)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid.Jump = false
	end
end

local function onRunning(speed)
	if isMoveKeyDown() and speed > 0.1 then
		if not currentMoveAnim.IsPlaying then
			playAnim(currentMoveAnim)
			currentMoveAnim:AdjustSpeed(2)
			wait(0.2)
			currentMoveAnim:AdjustSpeed()
		end
	elseif not currentIdleAnim.IsPlaying then
		playAnim(currentIdleAnim)
	end
end

local function onClimbing(speed)
	climbTrack:AdjustSpeed(speed/12)
	if not climbTrack.IsPlaying then
		playAnim(climbTrack)
	end
end

local function onSeated(active)
	if active then
		playAnim(sitTrack)
		togglePack(false)
	end
end

local function onStateChanged(old, new)
	if not isGreatState(new) then
		if cState ~= "none" then
			cNone()
		end
	end
	if not isGoodState(new) then
		if rotatePower then
			rotatePower:Destroy()
			rotatePower = nil
		end
		if moveEvent then
			moveEvent:Disconnect()
			moveEvent = nil
		end
		if cState ~= "none" then
			cNone()
		end
		currentToolAnim:Stop(0.2)
		change("resetJoints")
	else
		if currentTool and not sprinting then
			currentTool.Enabled = true
			local newToolAnim = nil
			if not currentToolAnim.IsPlaying then
				currentToolAnim:Play(0.2)
			end
		end
		if old == Enum.HumanoidStateType.Seated then
			togglePack(true)
		end
		rotatePower = hrp:FindFirstChild("RotatePower")
		if not rotatePower then
			rotatePower = change("get", "createGyro")
		end
		if not moveEvent then
			moveEvent = mouse.Move:Connect(rotate)
		end
		rotate()
	end
end

local function onChildAdded(child)
	if child:IsA("Tool") then
		currentTool = child
		local oldToolAnim = currentToolAnim
		if child:FindFirstChild("TwoHandsRequired") then
			currentToolAnim = toolTrack2
		else
			currentToolAnim = toolTrack1
		end
		if sprinting then
			change("enableTool", child, false)
		else
			if lastTool then
				oldToolAnim:Stop(0.2)
				wait(0.2)
				if not currentTool then return end
			end
			currentToolAnim:Play(0.2)
			rotate()
		end
		lastTool = child
	end
end

local function onChildRemoved(child)
	if child == currentTool then
		change("enableTool", child, true)
		currentTool = nil
		rotate()
		currentToolAnim:Stop(0.2)
		wait(0.2)
		lastTool = nil
	end
end

local function lowCState()
	sprinting = false
	if currentTool then
		change("enableTool", currentTool, true)
	end
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	if not torso:FindFirstChild("StayJoint") then
		change("makeStayJoint")
	end
end

local function crouch()
	cState = "crouching"
	canChange = false
	currentMoveAnim = crouchMoveTrack
	currentIdleAnim = crouchIdleTrack
	change("crouch")
	if humanoid:GetState() == Enum.HumanoidStateType.Running then
		onRunning(hrp.Velocity.magnitude)
	end
	rotate()
	wait(0.1)
	canChange = true
end

local function crawl()
	cState = "crawling"
	canChange = false
	currentMoveAnim = crawlMoveTrack
	currentIdleAnim = crawlIdleTrack
	change("crawl")
	if humanoid:GetState() == Enum.HumanoidStateType.Running then
		onRunning(hrp.Velocity.magnitude)
	end
	rotate()
	wait(0.1)
	canChange = true
end

local function onInputBegan(input, gpe)
	if not gpe then
		local state = humanoid:GetState()
		if input.KeyCode == Enum.KeyCode.LeftShift then
			sprinting = true
			if cState ~= "none" then
				cNone()
			end
			currentMoveAnim = sprintTrack
			change("sprint", currentTool)
		elseif input.KeyCode == Enum.KeyCode.Space and cState ~= "none" then
			cNone()
		elseif input.KeyCode == Enum.KeyCode.Q and isGoodState(state) and isGreatState(state) and canChange then
			if cState == "none" then
				cState = "crouching"
				lowCState()
				crouch()
			elseif cState == "crouching" then
				cState = "crawling"
				crawl()
			end
		elseif input.KeyCode == Enum.KeyCode.E and isGoodState(state) and isGreatState(state) and canChange then
			if cState == "crawling" then
				crouch()
			elseif cState == "crouching" then
				cNone()
			end
		end
	end
end

local function onInputEnded(input, gpe)
	if not gpe then
		if input.KeyCode == Enum.KeyCode.LeftShift then
			if cState == "none" then
				sprinting = false
				currentMoveAnim = runTrack
				change("endSprint", currentTool)
				if currentTool and not currentToolAnim.IsPlaying then
					currentToolAnim:Play(0.2)
				end
			end
		end
	end
end

local function onJumpRequest()
	change("removeSeatWeld")
end

local function onTorsoChildAdded(child)
	if child:IsA("Motor6D") then
		if child.Name == "Neck" then
			neck = child
			wait(0.1)
			neckP = CFrame.new(neck.C0.p)
			change("newJoint", "neck", neck)
		elseif child.Name == "Left Shoulder" then
			leftShoulder = child
			wait(0.1)
			leftP = CFrame.new(leftShoulder.C0.p)
			change("newJoint", "left", leftShoulder)
		elseif child.Name == "Right Shoulder" then
			rightShoulder = child
			wait(0.1)
			rightP = CFrame.new(rightShoulder.C0.p)
			change("newJoint", "right", rightShoulder)
		end
	end
end

humanoid.FallingDown:Connect(onFalling)
humanoid.Ragdoll:Connect(onFalling)
humanoid.GettingUp:Connect(onJumping)
humanoid.Jumping:Connect(onJumping)
humanoid.Swimming:Connect(onRunning)
humanoid.FreeFalling:Connect(onFalling)
humanoid.Running:Connect(onRunning)
humanoid.Climbing:Connect(onClimbing)
humanoid.Seated:Connect(onSeated)
humanoid.StateChanged:Connect(onStateChanged)
character.ChildAdded:Connect(onChildAdded)
character.ChildRemoved:Connect(onChildRemoved)
uis.InputBegan:Connect(onInputBegan)
uis.InputEnded:Connect(onInputEnded)
uis.JumpRequest:Connect(onJumpRequest)
torso.ChildAdded:Connect(onTorsoChildAdded)

for _, child in ipairs(character:GetChildren()) do
	onChildAdded(child)
end
