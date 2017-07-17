--scripted by AxonMega

local spawner = script.Parent
local user = spawner.Parent.Parent
local stats = spawner:WaitForChild("Stats")
local setupSpawner = require(game.ServerScriptService:WaitForChild("GearModules"):WaitForChild("SetupSpawner"))
local baseRobot = game.ServerStorage:WaitForChild("Npcs"):WaitForChild(string.gsub(spawner.Name, " Spawner", ""))
local baseScript = game.ServerStorage:WaitForChild("Scripts"):WaitForChild("RobotAI")
local despawning = false
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

local function receiveWR(task)
	if task == "spawn" then
		if #robots >= stats.RobotCount.Value then return end
		activate()
		local robot = baseRobot:Clone()
		table.insert(robots, robot)
		baseScript:Clone().Parent = robot
		local player = Instance.new("ObjectValue")
		player.Name = "Player"
		player.Value = user
		player.Parent = robot
		robot.Parent = workspace
		local function onParentChanged()
			if not despawning then
				for i, robot2 in ipairs(robots) do
					if robot2 == robot then
						table.remove(robots, i)
					end
				end
			end
		end
		robot:GetPropertyChangedSignal("Parent"):Connect(onParentChanged)
		wait(1)
		deactivate()
	elseif task == "despawn" then
		if #robots == 0 then return end
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

while not shared.createCom do wait() end
local com = shared.createCom(script, script:WaitForChild("RobotSpawnerInput"), {receiveWR = receiveWR})
