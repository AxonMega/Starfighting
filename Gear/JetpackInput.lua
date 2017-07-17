--scripted by AxonMega

local jetpack = script.Parent.Parent
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local equipped = false
local canActivate = false
local onBack = false
local flying = false

while not shared.createCom do wait() end
local com = shared.createCom(script, script.Parent)

while not com.ready do wait() end
while not user.Character do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")

local function onAnimationPlayed(track)
	if track.Name == "ToolAnim1" then
		track:Stop()
	end
end

local function onMove()
	local mouseP = mouse.Hit.p
	com:send(mouseP)
	local handleP = com.handle.Position
	com.flyPower.Velocity = (mouseP - handleP).unit*com.speed
	com.rotatePower.CFrame = CFrame.new(handleP, mouseP)*com.rotOffset
	local target = mouse.Target
	if target and not target.CanCollide and mouse.TargetFilter ~= target then
		mouse.TargetFilter = target
	end	
end

local function onButton1Down()
	if jetpack.Enabled and equipped and not flying and canActivate then
		if onBack then
			flying = true
			canActivate = false
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			event2 = mouse.Move:Connect(onMove)
			com:sendWR("activate")
		else
			onBack = true
			event1 = humanoid.AnimationPlayed:Connect(onAnimationPlayed)
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				if track.Name == "ToolAnim1" then
					track:Stop()
				end
			end
			com:sendWR("onBack")
		end
	end
end

local function onButton1Up()
	if not flying then return end
	flying = false
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	if event2 then
		event2:Disconnect()
		event2 = nil
	end
	com:sendWR("deactivate")
	if not equipped then return end
	canActivate = true
end

local function onEquipped()
	equipped = true
	mouse.Icon = "rbxasset://textures\\gunCursor.png"
	wait(0.2)
	canActivate = true
end

local function onUnequipped()
	equipped = false
	canActivate = false
	mouse.Icon = ""
	onBack = false
	com:sendWR("offBack")
	onButton1Up()
	if event1 then
		event1:Disconnect()
		event1 = nil
	end
end

mouse.Button1Down:Connect(onButton1Down)
mouse.Button1Up:Connect(onButton1Up)
jetpack.Equipped:Connect(onEquipped)
jetpack.Unequipped:Connect(onUnequipped)
