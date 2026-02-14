-- RemoteEventStatsHandler (SECURE)
-- Place this SCRIPT in ServerScriptService
-- Handles remote events for stat allocation with anti-exploit measures

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for StatsManager
local StatsManager
repeat
	task.wait(0.1)
	local statsScript = ServerScriptService:FindFirstChild("PlayerStatsManager")
	if statsScript then
		local success, result = pcall(function()
			return require(statsScript)
		end)
		if success then
			StatsManager = result
		end
	end
until StatsManager

-- Create RemoteEvent if it doesn't exist
local statRemote = ReplicatedStorage:FindFirstChild("StatRemote")
if not statRemote then
	statRemote = Instance.new("RemoteEvent")
	statRemote.Name = "StatRemote"
	statRemote.Parent = ReplicatedStorage
end

-- ============================================================================
-- ANTI-EXPLOIT CONFIGURATION
-- ============================================================================

local RATE_LIMIT = {
	MaxRequestsPerSecond = 10, -- Maximum 10 stat allocations per second
	BanThreshold = 50, -- Ban if they try 50 requests in one second
}

-- Track request rates per player
local requestTracking = {}

-- ============================================================================
-- SECURITY FUNCTIONS
-- ============================================================================

local function checkRateLimit(player)
	local userId = player.UserId
	local currentTime = tick()

	-- Initialize tracking for new players
	if not requestTracking[userId] then
		requestTracking[userId] = {
			requests = {},
			warnings = 0
		}
	end

	local playerData = requestTracking[userId]

	-- Remove requests older than 1 second
	local recentRequests = {}
	for _, timestamp in ipairs(playerData.requests) do
		if currentTime - timestamp < 1 then
			table.insert(recentRequests, timestamp)
		end
	end
	playerData.requests = recentRequests

	-- Check if over limit
	local requestCount = #playerData.requests

	if requestCount >= RATE_LIMIT.BanThreshold then
		-- Kick exploiter
		player:Kick("Anti-exploit: Too many stat allocation requests")
		return false
	elseif requestCount >= RATE_LIMIT.MaxRequestsPerSecond then
		-- Warn and deny
		playerData.warnings = playerData.warnings + 1
		warn(player.Name .. " is sending too many stat requests (" .. requestCount .. "/sec) - Warning #" .. playerData.warnings)
		return false
	end

	-- Add this request to tracking
	table.insert(playerData.requests, currentTime)
	return true
end

local function validateStatAllocation(player, action, points)
	-- Type validation
	if type(action) ~= "string" then
		warn(player.Name .. " sent invalid action type: " .. type(action))
		return false
	end

	if type(points) ~= "number" then
		warn(player.Name .. " sent invalid points type: " .. type(points))
		return false
	end

	-- Range validation
	if points < 1 or points > 100 then
		warn(player.Name .. " tried to allocate invalid amount: " .. points)
		return false
	end

	-- Must be whole number
	if points ~= math.floor(points) then
		warn(player.Name .. " tried to allocate decimal points: " .. points)
		return false
	end

	-- Whitelist valid actions
	local validActions = {
		"AddStrength",
		"AddDexterity",
		"AddConstitution",
		"AddIntelligence"
	}

	local isValidAction = false
	for _, validAction in ipairs(validActions) do
		if action == validAction then
			isValidAction = true
			break
		end
	end

	if not isValidAction then
		warn(player.Name .. " sent invalid action: " .. action)
		return false
	end

	return true
end

-- ============================================================================
-- REMOTE EVENT HANDLER
-- ============================================================================

statRemote.OnServerEvent:Connect(function(player, action, ...)
	-- Rate limit check
	if not checkRateLimit(player) then
		statRemote:FireClient(player, "Error", "Too many requests - please wait")
		return
	end

	local points = ...

	-- Validate input
	if not validateStatAllocation(player, action, points) then
		statRemote:FireClient(player, "Error", "Invalid request")
		return
	end

	-- Get player stats
	local stats = player:FindFirstChild("Stats")
	if not stats then 
		warn(player.Name .. " has no Stats folder")
		return 
	end

	local statPoints = stats:FindFirstChild("StatPoints")
	if not statPoints then
		warn(player.Name .. " has no StatPoints value")
		return
	end

	-- Check if player has enough stat points
	if statPoints.Value < points then
		statRemote:FireClient(player, "Error", "Not enough stat points!")
		return
	end

	-- Allocate stats using the StatsManager
	local success = false
	local statName = ""

	if action == "AddStrength" then
		success = StatsManager.AddStrength(player, points)
		statName = "Strength"

	elseif action == "AddDexterity" then
		success = StatsManager.AddDexterity(player, points)
		statName = "Dexterity"

	elseif action == "AddConstitution" then
		success = StatsManager.AddConstitution(player, points)
		statName = "Constitution"

	elseif action == "AddIntelligence" then
		success = StatsManager.AddIntelligence(player, points)
		statName = "Intelligence"
	end

	-- Send response to client
	if success then
		local currentValue = stats:FindFirstChild(statName)
		if currentValue then
			statRemote:FireClient(player, "Success", statName .. " increased to " .. currentValue.Value)
			print(player.Name .. " allocated " .. points .. " points to " .. statName)
		end
	else
		statRemote:FireClient(player, "Error", "Failed to add " .. statName)
		warn(player.Name .. " failed to allocate to " .. statName)
	end
end)

-- Clean up tracking when player leaves
Players.PlayerRemoving:Connect(function(player)
	requestTracking[player.UserId] = nil
end)

print("✓ RemoteEventStatsHandler (SECURE) loaded!")