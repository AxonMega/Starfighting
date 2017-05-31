--scripted by AxonMega

local gun = script.Parent
local stats = gun:WaitForChild("Stats")
local projFolder = workspace:WaitForChild("-Projectiles-")
local modFolder = game.ReplicatedStorage:WaitForChild("ModuleScripts")
local setupGun = require(modFolder:WaitForChild("SetupGun"))
local createLaser = require(modFolder:WaitForChild("CreateLaser"))
local enableLaser = require(modFolder:WaitForChild("EnableLaser"))
local lasRot = CFrame.Angles(0, math.pi/2, 0)
local user = gun.Parent.Parent

while #stats:GetChildren() < 5 do wait() end
while #gun:GetChildren() < stats.ChildCount.Value do wait() end
local nozzlePoint = gun.Handle:WaitForChild("NozzlePoint")
local interval = 1/stats.FireRate.Value
local glowPart = gun.GlowPart
local ammo, reloading, fireSound, reloadSound = setupGun(gun, user.TeamColor, stats.Damage.Value, stats.FireRate.Value)
local baseLaser, baseEffect = createLaser(user.TeamColor, stats.Damage.Value, stats.ProjectileSpeed.Value)
local lasOff = baseLaser.Size.X/2
ammo.Value = stats.ClipSize.Value

local function onInvoke(_, task, mouseP)
	if task == "fire" then
		fireSound:Play()
		local laser = baseLaser:Clone()
		local nozzleP = nozzlePoint.WorldPosition
		local dir = (mouseP - nozzleP).unit
		laser.CFrame = CFrame.new(nozzleP, mouseP)*lasRot + dir*lasOff
		laser:WaitForChild("FlyPower").Velocity = dir*stats.ProjectileSpeed.Value
		laser.Parent = projFolder
		laser:SetNetworkOwner(user)
		ammo.Value = ammo.Value - 1
		enableLaser(user, laser, baseEffect:Clone(), gun, stats.Damage.Value)
		return laser
	elseif task == "reload" then
		reloading.Value = true
		glowPart.Material = Enum.Material.SmoothPlastic
		reloadSound:Play()
		wait(2)
		ammo.Value = stats.ClipSize.Value
		glowPart.Material = Enum.Material.Neon
		reloading.Value = false
	elseif task == "get" then
		return nozzlePoint, interval, lasRot, lasOff	
	end
end

script:WaitForChild("Function").OnServerInvoke = onInvoke

local ready = Instance.new("BoolValue")
ready.Name = "Ready"
ready.Value = true
ready.Parent = script
