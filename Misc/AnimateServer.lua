--scripted by AxonMega

local animate = script.Parent
local character = animate.Parent
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("Torso")
local neck = torso:WaitForChild("Neck")
local leftShoulder = torso:WaitForChild("Left Shoulder")
local rightShoulder = torso:WaitForChild("Right Shoulder")
local hrp = character:WaitForChild("HumanoidRootPart")
local gyro
local pi = math.pi
local startCF = CFrame.new(0, 0, 0)*CFrame.Angles(pi/2, pi, 0)


local function empower(givenGyro)
	wait(0.5)
	givenGyro.MaxTorque = Vector3.new(0, 20000, 0)
end

local function onPropChange(_, task, ...)
	if task == "rotate" then
		local rotateC, neckC0, leftC0, rightC0 = ...
		gyro.CFrame = rotateC
		neck.C0 = neckC0
		leftShoulder.C0 = leftC0
		rightShoulder.C0 = rightC0
	elseif task == "createGyro" then
		gyro = Instance.new("BodyGyro")
		gyro.Name = "RotatePower"
		gyro.CFrame = character.Torso.CFrame
		gyro.MaxTorque = Vector3.new(0, 0, 0)
		gyro.P = 20000
		gyro.D = 0
		gyro.Parent = hrp
		coroutine.resume(coroutine.create(empower), gyro)
		return gyro
	elseif task == "unequipTools" then
		humanoid:UnequipTools()
	elseif task == "cNone" then
		humanoid.HipHeight = 0
		humanoid.WalkSpeed = 16
		torso:WaitForChild("StayJoint"):Destroy()
		if ... then
			local rootJoint = Instance.new("Motor6D")
			rootJoint.Name = "RootJoint"
			rootJoint.Part0 = hrp
			rootJoint.Part1 = torso
			rootJoint.Parent = hrp
			rootJoint.C0 = startCF
			rootJoint.C1 = startCF
			return rootJoint
		end
	elseif task == "resetJoints" then
		neck.C0 = CFrame.new(0, 1, 0)*CFrame.Angles(pi/2, pi, 0)
		leftShoulder.C0 = CFrame.new(-1, 0.5, 0)*CFrame.Angles(pi/-2, pi/-2, pi/-2)
		rightShoulder.C0 = CFrame.new(1, 0.5, 0)*CFrame.Angles(pi/-2, pi/2, pi/2)
	elseif task == "enableTool" then
		local tool, enabled = ...
		tool.Enabled = enabled
	elseif task == "makeStayJoint" then
		local weld = Instance.new("Weld")
		weld.Name = "StayJoint"
		weld.Part0 = torso
		weld.Part1 = hrp
		weld.C1 = CFrame.new(0, 0, 0)*CFrame.Angles(pi/-8, 0, 0)
		weld.Parent = torso
	elseif task == "crouch" then
		humanoid.HipHeight = -0.6
		humanoid.WalkSpeed = 12
		if torso:FindFirstChild("StayJoint") then
			torso.StayJoint.C0 = CFrame.new(0, 0, 0)*CFrame.Angles(pi/8, 0, 0)
			torso.StayJoint.C1 = CFrame.new(0, 0, 0)
		end
		if hrp:FindFirstChild("RootJoint") then
			hrp.RootJoint.C0 = CFrame.new(0, 0, 0)*CFrame.Angles(pi/2, pi, 0)
		end
	elseif task == "crawl" then
		humanoid.HipHeight = -2
		humanoid.WalkSpeed = 8
		if torso:FindFirstChild("StayJoint") then
			torso.StayJoint.C0 = CFrame.new(0, 0, 0)*CFrame.Angles(pi/2, 0, 0)
			torso.StayJoint.C1 = CFrame.new(0, -0.4, 0)
		end
		if hrp:FindFirstChild("RootJoint") then
			hrp.RootJoint.C0 = CFrame.new(0, -0.4, 0)*CFrame.Angles(pi/2, pi, 0)
		end
	elseif task == "sprint" then
		local currentTool = ...
		humanoid.WalkSpeed = 32
		if currentTool then
			currentTool.Enabled = false
		end
	elseif task == "endSprint" then
		local currentTool = ...
		humanoid.WalkSpeed = 16
		if currentTool then
			currentTool.Enabled = true
		end
	elseif task == "removeSeatWeld" then
		if torso:FindFirstChild("SeatWeld") then
			torso.SeatWeld:Destroy()
		end
	elseif task == "newJoint" then
		local jointType, joint = ...
		if jointType == "neck" then
			neck = joint
		elseif jointType == "left" then
			leftShoulder = joint
		elseif jointType == "right" then
			rightShoulder = joint
		end
	end
end

animate:WaitForChild("Event").OnServerEvent:Connect(onPropChange)
animate:WaitForChild("Function").OnServerInvoke = onPropChange

humanoid.AutoRotate = false
local lookPoint = Instance.new("Attachment")
lookPoint.Name = "LookPoint"
lookPoint.Position = Vector3.new(0, 1, 0)
lookPoint.Parent = torso
