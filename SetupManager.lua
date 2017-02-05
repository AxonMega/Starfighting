--scripted by AxonMega

local ship = script.Parent
local pilot = ship:WaitForChild("Pilot").Value
local stats = ship:WaitForChild("Stats")
local parts = ship:WaitForChild("Parts")
local engine = ship:WaitForChild("Engine")
local modFolder = game.ServerScriptService.ModuleScripts
local mods = {
	setupLandingLeg = require(modFolder.SetupLandingLeg), setupThruster = require(modFolder.SetupThruster),
	setupGunPort = require(modFolder.SetupGunPort), setupPilotChair = require(modFolder.SetupPilotChair),
	setupPilotChair = require(modFolder.SetupPilotChair), setupControlComputer = require(modFolder.SetupControlComputer),
	setupCockpit = require(modFolder.SetupCockpit), colorChange = require(modFolder.ColorChange),
	colorChange = require(modFolder.ColorChange), setupLandingGear = require(modFolder.SetupLandingGear),
	setupEngine = require(modFolder.SetupEngine), shipHealth = require(modFolder.ShipHealth)
}
local landingLegs = {}
local thrusters = {}
local retroThrusters = {}
local lightTurrets = {}
local heavyTurrets = {}
local glowParts = {}

local function join(part0, part1)
	local weld = Instance.new("Weld")
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:toObjectSpace(part1.CFrame)
	weld.Parent = part0
end

local function returnObjects()
	return thrusters, retroThrusters, lightTurrets, heavyTurrets, glowParts
end

while #stats:GetChildren() < 7 do wait() end
Instance.new("BoolValue", ship).Name = "SetupFinished"
Instance.new("BoolValue", ship).Name = "EngineOn"
Instance.new("BoolValue", ship).Name = "CockpitOn"
Instance.new("BoolValue", ship).Name = "LandingGearOn"
Instance.new("IntValue", ship).Name = "Health"
Instance.new("RemoteFunction", ship).Name = "GetObjects"
Instance.new("RemoteEvent", ship).Name = "ToggleCockpit"
Instance.new("RemoteEvent", ship).Name = "ToggleLandingGear"
Instance.new("RemoteEvent", ship).Name = "CutPower"
Instance.new("RemoteEvent", ship).Name = "TakeDamage"
ship.CockpitOn.Value = true
ship.Health.Value = stats.MaxHealth.Value
while #ship:GetChildren() < stats.ChildCount.Value do wait() end
while #parts:GetChildren() < stats.PartCount.Value do wait() end
for _, child in ipairs(parts:GetChildren()) do
	join(engine, child)
	child.Anchored = false
	if child.Name == "GlowPart" then
		table.insert(glowParts, child)
	end
end
for _, child in ipairs(ship:GetChildren()) do
	if child.Name == "LandingLeg" then
		table.insert(landingLegs, child)
		mods.setupLandingLeg(child, engine)
	elseif child.Name == "Thruster" then
		table.insert(thrusters, child)
		mods.setupThruster(child, engine)
	elseif child.Name == "RetroThruster" then
		table.insert(retroThrusters, child)
		mods.setupThruster(child, engine)
	elseif child.Name == "LightGunPort" then
		local turret = mods.setupGunPort(child, ship)
		table.insert(lightTurrets, turret)
		table.insert(glowParts, turret.GlowPart)
	elseif child.Name == "HeavyGunPort" then
		local turret = mods.setupGunPort(child, engine)
		table.insert(heavyTurrets, turret)
		table.insert(glowParts, turret.GlowPart)
	end
end
ship.GetObjects.OnServerInvoke = returnObjects
mods.setupPilotChair(ship, pilot)
mods.setupControlComputer(ship)
mods.setupCockpit(ship, pilot)
mods.colorChange(ship, pilot.TeamColor)
mods.setupLandingGear(landingLegs, ship, pilot)
mods.setupEngine(engine)
mods.shipHealth(ship, pilot)
ship.SetupFinished.Value = true
