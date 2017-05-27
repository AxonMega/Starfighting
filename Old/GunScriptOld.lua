--scripted by AxonMega

local gun = script.Parent
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local stats = gun:WaitForChild("Stats")
local equipped = false
local firing = false
local canFire = false
local projFolder = workspace:WaitForChild("-Projectiles-")
local modFolder = game:WaitForChild("ReplicatedStorage"):WaitForChild("ModuleScripts")
local setupGun = require(modFolder:WaitForChild("SetupGun"))
local createLaser = require(modFolder:WaitForChild("CreateLaser"))
local enableLaser = require(modFolder:WaitForChild("EnableLaser"))
local lasRot = CFrame.Angles(0, math.pi/2, 0)

while #stats:GetChildren() < 5 do wait() end
while #gun:GetChildren() < stats.ChildCount.Value do wait() end
local nozzlePoint = gun.Handle:WaitForChild("NozzlePoint")
local glowPart = gun.GlowPart
local ammo, reloading, fireSound, reloadSound = setupGun(gun, user.TeamColor, stats.Damage.Value, stats.FireRate.Value)
local baseLaser, baseEffect = createLaser(user.TeamColor, stats.Damage.Value, stats.ProjectileSpeed.Value)
ammo.Value = stats.ClipSize.Value

local function isGood()
	return gun.Enabled and equipped and canFire and not firing and not reloading.Value
end

local function reload()
	reloading.Value = true
	glowPart.Material = Enum.Material.SmoothPlastic
	mouse.Icon = "rbxasset://textures\\gunWaitCursor.png"
	reloadSound:Play()
	wait(2)
	ammo.Value = stats.ClipSize.Value
	reloading.Value = false
	glowPart.Material = Enum.Material.Neon
	if equipped then
		mouse.Icon = "rbxasset://textures\\gunCursor.png"
	end
end

local function fire()
	if not isGood() then return end
	if ammo.Value > 0 then
		firing = true
		fireSound:Play()
		local laser = baseLaser:Clone()
		laser.Parent = projFolder
		local hitP = mouse.Hit.p
		local pos = nozzlePoint.WorldPosition
		local dir = (hitP - pos).unit
		laser.CFrame = CFrame.new(pos, hitP)*lasRot + (dir*laser.Size.X/2)
		laser:WaitForChild("FlyPower").Velocity = dir*stats.ProjectileSpeed.Value
		ammo.Value = ammo.Value - 1
		enableLaser(user, laser, baseEffect:Clone(), gun, stats.Damage.Value)
		wait(1/stats.FireRate.Value)
		firing = false
	elseif not reloading.Value then
		reload()
	end
end

local function onInput(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.R and isGood() and ammo.Value < stats.ClipSize.Value then
		reload()
	end
end

local function onEquipped()
	equipped = true
	if reloading.Value then
		mouse.Icon = "rbxasset://textures\\gunWaitCursor.png"
	else
		mouse.Icon = "rbxasset://textures\\gunCursor.png"
	end
	wait(0.2)
	canFire = true
end

local function onUnequipped()
	equipped = false
	canFire = false
	mouse.Icon = ""
end

if game.Players:GetPlayerFromCharacter(gun.Parent) then
	onEquipped()
end

mouse.Button1Down:Connect(fire)
game:GetService("UserInputService").InputBegan:Connect(onInput)
gun.Equipped:Connect(onEquipped)
gun.Unequipped:Connect(onUnequipped)
