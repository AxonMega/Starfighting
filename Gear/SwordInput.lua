--scripted by AxonMega

local sword = script.Parent.Parent
local rFunc = sword.SwordScript:WaitForChild("Function")
local mouse = game.Players.LocalPlayer:GetMouse()
local equipped = false
local striking = false
local canStrike = false

local function isGood()
	return sword.Enabled and equipped and canStrike and not striking
end

local function onButton1Down()
	if isGood() then
		striking = true
		rFunc:InvokeServer()
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

sword.Equipped:Connect(onEquipped)
sword.Unequipped:Connect(onUnequipped)
mouse.Button1Down:Connect(onButton1Down)
