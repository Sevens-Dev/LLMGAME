--[[
	ClickerManager.lua (ServerScriptService - Script)
	Server-side logic for the Clicker mini-game.
	Validates clicks, tracks sessions, awards XP, and stores clicker stats.
--]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ClickerConfig = require(ReplicatedStorage:WaitForChild("ClickerConfig"))

-- Load PlayerStatsManager for XP rewards
local PlayerStatsManager
do
	local ok, result = pcall(function()
		return require(ServerScriptService:WaitForChild("PlayerStatsManager", 10))
	end)
	if ok then
		PlayerStatsManager = result
		print("?? ClickerManager: PlayerStatsManager loaded")
	else
		warn("?? ClickerManager: PlayerStatsManager not found – XP won't be awarded")
	end
end

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local ClickerEvents = Instance.new("Folder")
ClickerEvents.Name = "ClickerEvents"
ClickerEvents.Parent = ReplicatedStorage

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = ClickerEvents
	return r
end

local BeginClickerEvent  = makeRemote("BeginClicker")   -- Client ? Server: start session
local TargetClickedEvent = makeRemote("TargetClicked")  -- Client ? Server: player clicked target id
local TargetMissedEvent  = makeRemote("TargetMissed")   -- Client ? Server: target expired un-clicked
local EndClickerEvent    = makeRemote("EndClicker")     -- Client ? Server: player quit
local SessionUpdateEvent = makeRemote("SessionUpdate")  -- Server ? Client: live score update
local GameOverEvent      = makeRemote("GameOver")       -- Server ? Client: session results

-- ============================================================================
-- ANTI-EXPLOIT: RATE LIMITING
-- ============================================================================

local REQUEST_LIMIT = 30   -- max clicks per second before warning
local BAN_LIMIT     = 80   -- max before kick

local rateTracker = {}

local function checkRate(player)
	local uid = player.UserId
	local now = tick()
	rateTracker[uid] = rateTracker[uid] or { times = {}, warnings = 0 }
	local data = rateTracker[uid]

	-- Prune old entries
	local fresh = {}
	for _, t in ipairs(data.times) do
		if now - t < 1 then table.insert(fresh, t) end
	end
	data.times = fresh
	table.insert(data.times, now)

	local count = #data.times
	if count >= BAN_LIMIT then
		player:Kick("Anti-exploit: click rate too high")
		return false
	elseif count >= REQUEST_LIMIT then
		data.warnings += 1
		warn(player.Name .. " – suspicious click rate (" .. count .. "/s) warning #" .. data.warnings)
		return false
	end
	return true
end

-- ============================================================================
-- SESSION STATE
-- ============================================================================

--[[
	Session structure:
	{
		IsActive     : bool,
		Level        : number,
		ClicksThisLevel : number,
		TotalClicks  : number,
		TotalMisses  : number,
		TotalScore   : number,
		TotalXP      : number,
		BestCombo    : number,
		ComboCount   : number,
		LastClickTime: number,
		PendingTargets: { [targetId]: { SpawnTime: number } }
		PerfectRound : bool,  -- no misses this level
	}
--]]

local Sessions = {}

local function newSession()
	return {
		IsActive          = true,
		Level             = 1,
		ClicksThisLevel   = 0,
		TotalClicks       = 0,
		TotalMisses       = 0,
		TotalScore        = 0,
		TotalXP           = 0,
		BestCombo         = 0,
		ComboCount        = 0,
		LastClickTime     = 0,
		PendingTargets    = {},
		PerfectRound      = true,
	}
end

-- ============================================================================
-- CLICKER STATS (per-player persistent folder, lives under player)
-- ============================================================================

local function setupClickerStats(player)
	if player:FindFirstChild("ClickerStats") then return end

	local folder = Instance.new("Folder")
	folder.Name = "ClickerStats"
	folder.Parent = player

	local function intVal(name, default)
		local v = Instance.new("IntValue")
		v.Name = name
		v.Value = default or 0
		v.Parent = folder
	end

	intVal("BestLevel")
	intVal("BestScore")
	intVal("BestCombo")
	intVal("TotalClicks")
	intVal("TotalMisses")
	intVal("TotalSessions")
	intVal("TotalXPEarned")
end

local function updateClickerStats(player, session)
	local cs = player:FindFirstChild("ClickerStats")
	if not cs then return end

	cs.TotalSessions.Value += 1
	cs.TotalClicks.Value   += session.TotalClicks
	cs.TotalMisses.Value   += session.TotalMisses
	cs.TotalXPEarned.Value += session.TotalXP

	if session.Level > cs.BestLevel.Value then
		cs.BestLevel.Value = session.Level
	end
	if session.TotalScore > cs.BestScore.Value then
		cs.BestScore.Value = session.TotalScore
	end
	if session.BestCombo > cs.BestCombo.Value then
		cs.BestCombo.Value = session.BestCombo
	end
end

-- ============================================================================
-- HELPER: send current session state to client
-- ============================================================================

local function fireUpdate(player, session, extra)
	local data = {
		Level       = session.Level,
		ClicksThisLevel = session.ClicksThisLevel,
		ClicksNeeded = ClickerConfig.ClicksToLevelUp,
		TotalScore  = session.TotalScore,
		Combo       = session.ComboCount,
		TargetCount = ClickerConfig.GetTargetCount(session.Level),
		Lifetime    = ClickerConfig.GetTargetLifetime(session.Level),
		TargetSize  = ClickerConfig.GetTargetSize(session.Level),
	}
	if extra then
		for k, v in pairs(extra) do data[k] = v end
	end
	SessionUpdateEvent:FireClient(player, data)
end

-- ============================================================================
-- BEGIN SESSION
-- ============================================================================

BeginClickerEvent.OnServerEvent:Connect(function(player)
	-- Reset any old session
	Sessions[player.UserId] = newSession()
	local session = Sessions[player.UserId]

	local cs = player:FindFirstChild("ClickerStats")
	if cs then cs.TotalSessions.Value += 1 end

	-- Tell client to start (send initial config)
	fireUpdate(player, session, { Started = true })
	print("?? " .. player.Name .. " started a Clicker session")
end)

-- ============================================================================
-- TARGET CLICKED (client says it hit a target)
-- ============================================================================

TargetClickedEvent.OnServerEvent:Connect(function(player, targetId)
	if not checkRate(player) then return end

	local session = Sessions[player.UserId]
	if not session or not session.IsActive then return end

	-- Validate target exists
	if not session.PendingTargets[targetId] then
		-- Possible exploit or race condition – ignore silently
		return
	end
	session.PendingTargets[targetId] = nil

	local now = tick()

	-- Combo logic
	if now - session.LastClickTime <= ClickerConfig.ComboWindow then
		session.ComboCount += 1
	else
		session.ComboCount = 1
	end
	session.LastClickTime = now
	session.BestCombo = math.max(session.BestCombo, session.ComboCount)

	-- Score
	local multiplier = math.min(
		1 + (session.ComboCount - 1) * ClickerConfig.ComboMultiplier,
		ClickerConfig.MaxComboMultiplier
	)
	local baseScore = ClickerConfig.GetScorePerClick(session.Level)
	local score     = math.floor(baseScore * multiplier)
	session.TotalScore  += score
	session.TotalClicks += 1

	-- XP
	local xp = ClickerConfig.GetXPPerClick(session.Level)
	session.TotalXP += xp
	if PlayerStatsManager then
		PlayerStatsManager.GiveDexterityXP(player, xp)
	end

	-- Level up?
	session.ClicksThisLevel += 1
	local leveledUp = false
	local levelUpMsg = nil

	if session.ClicksThisLevel >= ClickerConfig.ClicksToLevelUp then
		-- Perfect round bonus
		if session.PerfectRound then
			local bonus = ClickerConfig.PerfectRoundXPBonus
			session.TotalXP += bonus
			if PlayerStatsManager then
				PlayerStatsManager.GiveDexterityXP(player, bonus)
			end
		end

		session.Level += 1
		session.ClicksThisLevel = 0
		session.PerfectRound    = true
		leveledUp  = true
		levelUpMsg = ClickerConfig.GetLevelUpMessage()
		print("?? " .. player.Name .. " reached Clicker level " .. session.Level)
	end

	-- Tell client
	fireUpdate(player, session, {
		Hit         = true,
		ScoreGained = score,
		XPGained    = xp,
		Combo       = session.ComboCount,
		Multiplier  = multiplier,
		LeveledUp   = leveledUp,
		LevelUpMsg  = levelUpMsg,
		TargetId    = targetId,
	})
end)



-- ============================================================================
-- REGISTER TARGET (server-side tracking for anti-exploit)
-- Called internally – the client also calls this so server can validate later.
-- For simplicity we trust the client's target IDs (GUID generated on client).
-- A stricter implementation would generate IDs server-side.
-- ============================================================================

-- We accept a RegisterTarget remote so server tracks active target IDs
local RegisterTargetEvent = makeRemote("RegisterTarget")

RegisterTargetEvent.OnServerEvent:Connect(function(player, targetId)
	local session = Sessions[player.UserId]
	if not session or not session.IsActive then return end

	session.PendingTargets[targetId] = { SpawnTime = tick() }
end)

-- ============================================================================
-- END SESSION (player quits or game over)
-- ============================================================================

local function endSession(player)
	local session = Sessions[player.UserId]
	if not session then return end

	session.IsActive = false
	updateClickerStats(player, session)

	local cs = player:FindFirstChild("ClickerStats")

	GameOverEvent:FireClient(player, {
		Level       = session.Level,
		TotalScore  = session.TotalScore,
		TotalClicks = session.TotalClicks,
		TotalMisses = session.TotalMisses,
		TotalXP     = session.TotalXP,
		BestCombo   = session.BestCombo,
		BestScore   = cs and cs.BestScore.Value or 0,
		BestLevel   = cs and cs.BestLevel.Value or 0,
	})

	Sessions[player.UserId] = nil
	print("?? " .. player.Name .. " ended Clicker session | Score: " .. session.TotalScore .. " | Level: " .. session.Level)
end

EndClickerEvent.OnServerEvent:Connect(endSession)

-- ============================================================================
-- TARGET MISSED (client says a target expired without being clicked)
-- ============================================================================

TargetMissedEvent.OnServerEvent:Connect(function(player, targetId)
	if not checkRate(player) then return end

	local session = Sessions[player.UserId]
	if not session or not session.IsActive then return end

	session.PendingTargets[targetId] = nil
	session.TotalMisses += 1
	session.PerfectRound = false
	session.ComboCount   = 0  -- Break combo on miss

	-- END SESSION ON MISS
	endSession(player)
end)

-- ============================================================================
-- PLAYER MANAGEMENT
-- ============================================================================

Players.PlayerAdded:Connect(function(player)
	setupClickerStats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	if Sessions[player.UserId] then
		endSession(player)
	end
	rateTracker[player.UserId] = nil
end)

-- Set up for players already in game
for _, player in ipairs(Players:GetPlayers()) do
	setupClickerStats(player)
end

print("?? ClickerManager loaded and active!")
