-- StatDataStoreManager
-- Place this as a ModuleScript in ServerScriptService
-- Handles saving and loading player data including StatProgress XP pools

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v3") -- Bumped version for StatProgress addition

local AUTO_SAVE_INTERVAL = 300
local MAX_RETRIES = 3

local DataManager = {}

-- Default data structure
local function getDefaultData()
	return {
		-- Level & Combat XP
		Level = 1,
		XP = 0,
		XPRequired = 100,

		-- Primary Stats (raw values, raised by minigame XP)
		Strength = 1,
		Dexterity = 1,
		Constitution = 1,
		Intelligence = 1,

		-- Resources
		CurrentHP = 110,
		CurrentStamina = 105,

		-- Equipment
		Defense = 0,
		EquipmentWeight = 0,

		-- Admin stat points
		StatPoints = 0,

		-- Stat XP Progress (individual minigame XP pools)
		-- Each stat tracks its own XP and XP requirement separately
		StrengthXP = 0,
		StrengthXPRequired = 50,
		DexterityXP = 0,
		DexterityXPRequired = 50,
		ConstitutionXP = 0,
		ConstitutionXPRequired = 50,
		IntelligenceXP = 0,
		IntelligenceXPRequired = 50,
	}
end

-- Save player data
function DataManager.SaveData(player)
	local stats = player:FindFirstChild("Stats")
	local leaderstats = player:FindFirstChild("leaderstats")
	local statProgress = player:FindFirstChild("StatProgress")

	if not stats or not leaderstats then
		warn("Cannot save data for " .. player.Name .. " - stats not found")
		return false
	end

	local dataToSave = {
		-- Level & Combat XP
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

		-- Equipment
		Defense = stats.Defense.Value,
		EquipmentWeight = stats.EquipmentWeight.Value,

		-- Admin stat points
		StatPoints = stats.StatPoints.Value,
	}

	-- Save StatProgress if it exists
	if statProgress then
		local statNames = {"Strength", "Dexterity", "Constitution", "Intelligence"}
		for _, statName in ipairs(statNames) do
			local xp = statProgress:FindFirstChild(statName .. "XP")
			local xpReq = statProgress:FindFirstChild(statName .. "XPRequired")
			if xp and xpReq then
				dataToSave[statName .. "XP"] = xp.Value
				dataToSave[statName .. "XPRequired"] = xpReq.Value
			end
		end
	end

	-- Attempt save with retries
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
		print("? Data saved for " .. player.Name)
		return true
	else
		warn("? Failed to save data for " .. player.Name .. " after " .. MAX_RETRIES .. " attempts")
		return false
	end
end

-- Load player data
function DataManager.LoadData(player)
	local success, data
	local attempts = 0

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

	if success and data then
		print("? Data loaded for " .. player.Name)
		-- Fill in any missing keys from default (handles old save data missing StatProgress)
		local defaults = getDefaultData()
		for key, defaultValue in pairs(defaults) do
			if data[key] == nil then
				data[key] = defaultValue
			end
		end
		return data
	else
		if not success then
			warn("? Failed to load data for " .. player.Name .. " - using default data")
		else
			print("? No saved data found for " .. player.Name .. " - using default data")
		end
		return getDefaultData()
	end
end

-- Apply loaded data to player
function DataManager.ApplyData(player, data)
	local stats = player:FindFirstChild("Stats")
	local leaderstats = player:FindFirstChild("leaderstats")
	local statProgress = player:FindFirstChild("StatProgress")

	if not stats or not leaderstats then
		warn("Cannot apply data for " .. player.Name .. " - stats not found")
		return false
	end

	-- Core stats
	leaderstats.Level.Value = data.Level or 1
	stats.XP.Value = data.XP or 0
	stats.XPRequired.Value = data.XPRequired or 100

	-- Primary stats
	stats.Strength.Value = data.Strength or 1
	stats.Dexterity.Value = data.Dexterity or 1
	stats.Constitution.Value = data.Constitution or 1
	stats.Intelligence.Value = data.Intelligence or 1

	-- Resources
	stats.CurrentHP.Value = data.CurrentHP or 110
	stats.CurrentStamina.Value = data.CurrentStamina or 105

	-- Equipment
	stats.Defense.Value = data.Defense or 0
	stats.EquipmentWeight.Value = data.EquipmentWeight or 0

	-- Admin stat points
	stats.StatPoints.Value = data.StatPoints or 0

	-- Apply StatProgress XP pools
	if statProgress then
		local statNames = {"Strength", "Dexterity", "Constitution", "Intelligence"}
		for _, statName in ipairs(statNames) do
			local xp = statProgress:FindFirstChild(statName .. "XP")
			local xpReq = statProgress:FindFirstChild(statName .. "XPRequired")
			if xp then
				xp.Value = data[statName .. "XP"] or 0
			end
			if xpReq then
				xpReq.Value = data[statName .. "XPRequired"] or 50
			end
		end
	end

	print("? Data applied for " .. player.Name)
	return true
end

-- Auto-save loop
local function startAutoSave()
	while true do
		task.wait(AUTO_SAVE_INTERVAL)
		print("Auto-saving all player data...")
		for _, player in pairs(Players:GetPlayers()) do
			DataManager.SaveData(player)
		end
	end
end

task.spawn(startAutoSave)

Players.PlayerRemoving:Connect(function(player)
	print(player.Name .. " is leaving - saving data...")
	DataManager.SaveData(player)
end)

game:BindToClose(function()
	print("Server shutting down - saving all player data...")
	for _, player in pairs(Players:GetPlayers()) do
		DataManager.SaveData(player)
	end
	task.wait(3)
end)

print("? StatDataStoreManager loaded! (v3 - includes StatProgress XP persistence)")

return DataManager
