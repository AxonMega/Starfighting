--scripted by AxonMega

local sword = script.Parent
local user = game.Players.LocalPlayer
local mouse = user:GetMouse()
local stats = sword:WaitForChild("Stats")
local setupSword = require(game:WaitForChild("ReplicatedStorage"):WaitForChild("ModuleScripts"):WaitForChild("SetupSword"))
local equipped = false
local striking = false
local canStrike = false
local hit = false
local passcodeDamage = "secret"
local passcodeDied = "secret"
local tracks = {}

while #stats:GetChildren() < 4 do wait() end
while #sword:GetChildren() < stats.ChildCount.Value do wait() end
local sounds, anims, hitSound, bladePart = setupSword(sword, user.TeamColor, stats.Damage.Value, stats.AttackRate.Value)
while not user.Character or not user.Character.Parent do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")
for _, anim in ipairs(anims) do
	table.insert(tracks, humanoid:LoadAnimation(anim))
end
local sparkCount = math.floor(stats.Damage.Value*0.6)

math.randomseed(tick())

local function isIn(part)
	return part.CanCollide == false and part.Transparency == 1
end

local function onTouched(part)
	if not striking or hit or isIn(part) or part:IsDescendantOf(sword) then return end
	hit = true
	bladePart.HitSound:Play()
	bladePart.Sparks:Emit(sparkCount)
	local parent = part.Parent
	if not parent or not parent.Parent then return end
	local enemy = game.Players:GetPlayerFromCharacter(parent) or game.Players:GetPlayerFromCharacter(parent.Parent)
	if enemy then
		local humanoid = enemy.Character.Humanoid
		if enemy.TeamColor == user.TeamColor or humanoid.Health <= 0 then return end
		humanoid:TakeDamage(stats.Damage.Value)
		if humanoid.Health <= 0 then
			workspace["-PlayerDiedC-"]:FireServer(enemy, passcodeDied)
		end
	else
		local remote = parent:FindFirstChild("TakeDamage") or parent.Parent:FindFirstChild("TakeDamage")
		if remote then
			remote:FireServer(stats.Damage.Value, passcodeDamage)
		end
	end
end

local function strike()
	if not sword.Enabled or not equipped or striking or not canStrike then return end
	striking = true
	local sound = sounds[math.random(1, 3)]
	sound:Play()
	tracks[math.random(1, 3)]:Play(0.1, 1, stats.AttackRate.Value)
	wait(1/stats.AttackRate.Value)
	striking = false
	hit = false
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

if game.Players:GetPlayerFromCharacter(sword.Parent) then
	onEquipped()
end

mouse.Button1Down:Connect(strike)
sword.Equipped:Connect(onEquipped)
sword.Unequipped:Connect(onUnequipped)
bladePart.Touched:Connect(onTouched)
