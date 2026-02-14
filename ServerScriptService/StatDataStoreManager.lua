-- StatDataStoreManager
-- Place this as a ModuleScript in ServerScriptService
-- Handles saving and loading player data

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v2") -- Changed version for new stats

-- Configuration
local AUTO_SAVE_INTERVAL = 300 -- Auto-save every 5 minutes (300 seconds)
local MAX_RETRIES = 3

local DataManager = {}

-- Default data structure
local function getDefaultData()
	return {
		-- Level & XP
		Level = 1,
		XP = 0,
		XPRequired = 100,

		-- Primary Stats (player allocates)
		Strength = 1,
		Dexterity = 1,
		Constitution = 1,
		Intelligence = 1,

		-- Resources
		CurrentHP = 110,  -- Will be recalculated on load
		CurrentStamina = 105,  -- Will be recalculated on load

		-- Equipment Stats (set by equipment system later)
		Defense = 0,
		EquipmentWeight = 0,

		-- Misc
		StatPoints = 0
	}
end

-- Save player data
function DataManager.SaveData(player)
	local stats = player:FindFirstChild("Stats")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not stats or not leaderstats then
		warn("Cannot save data for " .. player.Name .. " - stats not found")
		return false
	end

	-- Collect data from player
	local dataToSave = {
		-- Level & XP
		Level = leaderstats.Level.Value,
		XP = stats.XP.Value,
		XPRequired = stats.XPRequired.Value,

		-- Primary Stats
		Strength = stats.Strength.Value,
		Dexterity = stats.Dexterity.Value,
		Constitution = stats.Constitution.Value,
		Intelligence = stats.Intelligence.Value,

		-- Resources
		CurrentHP = stats.CurrentHP.Value,
		CurrentStamina = stats.CurrentStamina.Value,

		-- Equipment Stats
		Defense = stats.Defense.Value,
		EquipmentWeight = stats.EquipmentWeight.Value,

		-- Misc
		StatPoints = stats.StatPoints.Value
	}

	-- Attempt to save with retries
	local success = false
	local attempts = 0

	while not success and attempts < MAX_RETRIES do
		attempts = attempts + 1

		success = pcall(function()
			PlayerDataStore:SetAsync(player.UserId, dataToSave)
		end)

		if not success then
			warn("Failed to save data for " .. player.Name .. " (Attempt " .. attempts .. "/" .. MAX_RETRIES .. ")")
			task.wait(1)
		end
	end

	if success then
		print("✓ Data saved for " .. player.Name)
		return true
	else
		warn("✗ Failed to save data for " .. player.Name .. " after " .. MAX_RETRIES .. " attempts")
		return false
	end
end

-- Load player data
function DataManager.LoadData(player)
	local success, data
	local attempts = 0

	-- Attempt to load with retries
	while attempts < MAX_RETRIES do
		attempts = attempts + 1

		success, data = pcall(function()
			return PlayerDataStore:GetAsync(player.UserId)
		end)

		if success then
			break
		else
			warn("Failed to load data for " .. player.Name .. " (Attempt " .. attempts .. "/" .. MAX_RETRIES .. ")")
			task.wait(1)
		end
	end

	-- Return data or default
	if success and data then
		print("✓ Data loaded for " .. player.Name)
		return data
	else
		if not success then
			warn("✗ Failed to load data for " .. player.Name .. " - using default data")
		else
			print("ℹ No saved data found for " .. player.Name .. " - using default data")
		end
		return getDefaultData()
	end
end

-- Apply loaded data to player
function DataManager.ApplyData(player, data)
	local stats = player:FindFirstChild("Stats")
	local leaderstats = player:FindFirstChild("leaderstats")

	if not stats or not leaderstats then
		warn("Cannot apply data for " .. player.Name .. " - stats not found")
		return false
	end

	-- Apply data to stats
	leaderstats.Level.Value = data.Level or 1
	stats.XP.Value = data.XP or 0
	stats.XPRequired.Value = data.XPRequired or 100

	-- Primary Stats
	stats.Strength.Value = data.Strength or 1
	stats.Dexterity.Value = data.Dexterity or 1
	stats.Constitution.Value = data.Constitution or 1
	stats.Intelligence.Value = data.Intelligence or 1

	-- Resources (will be recalculated by PlayerStatsManager)
	stats.CurrentHP.Value = data.CurrentHP or 110
	stats.CurrentStamina.Value = data.CurrentStamina or 105

	-- Equipment Stats
	stats.Defense.Value = data.Defense or 0
	stats.EquipmentWeight.Value = data.EquipmentWeight or 0

	-- Misc
	stats.StatPoints.Value = data.StatPoints or 0

	print("✓ Data applied for " .. player.Name)
	return true
end

-- Auto-save loop for all players
local function startAutoSave()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)

		print("Auto-saving all player data...")
		for _, player in pairs(Players:GetPlayers()) do
			DataManager.SaveData(player)
		end
	end
end

-- Start auto-save
task.spawn(startAutoSave)

-- Save data when player leaves
Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " is leaving - saving data...")
	DataManager.SaveData(player)
end)

-- Save all data when server shuts down
game:BindToClose(function()
	print("Server shutting down - saving all player data...")

	for _, player in pairs(Players:GetPlayers()) do
		DataManager.SaveData(player)
	end

	-- Wait a bit to ensure all saves complete
	task.wait(3)
end)

print("✓ StatDataStoreManager loaded!")

return DataManager