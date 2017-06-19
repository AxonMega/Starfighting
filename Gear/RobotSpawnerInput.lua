--scripted by AxonMega

local spawner = script.Parent.Parent
local mouse = game.Players.LocalPlayer:GetMouse()
local equipped = false
local canSpawn = false
local createCom = require(864775860)
local com = createCom(script, script.Parent)

local function onButton1Down()
	if spawner.Enabled and equipped and canSpawn then
		canSpawn = false
		com:sendWR("spawn")
		canSpawn = true
	end
end

local function onInput(input, gpe)
	if equipped and not gpe and input.KeyCode == Enum.KeyCode.R then
		com:sendWR("despawn")
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

mouse.Button1Down:Connect(onButton1Down)
game:GetService("UserInputService").InputBegan:Connect(onInput)
spawner.Equipped:Connect(onEquipped)
spawner.Unequipped:Connect(onUnequipped)
