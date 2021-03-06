--scripted by AxonMega

local character = script.Parent.Parent
local humanoid = character:WaitForChild("Humanoid")
local torso = character:WaitForChild("Torso")
local hrp = character:WaitForChild("HumanoidRootPart")
local neck = torso:WaitForChild("Neck")
local leftShoulder = torso:WaitForChild("Left Shoulder")
local rightShoulder = torso:WaitForChild("Right Shoulder")
local pi = math.pi
local startCF = CFrame.new()*CFrame.Angles(pi/2, pi, 0)
local gyro

humanoid.AutoRotate = false
local lookPoint = Instance.new("Attachment")
lookPoint.Name = "LookPoint"
lookPoint.Position = Vector3.new(0, 1, 0)
lookPoint.Parent = torso

local function enableGyro()
	wait(0.5)
	gyro.MaxTorque = Vector3.new(0, 20000, 0)
end

local function receive(task, ...)
	if task == "rotate" then
		local rotateC, neckC0, leftC0, rightC0 = ...
		gyro.CFrame = rotateC
		neck.C0 = neckC0
		leftShoulder.C0 = leftC0
		rightShoulder.C0 = rightC0
	elseif task == "unequipTools" then
		humanoid:UnequipTools()
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
		weld.C1 = CFrame.Angles(pi/-8, 0, 0)
		weld.Parent = torso
	elseif task == "crouch" then
		humanoid.HipHeight = -0.6
		humanoid.WalkSpeed = 12
		if torso:FindFirstChild("StayJoint") then
			torso.StayJoint.C0 = CFrame.Angles(pi/8, 0, 0)
			torso.StayJoint.C1 = CFrame.new()
		end
		if hrp:FindFirstChild("RootJoint") then
			hrp.RootJoint.C0 = CFrame.Angles(pi/2, pi, 0)
		end
	elseif task == "crawl" then
		humanoid.HipHeight = -2
		humanoid.WalkSpeed = 8
		if torso:FindFirstChild("StayJoint") then
			torso.StayJoint.C0 = CFrame.Angles(pi/2, 0, 0)
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
	elseif task == "disableGyro" then
		gyro.MaxTorque = Vector3.new()
	elseif task == "enableGyro" then
		coroutine.resume(coroutine.create(enableGyro))
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

local function receiveWR(task, ...)
	if task == "createGyro" then
		gyro = Instance.new("BodyGyro")
		gyro.Name = "RotatePower"
		gyro.CFrame = character.Torso.CFrame
		gyro.MaxTorque = Vector3.new()
		gyro.P = 20000
		gyro.D = 0
		gyro.Parent = hrp
		coroutine.resume(coroutine.create(enableGyro))
		return gyro
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
	end
end

while not shared.createCom do wait() end
local com = shared.createCom(script, script.Parent, {receive = receive, receiveWR = receiveWR})
