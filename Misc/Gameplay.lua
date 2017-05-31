--scripted by AxonMega

--DECLARE VARIABLES

local players = game.Players
local storage = game.ServerStorage
local killfeedEvent = workspace:WaitForChild("-KillfeedEvent-")
local modFolder = game.ServerScriptService:WaitForChild("GameplayModuleScripts")
local adminUtils = require(modFolder:WaitForChild("AdminCommands"))
local shipManager = require(modFolder:WaitForChild("ShipManager"))
local setupOutpost = require(modFolder:WaitForChild("Outposts"))
local gear = storage:WaitForChild("Gear")
local scripts = storage:WaitForChild("Scripts")
local gun = gear:WaitForChild("Wasp-P2")
local debris = game:GetService("Debris")
local passcodeDied = "secret"
local ms = game:GetService("MarketplaceService")
local stats = {}
local latestKillfeed = {}
local gamePasses = {
	[613029662] = {gear:WaitForChild("Ronin-X4"), scripts:WaitForChild("SwordScript")},
	[628589421] = {gear:WaitForChild("Boa-S5"), scripts:WaitForChild("GunScript")},
	[669635802] = {gear:WaitForChild("Falcon-J6"), scripts:WaitForChild("JetpackScript")},
	[740135495] = {gear:WaitForChild("K3v1n-B7 Spawner"), scripts:WaitForChild("RobotSpawnerScript")}
}

--HANDLE GAME PASSES

local function onGiveGearRequest(player, assetId)
	local asset = gamePasses[assetId]
	if asset then
		local toolClone = asset[1]:Clone()
		asset[2]:Clone().Parent = toolClone
		toolClone.Parent = player.Backpack
	end
end

--HANDLE BATTLE STATS

local function onPlayerDied(victor, victim, passcode)
	if passcode == passcodeDied then
		stats[victor].kills = stats[victor].kills + 1
		victor.leaderstats.Kills.Value = stats[victor].kills
		print(victor, "has killed", victim) --TESTING
		killfeedEvent:FireAllClients(victor, victim, passcodeDied)
		table.insert(latestKillfeed, 1, {victor.Name .. " Killed " .. victim.Name, victor.TeamColor.Color})
		latestKillfeed[7] = nil
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
		scripts.GunScript:Clone().Parent = gunClone
		local dead = false
		local function onDied()
			if dead then return end
			dead = true
			stats[player].deaths = stats[player].deaths + 1
			player.leaderstats.Deaths.Value = stats[player].deaths
		end
		character:WaitForChild("Humanoid").Died:Connect(onDied)
		for id, asset in pairs(gamePasses) do
			if isAdmin or ms:PlayerOwnsAsset(player, id) then
				local toolClone = asset[1]:Clone()
				asset[2]:Clone().Parent = toolClone
				toolClone.Parent = player.Backpack
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
workspace:WaitForChild("-PlayerDied-").Event:Connect(onPlayerDied)
workspace:WaitForChild("-GetKillfeed-").OnServerInvoke = onKillfeedRequest
workspace:WaitForChild("-GivePlayerGear-").Event:Connect(onGiveGearRequest)

--SETUP SHIP SPAWNERS AND OUTPOSTS

shipManager:setupSpawners(workspace:WaitForChild("RedBase"):WaitForChild("ShipSpawners"))
shipManager:setupSpawners(workspace:WaitForChild("BlueBase"):WaitForChild("ShipSpawners"))
--[[setupOutpost(workspace:WaitForChild("OutpostA"))
setupOutpost(workspace:WaitForChild("OutpostB"))
setupOutpost(workspace:WaitForChild("OutpostX"))
setupOutpost(workspace:WaitForChild("OutpostY"))]]
