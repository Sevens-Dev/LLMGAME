--[[
	MeditationManager.lua (ServerScriptService)
	Server-side logic for Meditation & Martial Arts Training
	Awards Intelligence XP via the stat XP system
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeditationConfig = require(ReplicatedStorage:WaitForChild("MeditationConfig"))

-- Load PlayerStatsManager for Intelligence XP rewards
local PlayerStatsManager
local success, result = pcall(function()
	return require(game.ServerScriptService:WaitForChild("PlayerStatsManager"))
end)
if success then
	PlayerStatsManager = result
	print("?? PlayerStatsManager loaded — meditation will award Intelligence XP")
else
	warn("?? PlayerStatsManager not found — meditation won't award XP")
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

-- Setup meditation stats
local function setupMeditationStats(player)
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

local function initializeSession(player)
	MeditationSessions[player.UserId] = {
		CurrentLevel = 1,
		TotalEnlightenment = 0,
		Harmony = 0,
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
local function generateChiPath(length, gridSize)
	local path = {}
	local maxTileIndex = gridSize * gridSize
	local usedTiles = {}

	local firstTile = math.random(1, maxTileIndex)
	table.insert(path, firstTile)
	usedTiles[firstTile] = true

	for i = 2, length do
		local lastTile = path[#path]
		local adjacentTiles = getAdjacentTiles(lastTile, gridSize)

		local availableAdjacent = {}
		for _, adjTile in ipairs(adjacentTiles) do
			if not usedTiles[adjTile] then
				table.insert(availableAdjacent, adjTile)
			end
		end

		local nextTile
		if #availableAdjacent > 0 then
			nextTile = availableAdjacent[math.random(1, #availableAdjacent)]
		else
			repeat
				nextTile = math.random(1, maxTileIndex)
			until not usedTiles[nextTile]
		end

		table.insert(path, nextTile)
		usedTiles[nextTile] = true
	end

	return path
end

function getAdjacentTiles(tileIndex, gridSize)
	local row = math.floor((tileIndex - 1) / gridSize)
	local col = (tileIndex - 1) % gridSize
	local adjacent = {}

	local directions = {
		{-1, 0}, {1, 0}, {0, -1}, {0, 1},
		{-1, -1}, {-1, 1}, {1, -1}, {1, 1}
	}

	for _, dir in ipairs(directions) do
		local newRow = row + dir[1]
		local newCol = col + dir[2]
		if newRow >= 0 and newRow < gridSize and newCol >= 0 and newCol < gridSize then
			table.insert(adjacent, newRow * gridSize + newCol + 1)
		end
	end

	return adjacent
end

-- Handle meditation begin
BeginMeditationEvent.OnServerEvent:Connect(function(player)
	local session = MeditationSessions[player.UserId]
	if not session then
		initializeSession(player)
		session = MeditationSessions[player.UserId]
	end

	session.CurrentLevel = 1
	session.TotalEnlightenment = 0
	session.Harmony = 0
	session.Chi = 0
	session.Mistakes = 0
	session.IsMeditating = true
	session.PerfectFlows = 0
	session.StartTime = os.time()

	if player:FindFirstChild("MeditationStats") then
		player.MeditationStats.TotalSessions.Value += 1
	end

	local difficulty = MeditationConfig.GetDifficultyForLevel(1)
	session.CurrentPath = generateChiPath(difficulty.PathLength, MeditationConfig.GridSize)

	BeginMeditationEvent:FireClient(player, {
		Level = 1,
		ChiPath = session.CurrentPath,
		Difficulty = difficulty,
		Wisdom = MeditationConfig.GetWisdom("preparation")
	})
end)

-- Handle flow submission
SubmitFlowEvent.OnServerEvent:Connect(function(player, playerPath)
	local session = MeditationSessions[player.UserId]
	if not session or not session.IsMeditating then return end

	-- Validate chi flow
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

	local sessionDuration = os.time() - session.StartTime
	local expectedMinTime = #session.CurrentPath * 2
	local isMindful = sessionDuration >= expectedMinTime

	if isHarmony then
		session.Harmony += 1
		session.Chi = math.min(session.Chi + MeditationConfig.ChiPerLevel, MeditationConfig.MaxChi)

		if mistakes == 0 then
			session.PerfectFlows += 1
			if player:FindFirstChild("MeditationStats") then
				player.MeditationStats.PerfectFlows.Value += 1
			end
		end

		local enlightenment = MeditationConfig.CalculateEnlightenment(
			session.CurrentLevel,
			mistakes,
			session.Harmony,
			isMindful
		)

		session.TotalEnlightenment += enlightenment
		session.CurrentLevel += 1

		if session.CurrentLevel > session.HighestLevel then
			session.HighestLevel = session.CurrentLevel
			if player:FindFirstChild("MeditationStats") then
				player.MeditationStats.HighestLevel.Value = session.HighestLevel
			end
		end

		if player:FindFirstChild("MeditationStats") then
			player.MeditationStats.TotalEnlightenment.Value = session.TotalEnlightenment
		end

		-- ============================================================
		-- AWARD INTELLIGENCE XP (not combat XP)
		-- Meditation trains the mind — feeds the Intelligence stat pool
		-- Formula: polynomial scaling so deeper meditation is more rewarding
		-- ============================================================
		local intXPAmount = math.floor(enlightenment * (session.CurrentLevel ^ 2) / 100)

		if PlayerStatsManager and PlayerStatsManager.GiveIntelligenceXP then
			local rankedUp = PlayerStatsManager.GiveIntelligenceXP(player, intXPAmount)
			print("?? " .. player.Name .. " earned " .. intXPAmount .. " Intelligence XP from meditation Level " .. session.CurrentLevel)
			if rankedUp then
				print("?? " .. player.Name .. "'s Intelligence ranked up!")
			end
		else
			warn("?? Failed to award Intelligence XP — PlayerStatsManager not available")
		end

		local difficulty = MeditationConfig.GetDifficultyForLevel(session.CurrentLevel)
		session.CurrentPath = generateChiPath(difficulty.PathLength, MeditationConfig.GridSize)
		session.StartTime = os.time()

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

Players.PlayerAdded:Connect(function(player)
	setupMeditationStats(player)
	initializeSession(player)
end)

Players.PlayerRemoving:Connect(function(player)
	MeditationSessions[player.UserId] = nil
end)

print("?? MeditationManager loaded — awards Intelligence XP on success")
