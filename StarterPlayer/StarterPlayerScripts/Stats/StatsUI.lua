-- StatsUI (Client)
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Handles client-side stat interactions

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

-- Wait for StatRemote with timeout
local statRemote = ReplicatedStorage:WaitForChild("StatRemote", 10)
if not statRemote then
	warn("StatRemote not found in ReplicatedStorage!")
	return
end

-- Wait for player stats to load with timeout
local stats = player:WaitForChild("Stats", 10)
if not stats then
	warn("Stats folder not found! Make sure PlayerStatsManager is running on server.")
	return
end

-- Wait for all stat values
local strength = stats:WaitForChild("Strength", 5)
local dexterity = stats:WaitForChild("Dexterity", 5)
local constitution = stats:WaitForChild("Constitution", 5)
local intelligence = stats:WaitForChild("Intelligence", 5)
local statPoints = stats:WaitForChild("StatPoints", 5)

-- Wait for derived stats
local maxHP = stats:WaitForChild("MaxHP", 5)
local currentHP = stats:WaitForChild("CurrentHP", 5)
local maxStamina = stats:WaitForChild("MaxStamina", 5)
local currentStamina = stats:WaitForChild("CurrentStamina", 5)
local speed = stats:WaitForChild("Speed", 5)
local defense = stats:WaitForChild("Defense", 5)
local spellRange = stats:WaitForChild("SpellRange", 5)
local wordCount = stats:WaitForChild("WordCount", 5)

if not (strength and dexterity and constitution and intelligence and statPoints) then
	warn("Some stat values not found!")
	return
end

-- ============================================================================
-- STAT ALLOCATION FUNCTIONS (for UI buttons to call)
-- ============================================================================

local function requestAddStrength(points)
	if statPoints.Value >= points then
		statRemote:FireServer("AddStrength", points)
	else
		warn("Not enough stat points!")
	end
end

local function requestAddDexterity(points)
	if statPoints.Value >= points then
		statRemote:FireServer("AddDexterity", points)
	else
		warn("Not enough stat points!")
	end
end

local function requestAddConstitution(points)
	if statPoints.Value >= points then
		statRemote:FireServer("AddConstitution", points)
	else
		warn("Not enough stat points!")
	end
end

local function requestAddIntelligence(points)
	if statPoints.Value >= points then
		statRemote:FireServer("AddIntelligence", points)
	else
		warn("Not enough stat points!")
	end
end

-- ============================================================================
-- SERVER RESPONSE HANDLER
-- ============================================================================

statRemote.OnClientEvent:Connect(function(responseType, message)
	if responseType == "Success" then
		print("✓ " .. message)
		-- Update UI here when you create it
	elseif responseType == "Error" then
		warn("✗ " .. message)
		-- Show error message in UI
	end
end)

-- ============================================================================
-- STAT CHANGE LISTENERS (for UI updates)
-- ============================================================================

-- Primary Stats
strength.Changed:Connect(function(newValue)
	print("Strength: " .. newValue)
	-- Update UI here
end)

dexterity.Changed:Connect(function(newValue)
	print("Dexterity: " .. newValue .. " (Speed: " .. math.floor(speed.Value) .. ")")
	-- Update UI here
end)

constitution.Changed:Connect(function(newValue)
	print("Constitution: " .. newValue .. " (HP: " .. math.floor(maxHP.Value) .. ", Stamina: " .. math.floor(maxStamina.Value) .. ")")
	-- Update UI here
end)

intelligence.Changed:Connect(function(newValue)
	print("Intelligence: " .. newValue .. " (Range: " .. spellRange.Value .. ", Words: " .. wordCount.Value .. ")")
	-- Update UI here
end)

statPoints.Changed:Connect(function(newValue)
	print("Stat Points available: " .. newValue)
	-- Update UI here
end)

-- Derived Stats
currentHP.Changed:Connect(function(newValue)
	-- Update HP bar here
end)

currentStamina.Changed:Connect(function(newValue)
	-- Update Stamina bar here
end)

speed.Changed:Connect(function(newValue)
	-- Update speed display here
end)

print("✓ StatsUI loaded for " .. player.Name)

-- ============================================================================
-- EXPOSE FUNCTIONS FOR UI BUTTONS
-- ============================================================================

_G.AddStrength = requestAddStrength
_G.AddDexterity = requestAddDexterity
_G.AddConstitution = requestAddConstitution
_G.AddIntelligence = requestAddIntelligence