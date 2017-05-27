--scripted by AxonMega

local jetpack = script.Parent
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local stats = jetpack:WaitForChild("Stats")
local setupJetpack= require(game:WaitForChild("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("SetupJetpack"))
local equipped = false
local canActivate = false
local onBack = false
local flying = false
local event1 = nil
local event2 = nil
local rotOffset = CFrame.Angles(math.pi/2, 0, math.pi)
local terrain = workspace.Terrain

while #stats:GetChildren() < 2 do wait() end
local speed = stats.Speed.Value
while #jetpack:GetChildren() < stats.ChildCount.Value do wait() end
local jetSound, flyPower, rotatePower, jetGlows = setupJetpack(jetpack, user.TeamColor, speed)
local handle = jetpack.Handle
local joinPoint = handle:WaitForChild("JoinPoint").CFrame
while not user.Character or not user.Character.Parent do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")

local function onAnimationPlayed(track)
	if track.Name == "ToolAnim1" then
		track:Stop()
	end
end

local function onMove()
	flyPower.Velocity = (mouse.Hit.p - handle.Position).unit*speed
	rotatePower.CFrame = CFrame.new(handle.Position, mouse.Hit.p)*rotOffset
	local target = mouse.Target
	if target and (not target.CanCollide or target == terrain) and mouse.TargetFilter ~= target then
		mouse.TargetFilter = target
	end
end

local function activate()
	if jetpack.Enabled and equipped and not flying and canActivate then
		if onBack then
			flying = true
			canActivate = false
			humanoid:ChangeState(Enum.HumanoidStateType.Physics)
			event2 = mouse.Move:Connect(onMove)
			flyPower.MaxForce = Vector3.new(20000, 20000, 20000)
			rotatePower.MaxTorque = Vector3.new(20000, 20000, 20000)
			for _, jetGlow in ipairs(jetGlows) do
				jetGlow.Flames.Enabled = true
			end
			jetSound:Play()
			for i = 1, 3 do
				if not flying then break end
				for _, jetGlow in ipairs(jetGlows) do
					jetGlow.Transparency = 1 - i*0.25
					jetSound.PlaybackSpeed = speed/160 + i/6
				end
				wait(0.05)
			end
		else
			onBack = true
			if user.Character["Right Arm"]:FindFirstChild("RightGrip") then
				user.Character["Right Arm"].RightGrip.Part1 = nil
			end
			local weld = Instance.new("Weld")
			weld.Name = "BackWeld"
			weld.Part0 = handle
			weld.Part1 = user.Character.Torso
			weld.C0 = joinPoint
			weld.Parent = handle
			event1 = humanoid.AnimationPlayed:Connect(onAnimationPlayed)
			for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
				if track.Name == "ToolAnim1" then
					track:Stop()
				end
			end
		end
	end
end

local function deactivate()
	if not flying then return end
	flying = false
	humanoid:ChangeState(Enum.HumanoidStateType.Landed)
	if event2 then
		event2:Disconnect()
		event2 = nil
	end
	flyPower.MaxForce = Vector3.new(0, 0, 0)
	rotatePower.MaxTorque = Vector3.new(0, 0, 0)
	mouse.TargetFilter = nil
	for _, jetGlow in ipairs(jetGlows) do
		jetGlow.Flames.Enabled = false
	end
	for i = 1, 3 do
		for _, jetGlow in ipairs(jetGlows) do
			jetGlow.Transparency = 0.25 + i*0.25
			jetSound.PlaybackSpeed = speed/80 - i/6
		end
		wait(0.05)
	end
	jetSound:Stop()
	wait(0.1)
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
	if handle:FindFirstChild("BackWeld") then
		handle.BackWeld:Destroy()
	end
	deactivate()
	if event1 then
		event1:Disconnect()
		event1 = nil
	end
end

if game.Players:GetPlayerFromCharacter(jetpack.Parent) then
	onEquipped()
end

mouse.Button1Down:Connect(activate)
mouse.Button1Up:Connect(deactivate)
jetpack.Equipped:Connect(onEquipped)
jetpack.Unequipped:Connect(onUnequipped)
