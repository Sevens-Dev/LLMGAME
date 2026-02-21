-- RemoteEventStatsHandler
-- Place this SCRIPT in ServerScriptService
-- Stat allocation is now admin-only via chat commands (AdminCommands.lua)
-- This handler exists purely to send back a clear message if a client somehow fires it

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create StatRemote if it doesn't exist (client scripts wait for it)
local statRemote = ReplicatedStorage:FindFirstChild("StatRemote")
if not statRemote then
	statRemote = Instance.new("RemoteEvent")
	statRemote.Name = "StatRemote"
	statRemote.Parent = ReplicatedStorage
end

-- ============================================================================
-- RATE LIMIT TRACKING (kept as anti-exploit measure)
-- ============================================================================

local requestTracking = {}

local function checkRateLimit(player)
	local userId = player.UserId
	local currentTime = tick()

	if not requestTracking[userId] then
		requestTracking[userId] = { requests = {}, warnings = 0 }
	end

	local playerData = requestTracking[userId]

	-- Clear requests older than 1 second
	local recentRequests = {}
	for _, timestamp in ipairs(playerData.requests) do
		if currentTime - timestamp < 1 then
			table.insert(recentRequests, timestamp)
		end
	end
	playerData.requests = recentRequests

	local requestCount = #playerData.requests

	-- Kick if hammering the remote (likely an exploiter probing)
	if requestCount >= 20 then
		player:Kick("Anti-exploit: Stat remote abuse detected")
		return false
	end

	table.insert(playerData.requests, currentTime)
	return true
end

-- ============================================================================
-- HANDLER - Rejects all requests
-- Players raise stats via minigames, not this remote
-- Admins use chat commands (!addstr, !adddex, etc.)
-- ============================================================================

statRemote.OnServerEvent:Connect(function(player, action)
	if not checkRateLimit(player) then return end

	-- Log attempt for debugging
	warn("[StatRemote] " .. player.Name .. " fired StatRemote with action: " .. tostring(action) .. "   rejected (use minigames to train stats)")

	-- Inform the client
	statRemote:FireClient(player, "Info", "Stats are raised by training minigames, not manual allocation.")
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(function(player)
	requestTracking[player.UserId] = nil
end)

print("? RemoteEventStatsHandler loaded   stat allocation restricted to admin chat commands")
print("  Players raise stats through minigame training")
