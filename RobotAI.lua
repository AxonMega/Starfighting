--scripted by AxonMega

local robot = script.Parent
local body = robot:WaitForChild("Body")
local player = robot:WaitForChild("Player").Value
local torso = player.Character.Torso
local head = player.Character.Head
local humanoid = player.Character.Humanoid
local stats = robot:WaitForChild("Stats")
local projFolder = workspace:WaitForChild("-Projectiles-")
local modFolder = game.ReplicatedStorage:WaitForChild("ModuleScripts")
local setupRobot = require(modFolder:WaitForChild("SetupRobot"))
local createLaser = require(modFolder:WaitForChild("CreateLaser"))
local enableLaser = require(modFolder:WaitForChild("EnableLaser"))
local health = stats.MaxHealth.Value
local offset = Vector3.new(0, 5, 0)
local lastSpeed = 20
local lastOff = nil
local timer = 0
local hover = Vector3.new(0, 0, 0)
local hoverDir = 1
local target = nil
local targetTorso = nil
local lastFire = 0
local lasRot = CFrame.Angles(0, math.pi/2, 0)
local passcodeDamage = "--[[Evil Coasters 206827]]--"

math.randomseed(tick())

while #stats:GetChildren() < 5 do wait() end
while #robot:GetChildren() < stats.ChildCount.Value do wait() end
local nozzlePoint = robot.Body:WaitForChild("NozzlePoint")
local glowParts, flyPower, rotatePower, hum, fireSound = setupRobot(robot, player.TeamColor, stats.FireRate.Value)
local baseLaser, baseEffect = createLaser(player.TeamColor, stats.Damage.Value, stats.ProjectileSpeed.Value)

hum:Play()

local healthBar = robot.HealthDisplay:WaitForChild("HealthBar")

local function onDamaged(enemy, damage, passcode)
	if enemy.TeamColor == player.TeamColor or health == 0 or passcode ~= passcodeDamage then return end
	health = math.max(health - damage, 0)
	if health == 0 then
		healthBar.Visible = false
	else
		healthBar.Size = UDim2.new((health/stats.MaxHealth.Value)*0.6, 0, 0.1, 0)
	end
end

robot.TakeDamageC.OnServerEvent:Connect(onDamaged)
robot.TakeDamageS.Event:Connect(onDamaged)

local function randOffset()
	return Vector3.new(math.random(-40, 40)/10, math.random(40, 60)/10, math.random(-40, 40)/10)
end

local function teleport()
	robot:MoveTo(torso.Position + randOffset())
end

teleport()

local function fire()
	local now = elapsedTime()
	if now - lastFire >= 1/stats.FireRate.Value then
		lastFire = now
		fireSound:Play()
		local laser = baseLaser:Clone()
		laser.Parent = projFolder
		local pos = nozzlePoint.WorldPosition
		local dir = nozzlePoint.WorldAxis
		laser.CFrame = CFrame.new(pos, pos + dir*10)*lasRot + dir*(laser.Size.X/2)
		laser:WaitForChild("FlyPower").Velocity = dir*stats.ProjectileSpeed.Value
		enableLaser(player, laser, baseEffect:Clone(), robot, stats.Damage.Value)
	end
end

local function onAncestryChanged(_, newParent)
	if not newParent then
		robot:Destroy()
	end
end

torso.AncestryChanged:Connect(onAncestryChanged)

local function goodTarget(prospect)
	local character = prospect.Character
	if character and character:FindFirstChild("Torso") and character.Humanoid.Health > 0 then
		local ray = Ray.new(body.Position, character.Torso.Position - body.Position)
		local part = workspace:FindPartOnRay(ray, robot)
		local distance = ray.Direction.magnitude
		if part and part:IsDescendantOf(character) and distance < 80 then
			return distance
		end
	end
end

local function findTarget()
	local minDistance = 80
	local closest = nil
	for _, prospect in ipairs(game.Players:GetPlayers()) do
		if prospect.TeamColor ~= player.TeamColor then
			local distance = goodTarget(prospect)
			if distance and distance < minDistance then
				closest = prospect
				minDistance = distance
			end
		end
	end
	if closest then
		return closest, closest.Character.Torso
	end
end

local function rotate(to)
	rotatePower.CFrame = CFrame.new(body.Position, to)
end

while health > 0 do
	if target then
		if goodTarget(target) then
			fire()
		else
			target = nil
			targetTorso = nil
		end
	else
		target, targetTorso = findTarget()
	end
	local distance = (torso.Position + offset - body.Position).magnitude
	if distance > 80 then
		teleport()
	elseif distance > 5 then
		local speed = 0
		local playerMoving = true
		if torso.Velocity.magnitude > humanoid.WalkSpeed then
			speed = torso.Velocity.magnitude
		else
			speed = lastSpeed
			playerMoving = false
		end
		if not lastOff then
			lastOff = randOffset()
		end
		local to = torso.Position + lastOff
		flyPower.Velocity = (to - body.Position).unit*speed + hover
		if targetTorso then
			rotate(targetTorso.Position)
		else
			rotate(to)
		end
		if playerMoving then
			lastSpeed = flyPower.Velocity.magnitude
		end
	else
		flyPower.Velocity = hover
		if targetTorso then
			rotate(targetTorso.Position)
		else
			rotatePower.CFrame = head.CFrame
		end
		lastSpeed = 20
		randOff = nil
	end
	timer = timer + hoverDir
	hover = Vector3.new(0, ((7.5 - math.abs(timer))/25)*hoverDir, 0)
	if timer == 15 or timer == -15 then
		timer = 0
		hoverDir = -hoverDir
	end
	wait(0.15)
end
for _, glowPart in ipairs(glowParts) do
	glowPart.Material = Enum.Material.SmoothPlastic
end
hum:Stop()
flyPower:Destroy()
rotatePower:Destroy()
wait(5)
robot:Destroy()
