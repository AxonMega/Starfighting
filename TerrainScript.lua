--scripted by AxonMega

local terrain = script.Parent
local size = Vector3.new(1000, 20, 1000)
local underwater = {}

local function fill(pos)
	local region = Region3.new(pos - size, pos + size)
	terrain:FillRegion(region:ExpandToGrid(4), 4, Enum.Material.Water)
end

fill(Vector3.new(1000, 30, 1000))
fill(Vector3.new(1000, 30, -1000))
fill(Vector3.new(-1000, 30, 1000))
fill(Vector3.new(-1000, 30, -1000))


local function isUnderwater(part)
	local p = part.Position
	return p.X >= -2000 and p.X <= 2000 and p.Y >= 10 and p.Y <= 50 and p.Z >= -2000 and p.Z <= 2000
end

local function onTouched(part)
	local parent = part.Parent
	if not parent or not parent:IsA("Model") or underwater[parent] then return end
	if parent:FindFirstChild("ItemType") and parent.ItemType.Value == "Starfighter" then
		underwater[parent] = true
		wait(0.6)
		if isUnderwater(part) then
			parent.CutPower:FireClient(parent.Pilot.Value, "crashed")
		end
		underwater[parent] = false
	elseif game.Players:GetPlayerFromCharacter(parent) then
		underwater[parent] = true
		wait(0.3)
		while underwater[parent] and parent:FindFirstChild("Torso") do
			if parent.Torso.Velocity.magnitude > 20 and isUnderwater(parent.Torso) then
				parent.Humanoid:UnequipTools()
			end
			wait(0.6)
		end
	end
end

local function onTouchEnded(part)
	local parent = part.Parent
	if not parent or not parent:IsA("Model") or not game.Players:GetPlayerFromCharacter(parent) then return end
	underwater[parent] = false
end

terrain.Touched:Connect(onTouched)
terrain.TouchEnded:Connect(onTouchEnded)
