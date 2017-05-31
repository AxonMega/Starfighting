--scripted by AxonMega

local storage = game.ServerStorage
local ship = storage:WaitForChild("Ships"):WaitForChild("Protostar-A1")
local setupManager = storage:WaitForChild("Scripts"):WaitForChild("SetupManager")
local ships = {}
local shipManager = {}

local function setupButton(button)
	local beep = Instance.new("Sound")
	beep.Name = "Beep"
	beep.SoundId = "https://www.roblox.com/asset?id=161164363"
	beep.Parent = button
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 16
	clicker.Parent = button
	return beep, clicker
end

local function setupSpawner(spawner, spawners)
	local button = spawner:WaitForChild("Button")
	local beep, clicker = setupButton(button)
	local spawnZone = spawners["SpawnZone" .. string.sub(spawner.Name, 12)]
	local clickable = true
	local function onClick(player)
	if clickable then
			clickable = false
			if ships[player.Name] then
				ships[player.Name]:Destroy()
			end
			beep:Play()
			button.Transparency = 0
			local region = Region3.new(spawnZone.Position - Vector3.new(12, -1, 12),
				spawnZone.Position + Vector3.new(12, 8.5, 12))
			local toIgnore = {}
			for _, player in ipairs(game.Players:GetPlayers()) do
				table.insert(toIgnore, player.Character)
			end
			if workspace:IsRegion3EmptyWithIgnoreList(region, toIgnore) then
				local shipClone = ship:Clone()
				ships[player.Name] = shipClone
				local pilot = Instance.new("ObjectValue")
				pilot.Name = "Pilot"
				pilot.Value = player
				pilot.Parent = shipClone
				local cp = shipClone:WaitForChild("CenterPart")
				shipClone.Parent = workspace
				shipClone:SetPrimaryPartCFrame(spawnZone.CFrame + Vector3.new(0, shipClone.PrimaryPart.Size.Y/2 + 4, 0))
				cp:Destroy()
				setupManager:Clone().Parent = shipClone
				local function onChanged(property)
					if property == "Parent" and not shipClone.Parent then
						ships[player.Name] = nil
					end
				end
				shipClone.Changed:Connect(onChanged)
			end
			wait(1)
			button.Transparency = 0.25
			beep:Stop()
			clickable = true
		end
	end
	clicker.MouseClick:Connect(onClick)
end

local function setupDespawner(despawner)
	local button = despawner:WaitForChild("Button")
	local beep, clicker = setupButton(button)
	local clickable = true
	local function onClick(player)
		if ships[player.Name] and clickable then
			clickable = false
			beep:Play()
			button.Transparency = 0
			ships[player.Name]:Destroy()
			ships[player.Name] = nil
			wait(1)
			button.Transparency = 0.25
			beep:Stop()
			clickable = true
		end
	end
	clicker.MouseClick:Connect(onClick)
end

function shipManager:removeShip(player)
	if ships[player.Name] then
		ships[player.Name]:Destroy()
		ships[player.Name] = nil
	end
end

function shipManager:setupSpawners(spawners)
	while #spawners:GetChildren() < 14 do wait() end
	for _, child in ipairs(spawners:GetChildren()) do
		if string.sub(child.Name, 1, 11) == "ShipSpawner" then
			setupSpawner(child, spawners)
		elseif child.Name == "ShipDespawner" then
			setupDespawner(child)
		end
	end
end

return shipManager
