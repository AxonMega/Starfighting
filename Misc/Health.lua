--scripted by AxonMega

local character = script.Parent
local player = game.Players:GetPlayerFromCharacter(character)
local torso = character:WaitForChild("Torso")
local humanoid = character:WaitForChild("Humanoid")
local healing = false
local deadFace = "http://www.roblox.com/asset/?id=15395252"
local cpp = PhysicalProperties.new(0.3, 0.3, 0.5)
local ballSockets = {}
local bodyparts = {
	["Head"] = {"Neck", Vector3.new(0, -0.5, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 90)},
	["Left Arm"] = {"Left Shoulder", Vector3.new(0.5, 0.5, 0), Vector3.new(-1, 0.5, 0), Vector3.new(0, 180, 0)},
	["Right Arm"] = {"Right Shoulder", Vector3.new(-0.5, 0.5, 0), Vector3.new(1, 0.5, 0), Vector3.new()},
	["Left Leg"] = {"Left Hip", Vector3.new(0, 1, 0), Vector3.new(-0.5, -1, 0), Vector3.new(0, 0, -90)},
	["Right Leg"] = {"Right Hip", Vector3.new(0, 1, 0), Vector3.new(0.5, -1, 0), Vector3.new(0, 0, -90)}
}

local takeDamage = Instance.new("BindableEvent")
takeDamage.Name = "TakeDamage"
takeDamage.Parent = character

local function onTakeDamageRequest(enemy, damage)
	if enemy.TeamColor == player.TeamColor or humanoid.Health <= 0  then return end
	humanoid:TakeDamage(damage)
	if humanoid.Health <= 0 then
		workspace["-Messaging-"].PlayerDied:Fire(enemy, player)
	end
end

takeDamage.Event:Connect(onTakeDamageRequest)

game:GetService("ContentProvider"):Preload(deadFace)
torso.CustomPhysicalProperties = cpp
character:WaitForChild("HumanoidRootPart").CustomPhysicalProperties = cpp
for name, data in pairs(bodyparts) do
	local jointName = data[1]
	local bodypart = character:WaitForChild(name)
	bodypart.CustomPhysicalProperties = cpp
	local ballSocket = Instance.new("BallSocketConstraint")
	ballSocket.Name = "Floppy " .. jointName
	ballSocket.Enabled = false
	ballSocket.LimitsEnabled = true
	if name == "Head" then
		ballSocket.UpperAngle = 30
	else
		ballSocket.UpperAngle = 90
	end
	ballSocket.Parent = torso
	local att0 = Instance.new("Attachment")
	att0.Name = jointName .. " 0"
	att0.Position = data[2]
	if name == "Left Arm" or name == "Right Arm" then
		att0.Rotation = Vector3.new(0, 0, -90)
	else
		att0.Rotation = data[4]
	end
	att0.Parent = bodypart
	local att1 = Instance.new("Attachment")
	att1.Name = jointName .. " 1"
	att1.Position = data[3]
	att1.Rotation = data[4]
	att1.Parent = torso
	ballSocket.Attachment0 = att0
	ballSocket.Attachment1 = att1
	table.insert(ballSockets, ballSocket)
end

local function canHeal()
	return humanoid.Health < humanoid.MaxHealth and humanoid.Health > 0
end

local function heal()
	if not healing and canHeal() then
		healing = true
		while canHeal() do
			wait(1)
			humanoid.Health = humanoid.Health + humanoid.MaxHealth*0.01
		end
		healing = false
	end
end

local function onDied()
	humanoid.Health = 0
	humanoid:UnequipTools()
	player.Backpack:ClearAllChildren()
	if not torso.Parent then return end
	for _, hat in ipairs(humanoid:GetAccessories()) do
		hat.Handle.CanCollide = true
	end
	for _, ballSocket in ipairs(ballSockets) do
		ballSocket.Enabled = true
	end
	if character:FindFirstChild("Head") and character.Head:FindFirstChild("face") then
		character.Head.face.Texture = deadFace
	end
	if character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart:Destroy()
	end
end

humanoid.HealthChanged:Connect(heal)
humanoid.Died:Connect(onDied)

wait(0.25)
for _, hat in ipairs(humanoid:GetAccessories()) do
	hat:WaitForChild("Handle").CustomPhysicalProperties = cpp
end
