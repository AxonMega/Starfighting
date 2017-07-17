--scripted by AxonMega

local sword = script.Parent.Parent
local mouse = game.Players.LocalPlayer:GetMouse()
local equipped = false
local striking = false
local canStrike = false

while not shared.createCom do wait() end
local com = shared.createCom(script, script.Parent)

local function isGood()
	return sword.Enabled and equipped and canStrike and not striking
end

local function onButton1Down()
	if isGood() then
		striking = true
		com:sendWR()
		striking = false
	end
end

local function onEquipped()
	equipped = true
	mouse.Icon = "rbxasset://textures\\gunCursor.png"
	wait(0.2)
	canStrike = true
end

local function onUnequipped()
	equipped = false
	canStrike = false
	mouse.Icon = ""
end

mouse.Button1Down:Connect(onButton1Down)
sword.Equipped:Connect(onEquipped)
sword.Unequipped:Connect(onUnequipped)
