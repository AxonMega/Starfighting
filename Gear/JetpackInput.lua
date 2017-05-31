--scripted by AxonMega

local jetpack = script.Parent.Parent
local rEvent = jetpack.JetpackScript:WaitForChild("Event")
local rFunction = jetpack.JetpackScript:WaitForChild("Function")
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local equipped = false
local canActivate = false
local onBack = false
local flying = false
local event1, event2, handle, flyPower, rotatePower, speed, rotOffset

while not user.Character do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")

local function onAnimationPlayed(track)
	if track.Name == "ToolAnim1" then
		track:Stop()
	end
end

local function onMove()
	local mouseP = mouse.Hit.p
	rEvent:FireServer(mouseP)
	local handleP = handle.Position
	flyPower.Velocity = (mouseP - handleP).unit*speed
	rotatePower.CFrame = CFrame.new(handleP, mouseP)*rotOffset
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
			rFunction:InvokeServer("activate")
		else
			onBack = true
			event1 = humanoid.AnimationPlayed:Connect(onAnimationPlayed)
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				if track.Name == "ToolAnim1" then
					track:Stop()
				end
			end
			rFunction:InvokeServer("onBack")
		end
	end
end

local function onButton1Up()
	if not flying then return end
	flying = false
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)
	if event2 then
		event2:Disconnect()
		event2 = nil
	end
	rFunction:InvokeServer("deactivate")
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
	rFunction:InvokeServer("offBack")
	onButton1Up()
	if event1 then
		event1:Disconnect()
		event1 = nil
	end
end

jetpack.JetpackScript:WaitForChild("Ready")
handle, flyPower, rotatePower, speed, rotOffset = rFunction:InvokeServer("get")

mouse.Button1Down:Connect(onButton1Down)
mouse.Button1Up:Connect(onButton1Up)
jetpack.Equipped:Connect(onEquipped)
jetpack.Unequipped:Connect(onUnequipped)
