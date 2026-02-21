-- StatsSystemLoader
-- Place this as a REGULAR SCRIPT in ServerScriptService
-- This will load and initialize your ModuleScripts

local ServerScriptService = game:GetService("ServerScriptService")

print("========== STATS SYSTEM LOADER ==========")

-- Step 1: Load StatDataStoreManager
print("Loading StatDataStoreManager...")
local dataStoreModule = ServerScriptService:WaitForChild("StatDataStoreManager", 10)
if not dataStoreModule then
	error("StatDataStoreManager not found!")
end

local DataStoreManager = require(dataStoreModule)
print("? StatDataStoreManager loaded")

-- Step 2: Load PlayerStatsManager (this will also connect PlayerAdded)
print("Loading PlayerStatsManager...")
local statsModule = ServerScriptService:WaitForChild("PlayerStatsManager", 10)
if not statsModule then
	error("PlayerStatsManager not found!")
end

local StatsManager = require(statsModule)
print("? PlayerStatsManager loaded")

print("? Stats system ready!")
print("=========================================")
