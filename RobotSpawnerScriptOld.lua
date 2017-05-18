--scripted by AxonMega

local spawner = script.Parent
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local stats = spawner:WaitForChild("Stats")
local equipped = false
local canSpawn = false
local despawning = false
local rStorage = game:WaitForChild("ReplicatedStorage")
local setupSpawner = require(rStorage:WaitForChild("ModuleScripts"):WaitForChild("SetupSpawner"))
local baseRobot = rStorage:WaitForChild("Npcs"):WaitForChild(string.gsub(spawner.Name, " Spawner", ""))
local baseScript = rStorage:WaitForChild("Scripts"):WaitForChild("RobotAI")
local robots = {}

while #stats:GetChildren() < 2 do wait() end
while #spawner:GetChildren() < stats.ChildCount.Value do wait() end
local beep, glowParts = setupSpawner(spawner, user.TeamColor)

local function activate()
	beep:Play()
	for _, glowPart in ipairs(glowParts) do
		glowPart.Transparency = 0
	end
end

local function deactivate()
	beep:Stop()
	for _, glowPart in ipairs(glowParts) do
		glowPart.Transparency = 0.25
	end
end

local function spawnRobot()
	if spawner.Enabled and equipped and canSpawn and #robots < stats.RobotCount.Value then
		canSpawn = false
		activate()
		local robot = baseRobot:Clone()
		table.insert(robots, robot)
		baseScript:Clone().Parent = robot
		local player = Instance.new("ObjectValue")
		player.Name = "Player"
		player.Value = user
		player.Parent = robot
		robot.Parent = workspace
		local function onAncestryChanged(_, newParent)
			if not despawning and not newParent then
				for i, robot2 in ipairs(robots) do
					if robot2 == robot then
						table.remove(robots, i)
					end
				end
			end
		end
		robot.AncestryChanged:Connect(onAncestryChanged)
		wait(1)
		deactivate()
		canSpawn = true
	end
end

local function onInput(input, gpe)
	if equipped and not gpe and input.KeyCode == Enum.KeyCode.R and #robots > 0 then
		despawning = true
		activate()
		for _, robot in ipairs(robots) do
			robot:Destroy()
		end
		robots = {}
		wait(1)
		deactivate()
		despawning = false
	end
end

local function onEquipped()
	equipped = true
	mouse.Icon = "rbxasset://textures\\gunCursor.png"
	wait(0.2)
	canSpawn = true
end

local function onUnequipped()
	equipped = false
	mouse.Icon = ""
end

if game.Players:GetPlayerFromCharacter(spawner.Parent) then
	onEquipped()
end

mouse.Button1Down:Connect(spawnRobot)
game:GetService("UserInputService").InputBegan:Connect(onInput)
spawner.Equipped:Connect(onEquipped)
spawner.Unequipped:Connect(onUnequipped)
