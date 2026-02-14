--[[
	MeditationManager.lua (ServerScriptService)
	Server-side logic for Meditation & Martial Arts Training
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeditationConfig = require(ReplicatedStorage:WaitForChild("MeditationConfig"))

-- Load PlayerStatsManager for EXP rewards
local PlayerStatsManager
local success, result = pcall(function()
	return require(game.ServerScriptService:WaitForChild("PlayerStatsManager"))
end)
if success then
	PlayerStatsManager = result
	print("🧘 PlayerStatsManager loaded for meditation EXP rewards")
else
	warn("🧘 PlayerStatsManager not found - meditation won't award EXP")
end

-- Create RemoteEvents
local RemoteEvents = Instance.new("Folder")
RemoteEvents.Name = "MeditationEvents"
RemoteEvents.Parent = ReplicatedStorage

local BeginMeditationEvent = Instance.new("RemoteEvent")
BeginMeditationEvent.Name = "BeginMeditation"
BeginMeditationEvent.Parent = RemoteEvents

local SubmitFlowEvent = Instance.new("RemoteEvent")
SubmitFlowEvent.Name = "SubmitFlow"
SubmitFlowEvent.Parent = RemoteEvents

local EnlightenmentEvent = Instance.new("RemoteEvent")
EnlightenmentEvent.Name = "Enlightenment"
EnlightenmentEvent.Parent = RemoteEvents

-- Player meditation sessions
local MeditationSessions = {}

-- Setup meditation stats (NOT in leaderstats to avoid conflicts)
local function setupMeditationStats(player: Player)
	local meditationStats = Instance.new("Folder")
	meditationStats.Name = "MeditationStats"
	meditationStats.Parent = player

	local highestLevel = Instance.new("IntValue")
	highestLevel.Name = "HighestLevel"
	highestLevel.Value = 0
	highestLevel.Parent = meditationStats

	local totalSessions = Instance.new("IntValue")
	totalSessions.Name = "TotalSessions"
	totalSessions.Value = 0
	totalSessions.Parent = meditationStats

	local perfectFlows = Instance.new("IntValue")
	perfectFlows.Name = "PerfectFlows"
	perfectFlows.Value = 0
	perfectFlows.Parent = meditationStats

	local totalEnlightenment = Instance.new("IntValue")
	totalEnlightenment.Name = "TotalEnlightenment"
	totalEnlightenment.Value = 0
	totalEnlightenment.Parent = meditationStats
end

-- Initialize meditation session
local function initializeSession(player: Player)
	MeditationSessions[player.UserId] = {
		CurrentLevel = 1,
		TotalEnlightenment = 0,
		Harmony = 0, -- Combo counter
		Chi = 0,
		HighestLevel = 0,
		CurrentPath = {},
		IsMeditating = false,
		Mistakes = 0,
		StartTime = 0,
		PerfectFlows = 0
	}
end

-- Generate chi flow path
local function generateChiPath(length: number, gridSize: number): {number}
	local path = {}
	local maxTileIndex = gridSize * gridSize
	local usedTiles = {}

	-- First tile is random
	local firstTile = math.random(1, maxTileIndex)
	table.insert(path, firstTile)
	usedTiles[firstTile] = true

	-- Subsequent tiles prefer adjacent ones (more natural flow)
	for i = 2, length do
		local lastTile = path[#path]
		local adjacentTiles = getAdjacentTiles(lastTile, gridSize)

		-- Try to use an adjacent tile that hasn't been used
		local nextTile
		local availableAdjacent = {}

		for _, adjTile in ipairs(adjacentTiles) do
			if not usedTiles[adjTile] then
				table.insert(availableAdjacent, adjTile)
			end
		end

		if #availableAdjacent > 0 then
			-- Use adjacent tile for natural flow
			nextTile = availableAdjacent[math.random(1, #availableAdjacent)]
		else
			-- All adjacent used, pick any unused tile
			repeat
				nextTile = math.random(1, maxTileIndex)
			until not usedTiles[nextTile]
		end

		table.insert(path, nextTile)
		usedTiles[nextTile] = true
	end

	return path
end

-- Get adjacent tiles (for natural chi flow)
function getAdjacentTiles(tileIndex: number, gridSize: number): {number}
	local row = math.floor((tileIndex - 1) / gridSize)
	local col = (tileIndex - 1) % gridSize
	local adjacent = {}

	-- Cardinal directions
	local directions = {
		{-1, 0}, {1, 0}, {0, -1}, {0, 1}, -- Up, Down, Left, Right
		{-1, -1}, {-1, 1}, {1, -1}, {1, 1} -- Diagonals
	}

	for _, dir in ipairs(directions) do
		local newRow = row + dir[1]
		local newCol = col + dir[2]

		if newRow >= 0 and newRow < gridSize and newCol >= 0 and newCol < gridSize then
			local newIndex = newRow * gridSize + newCol + 1
			table.insert(adjacent, newIndex)
		end
	end

	return adjacent
end

-- Handle meditation begin
BeginMeditationEvent.OnServerEvent:Connect(function(player: Player)
	local session = MeditationSessions[player.UserId]
	if not session then
		initializeSession(player)
		session = MeditationSessions[player.UserId]
	end

	-- Reset for new session
	session.CurrentLevel = 1
	session.TotalEnlightenment = 0
	session.Harmony = 0
	session.Chi = 0
	session.Mistakes = 0
	session.IsMeditating = true
	session.PerfectFlows = 0
	session.StartTime = os.time()

	-- Increment total sessions
	if player:FindFirstChild("MeditationStats") then
		player.MeditationStats.TotalSessions.Value += 1
	end

	-- Get difficulty for level 1
	local difficulty = MeditationConfig.GetDifficultyForLevel(1)

	-- Generate chi path for level 1
	session.CurrentPath = generateChiPath(difficulty.PathLength, MeditationConfig.GridSize)

	-- Send to client
	BeginMeditationEvent:FireClient(player, {
		Level = 1,
		ChiPath = session.CurrentPath,
		Difficulty = difficulty,
		Wisdom = MeditationConfig.GetWisdom("preparation")
	})
end)

-- Handle flow submission
SubmitFlowEvent.OnServerEvent:Connect(function(player: Player, playerPath: {number})
	local session = MeditationSessions[player.UserId]
	if not session or not session.IsMeditating then
		return
	end

	-- Validate the chi flow
	local isHarmony = true
	local mistakes = 0

	if #playerPath ~= #session.CurrentPath then
		isHarmony = false
		mistakes = math.abs(#playerPath - #session.CurrentPath)
	else
		for i, tileIndex in ipairs(playerPath) do
			if tileIndex ~= session.CurrentPath[i] then
				isHarmony = false
				mistakes += 1
			end
		end
	end

	session.Mistakes = mistakes

	-- Check for mindfulness bonus (deliberate, unhurried play)
	local sessionDuration = os.time() - session.StartTime
	local expectedMinTime = #session.CurrentPath * 2 -- Rough estimate
	local isMindful = sessionDuration >= expectedMinTime

	if isHarmony then
		-- Harmony achieved!
		session.Harmony += 1
		session.Chi = math.min(session.Chi + MeditationConfig.ChiPerLevel, MeditationConfig.MaxChi)

		if mistakes == 0 then
			session.PerfectFlows += 1
			if player:FindFirstChild("MeditationStats") then
				player.MeditationStats.PerfectFlows.Value += 1
			end
		end

		-- Calculate enlightenment (EXP reward)
		local enlightenment = MeditationConfig.CalculateEnlightenment(
			session.CurrentLevel,
			mistakes,
			session.Harmony,
			isMindful
		)

		session.TotalEnlightenment += enlightenment
		session.CurrentLevel += 1

		-- Update highest level
		if session.CurrentLevel > session.HighestLevel then
			session.HighestLevel = session.CurrentLevel
			if player:FindFirstChild("MeditationStats") then
				player.MeditationStats.HighestLevel.Value = session.HighestLevel
			end
		end

		-- Store total enlightenment
		if player:FindFirstChild("MeditationStats") then
			player.MeditationStats.TotalEnlightenment.Value = session.TotalEnlightenment
		end

		-- Award EXP to player's main stats system
		-- POLYNOMIAL XP SCALING - Higher levels give much more EXP!

		-- Choose your formula (comment/uncomment the one you want):

		-- OPTION 1: Quadratic (Level^2) - Moderate scaling
		local expAmount = math.floor(enlightenment * (session.CurrentLevel ^ 2) / 100)

		-- OPTION 2: Cubic (Level^3) - Aggressive scaling
		-- local expAmount = math.floor(enlightenment * (session.CurrentLevel ^ 3) / 1000)

		-- OPTION 3: Square root polynomial - Gentle curve
		-- local expAmount = math.floor(enlightenment * math.sqrt(session.CurrentLevel) / 5)

		-- OPTION 4: Custom polynomial (aLevel^2 + bLevel + c)
		-- local expAmount = math.floor((session.CurrentLevel ^ 2) * 5 + session.CurrentLevel * 10 + enlightenment / 10)

		-- OPTION 5: Exponential (not polynomial but very rewarding)
		-- local expAmount = math.floor(enlightenment * (1.5 ^ session.CurrentLevel) / 10)

		if PlayerStatsManager and PlayerStatsManager.GiveXP then
			PlayerStatsManager.GiveXP(player, expAmount)
			print("🧘 " .. player.Name .. " earned " .. expAmount .. " EXP from meditation Level " .. session.CurrentLevel .. " (Enlightenment: " .. enlightenment .. ")")
		else
			warn("🧘 Failed to award EXP - PlayerStatsManager not available")
		end

		-- Get difficulty for next level
		local difficulty = MeditationConfig.GetDifficultyForLevel(session.CurrentLevel)

		-- Generate next path
		session.CurrentPath = generateChiPath(difficulty.PathLength, MeditationConfig.GridSize)
		session.StartTime = os.time()

		-- Send success to client
		EnlightenmentEvent:FireClient(player, {
			Success = true,
			Level = session.CurrentLevel,
			Enlightenment = enlightenment,
			TotalEnlightenment = session.TotalEnlightenment,
			Harmony = session.Harmony,
			Chi = session.Chi,
			Mindful = isMindful,
			NextPath = session.CurrentPath,
			NextDifficulty = difficulty,
			Wisdom = MeditationConfig.GetWisdom("success"),
			PerfectFlow = mistakes == 0
		})
	else
		-- Flow disrupted
		session.IsMeditating = false

		EnlightenmentEvent:FireClient(player, {
			Success = false,
			FinalLevel = session.CurrentLevel,
			FinalEnlightenment = session.TotalEnlightenment,
			HighestLevel = session.HighestLevel,
			PerfectFlows = session.PerfectFlows,
			Wisdom = MeditationConfig.GetWisdom("failure")
		})
	end
end)

-- Player management
Players.PlayerAdded:Connect(function(player)
	setupMeditationStats(player)
	initializeSession(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MeditationSessions[player.UserId] = nil
end)

print("🧘 Meditation & Martial Arts Training - Server Active")