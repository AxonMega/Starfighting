--scripted by AxonMega

local gun = script.Parent.Parent
local ammo = gun:WaitForChild("Ammo")
local reloading = gun:WaitForChild("Reloading")
local mouse = game.Players.LocalPlayer:GetMouse()
local equipped = false
local firing = false
local canFire = false

while not shared.createCom do wait() end
local com = shared.createCom(script, script.Parent)

while not com.ready do wait() end
local interval = 1/com.stats.FireRate.Value

local function isGood()
	return gun.Enabled and equipped and canFire and not firing and not reloading.Value
end

local function isBad(part)
	return (part.CanCollide == false and part.Transparency == 1) or not part.Parent
end

local function reload()
	mouse.Icon = "rbxasset://textures\\gunWaitCursor.png"
	com:sendWR("reload")
	if equipped then
		mouse.Icon = "rbxasset://textures\\gunCursor.png"
	end
end

local function fire()
	firing = true
	local mouseP = mouse.Hit.p
	local laser = com:sendWR("fire", mouseP)
	local nozzleP = com.nozzlePoint.WorldPosition
	local dir = (mouseP - nozzleP).unit
	laser.CFrame = CFrame.new(nozzleP, mouseP)*com.lasRot + dir*com.lasOff
	laser.FlyPower.Velocity = dir*com.stats.ProjectileSpeed.Value
	local function onTouched(part)
		if isBad(part) or part:IsDescendantOf(gun) then return end
		laser.Transparency = 1
		laser.Anchored = true
	end
	laser.Touched:Connect(onTouched)
	wait(interval)
	firing = false
end

local function onButton1Down()
	if isGood() then
		if ammo.Value > 0 then
			fire()
		elseif not reloading.Value then
			reload()
		end
	end
end

local function onInput(input, gpe)
	if input.KeyCode == Enum.KeyCode.R and isGood() and not gpe and ammo.Value < com.stats.ClipSize.Value then
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

mouse.Button1Down:Connect(onButton1Down)
game:GetService("UserInputService").InputBegan:Connect(onInput)
gun.Equipped:Connect(onEquipped)
gun.Unequipped:Connect(onUnequipped)
