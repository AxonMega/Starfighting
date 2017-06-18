--scripted by AxonMega

local sword = script.Parent
local stats = sword:WaitForChild("Stats")
local setupSword = require(game.ReplicatedStorage:WaitForChild("ModuleScripts"):WaitForChild("SetupSword"))
local user = sword.Parent.Parent
local canHurt = false
local hit = false
local tracks = {}
local passcodeDamage = "secret"
local passcodeDied = "secret"

while #stats:GetChildren() < 4 do wait() end
while #sword:GetChildren() < stats.ChildCount.Value do wait() end
local interval = 1/stats.AttackRate.Value
local sparkCount = math.floor(stats.Damage.Value*0.6)
local sounds, anims, hitSound, bladePart = setupSword(sword, user.TeamColor, stats.Damage.Value, stats.AttackRate.Value)
while not user.Character or not user.Character.Parent do wait() end
local humanoid = user.Character:WaitForChild("Humanoid")
for _, anim in ipairs(anims) do
	table.insert(tracks, humanoid:LoadAnimation(anim))
end

local function isBad(part)
	return (part.CanCollide == false and part.Transparency == 1) or not part.Parent
end

local function onTouched(part)
	if not canHurt or hit or isBad(part) or part:IsDescendantOf(sword) then return end
	hit = true
	bladePart.HitSound:Play()
	bladePart.Sparks:Emit(sparkCount)
	local parent = part.Parent
	local remote = parent:FindFirstChild("TakeDamageS")
	if remote then
		remote:Fire(stats.Damage.Value, passcodeDamage)
	end
end

local function receiveWR()
	canHurt = true
	sounds[math.random(1, 3)]:Play()
	tracks[math.random(1, 3)]:Play(0.1, 1, stats.AttackRate.Value)
	wait(interval)
	canHurt = false
	hit = false
end

bladePart.Touched:Connect(onTouched)

local createCom = require(864775860)
local com = createCom(script, script:WaitForChild("SwordInput"), {receiveWR = receiveWR})
