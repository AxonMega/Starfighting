--scripted by AxonMega

--DEFINE VARIABLES

local players = game:WaitForChild("Players")
local playerDiedC = workspace:WaitForChild("-PlayerDiedC-")
local storage = game:WaitForChild("ServerStorage")
local modFolder = game.ServerScriptService:WaitForChild("GameplayModuleScripts")
local adminUtils = require(modFolder:WaitForChild("AdminCommands"))
local shipManager = require(modFolder:WaitForChild("ShipManager"))
local gun = storage:WaitForChild("Gear"):WaitForChild("Wasp-P2")
local gunScript = storage:WaitForChild("Scripts"):WaitForChild("GunScript")
local debris = game:GetService("Debris")
local passcodeDied = "secret"
local size = Vector3.new(1000, 20, 1000)
local ms = game:GetService("MarketplaceService")
local stats = {}
local latestKillfeed = {}
local gamePasses = {
	[613029662] = {storage.Gear:WaitForChild("Ronin-X4"), storage.Scripts:WaitForChild("SwordScript")},
	[628589421] = {storage.Gear:WaitForChild("Boa-S5"), gunScript}
}

--HANDLE BATTLE STATS

local function onPlayerDied(victor, victim, passcode)
	if passcode == passcodeDied then
		playerDiedC:FireAllClients(victor, victim, passcodeDied)
		table.insert(latestKillfeed, 1, {victor.Name .. " Killed " .. victim.Name, victor.TeamColor.Color})
		latestKillfeed[7] = nil
		stats[victor].kills = stats[victor].kills + 1
		victor.leaderstats.Kills.Value = stats[victor].kills
	end
end

local function onKillfeedRequest()
	return latestKillfeed
end

--PLAYER ENTER AND LEAVE

local function onPlayerAdded(player)
	if adminUtils:isBanned(player) then return end
	stats[player] = {kills = 0, deaths = 0}
	local leaderstats = Instance.new("Configuration")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	Instance.new("IntValue", leaderstats).Name = "Kills"
	Instance.new("IntValue", leaderstats).Name = "Deaths"
	local isAdmin = adminUtils:isAdmin(player)
	local function onCharacterAdded(character)
		local gunClone = gun:Clone()
		gunClone.Parent = player.Backpack
		gunScript:Clone().Parent = gunClone
		local function onDied()
			stats[player].deaths = stats[player].deaths + 1
			player.leaderstats.Deaths.Value = stats[player].deaths
		end
		character:WaitForChild("Humanoid").Died:Connect(onDied)
		for id, asset in pairs(gamePasses) do
			if isAdmin or ms:PlayerOwnsAsset(player, id) then
				local toolClone = asset[1]:Clone()
				toolClone.Parent = player.Backpack
				asset[2]:Clone().Parent = toolClone
			end
		end
	end
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	if isAdmin then
		adminUtils:adminify(player)
	end
end

local function onPlayerRemoving(player)
	stats[player] = nil
	shipManager:removeShip(player)
	adminUtils:playerLeft(player)
end

for _, player in ipairs(players:GetPlayers()) do
	onPlayerAdded(player)
end

--CONNECT EVENTS

players.PlayerAdded:Connect(onPlayerAdded)
players.PlayerRemoving:Connect(onPlayerRemoving)
playerDiedC.OnServerEvent:Connect(onPlayerDied)
workspace:WaitForChild("-GetKillfeed-").OnServerInvoke = onKillfeedRequest
workspace:WaitForChild("-PlayerDiedS-").Event:Connect(onPlayerDied)

--SETUP SHIP SPAWNERS

shipManager:setupSpawners(workspace:WaitForChild("RedBase"):WaitForChild("ShipSpawners"))
shipManager:setupSpawners(workspace:WaitForChild("BlueBase"):WaitForChild("ShipSpawners"))

--GENERATE TERRAIN

while not workspace.Terrain do wait() end
local terrain = workspace.Terrain

local function fill(pos)
	local region = Region3.new(pos - size, pos + size)
	terrain:FillRegion(region:ExpandToGrid(4), 4, Enum.Material.Water)
end

fill(Vector3.new(1000, 30, 1000))
fill(Vector3.new(1000, 30, -1000))
fill(Vector3.new(-1000, 30, 1000))
fill(Vector3.new(-1000, 30, -1000))
