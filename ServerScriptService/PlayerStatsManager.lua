-- PlayerStatsManager
-- Place this as a ModuleScript in ServerScriptService
-- Handles player leveling, stat systems, and stat-specific XP progression

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for and require DataStoreManager
local DataStoreManager
repeat
	task.wait(0.1)
	local dataStoreScript = ServerScriptService:FindFirstChild("StatDataStoreManager")
	if dataStoreScript then
		local success, result = pcall(function()
			return require(dataStoreScript)
		end)
		if success then
			DataStoreManager = result
			print("? Successfully loaded StatDataStoreManager")
		end
	end
until DataStoreManager

-- ============================================================================
-- CONFIGURATION - EDIT THESE VALUES TO BALANCE THE GAME
-- ============================================================================
local CONFIG = {
	-- Leveling (Character Level - earned from combat)
	StartingLevel = 1,
	StartingXP = 0,
	BaseXPRequired = 100,
	XPScaling = 1.5,			-- XP requirement multiplier per level

	-- Primary Stats (starting values)
	StartingStrength = 1,
	StartingDexterity = 1,
	StartingConstitution = 1,
	StartingIntelligence = 1,

	-- Character Level Bonus
	-- Each character level adds this to every primary stat before derived calculation
	-- e.g. Level 10 = +5 effective bonus to all stats
	LevelStatBonus = 0.5,

	-- Stat Conversions (applied to effective stat = raw + level bonus)
	StrengthToDamage = 2,
	DexterityToSpeed = 0.5,
	ConstitutionToHP = 10,
	ConstitutionToStamina = 5,
	IntelligenceToSpellRange = 1,
	IntelligenceToWordCount = 0.5,

	-- Base Values
	BasePhysicalDamage = 5,
	BaseHP = 100,
	BaseStamina = 100,
	BaseSpeed = 16,
	BaseSpellRange = 50,
	BaseWordCount = 10,

	-- Caps
	MaxSpeed = 80,

	-- Equipment (defaults)
	DefaultDefense = 0,
	DefaultEquipmentWeight = 0,

	-- Stat XP Scaling
	-- Each stat has its own XP pool. Softer curve than character leveling.
	BaseStatXPRequired = 50,		-- XP needed for first stat rank-up
	StatXPScaling = 1.25,			-- Multiplier per rank (softer than 1.5 character scaling)
}

-- ============================================================================
-- STAT CREATION
-- ============================================================================

local function setupPlayerStats(player)
	-- Leaderstats folder (shows on leaderboard)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = CONFIG.StartingLevel
	levelValue.Parent = leaderstats

	-- Stats folder (core stat values)
	local stats = Instance.new("Folder")
	stats.Name = "Stats"
	stats.Parent = player

	-- Character XP System (fed by combat)
	local xpValue = Instance.new("IntValue")
	xpValue.Name = "XP"
	xpValue.Value = CONFIG.StartingXP
	xpValue.Parent = stats

	local xpRequiredValue = Instance.new("IntValue")
	xpRequiredValue.Name = "XPRequired"
	xpRequiredValue.Value = CONFIG.BaseXPRequired
	xpRequiredValue.Parent = stats

	-- Primary Stats (raw values, incremented by stat XP system)
	local strengthValue = Instance.new("IntValue")
	strengthValue.Name = "Strength"
	strengthValue.Value = CONFIG.StartingStrength
	strengthValue.Parent = stats

	local dexterityValue = Instance.new("IntValue")
	dexterityValue.Name = "Dexterity"
	dexterityValue.Value = CONFIG.StartingDexterity
	dexterityValue.Parent = stats

	local constitutionValue = Instance.new("IntValue")
	constitutionValue.Name = "Constitution"
	constitutionValue.Value = CONFIG.StartingConstitution
	constitutionValue.Parent = stats

	local intelligenceValue = Instance.new("IntValue")
	intelligenceValue.Name = "Intelligence"
	intelligenceValue.Value = CONFIG.StartingIntelligence
	intelligenceValue.Parent = stats

	-- Derived Stats (calculated from effective stats)
	local maxHPValue = Instance.new("NumberValue")
	maxHPValue.Name = "MaxHP"
	maxHPValue.Value = CONFIG.BaseHP + (CONFIG.StartingConstitution * CONFIG.ConstitutionToHP)
	maxHPValue.Parent = stats

	local currentHPValue = Instance.new("NumberValue")
	currentHPValue.Name = "CurrentHP"
	currentHPValue.Value = maxHPValue.Value
	currentHPValue.Parent = stats

	local maxStaminaValue = Instance.new("NumberValue")
	maxStaminaValue.Name = "MaxStamina"
	maxStaminaValue.Value = CONFIG.BaseStamina + (CONFIG.StartingConstitution * CONFIG.ConstitutionToStamina)
	maxStaminaValue.Parent = stats

	local currentStaminaValue = Instance.new("NumberValue")
	currentStaminaValue.Name = "CurrentStamina"
	currentStaminaValue.Value = maxStaminaValue.Value
	currentStaminaValue.Parent = stats

	local speedValue = Instance.new("NumberValue")
	speedValue.Name = "Speed"
	speedValue.Value = CONFIG.BaseSpeed + (CONFIG.StartingDexterity * CONFIG.DexterityToSpeed)
	speedValue.Parent = stats

	-- Equipment Stats
	local defenseValue = Instance.new("NumberValue")
	defenseValue.Name = "Defense"
	defenseValue.Value = CONFIG.DefaultDefense
	defenseValue.Parent = stats

	local equipmentWeightValue = Instance.new("NumberValue")
	equipmentWeightValue.Name = "EquipmentWeight"
	equipmentWeightValue.Value = CONFIG.DefaultEquipmentWeight
	equipmentWeightValue.Parent = stats

	-- Spell Stats
	local spellRangeValue = Instance.new("NumberValue")
	spellRangeValue.Name = "SpellRange"
	spellRangeValue.Value = CONFIG.BaseSpellRange + (CONFIG.StartingIntelligence * CONFIG.IntelligenceToSpellRange)
	spellRangeValue.Parent = stats

	local wordCountValue = Instance.new("IntValue")
	wordCountValue.Name = "WordCount"
	wordCountValue.Value = CONFIG.BaseWordCount + math.floor(CONFIG.StartingIntelligence * CONFIG.IntelligenceToWordCount)
	wordCountValue.Parent = stats

	-- StatPoints kept for admin use only
	local statPointsValue = Instance.new("IntValue")
	statPointsValue.Name = "StatPoints"
	statPointsValue.Value = 0
	statPointsValue.Parent = stats

	-- ============================================================================
	-- STAT PROGRESS FOLDER
	-- Tracks individual stat XP pools, separate from the core Stats folder
	-- Each stat has: XP (current), XPRequired (to next rank-up)
	-- ============================================================================
	local statProgress = Instance.new("Folder")
	statProgress.Name = "StatProgress"
	statProgress.Parent = player

	local statNames = {"Strength", "Dexterity", "Constitution", "Intelligence"}
	for _, statName in ipairs(statNames) do
		local xp = Instance.new("IntValue")
		xp.Name = statName .. "XP"
		xp.Value = 0
		xp.Parent = statProgress

		local xpReq = Instance.new("IntValue")
		xpReq.Name = statName .. "XPRequired"
		xpReq.Value = CONFIG.BaseStatXPRequired
		xpReq.Parent = statProgress
	end

	print("? " .. player.Name .. " stats and progress initialized!")
end

-- ============================================================================
-- EFFECTIVE STAT CALCULATION
-- Applies the character level bonus to raw stat values
-- EffectiveStat = RawStat + (CharacterLevel * LevelStatBonus)
-- ============================================================================

local function getEffectiveStat(player, statName)
	local stats = player:FindFirstChild("Stats")
	local leaderstats = player:FindFirstChild("leaderstats")
	if not stats or not leaderstats then return 0 end

	local rawStat = stats:FindFirstChild(statName)
	if not rawStat then return 0 end

	local levelBonus = leaderstats.Level.Value * CONFIG.LevelStatBonus
	return rawStat.Value + levelBonus
end

-- ============================================================================
-- DERIVED STAT CALCULATIONS (now use effective stats with level bonus)
-- ============================================================================

local function calculateMaxHP(player)
	local effectiveCON = getEffectiveStat(player, "Constitution")
	return CONFIG.BaseHP + (effectiveCON * CONFIG.ConstitutionToHP)
end

local function calculateMaxStamina(player)
	local effectiveCON = getEffectiveStat(player, "Constitution")
	return CONFIG.BaseStamina + (effectiveCON * CONFIG.ConstitutionToStamina)
end

local function calculateSpeed(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then return CONFIG.BaseSpeed end
	local effectiveDEX = getEffectiveStat(player, "Dexterity")
	local speed = CONFIG.BaseSpeed + (effectiveDEX * CONFIG.DexterityToSpeed) - stats.EquipmentWeight.Value
	return math.clamp(speed, 0, CONFIG.MaxSpeed)
end

local function calculatePhysicalDamage(player)
	local effectiveSTR = getEffectiveStat(player, "Strength")
	return CONFIG.BasePhysicalDamage + (effectiveSTR * CONFIG.StrengthToDamage)
end

local function calculateSpellRange(player)
	local effectiveINT = getEffectiveStat(player, "Intelligence")
	return CONFIG.BaseSpellRange + (effectiveINT * CONFIG.IntelligenceToSpellRange)
end

local function calculateWordCount(player)
	local effectiveINT = getEffectiveStat(player, "Intelligence")
	return CONFIG.BaseWordCount + math.floor(effectiveINT * CONFIG.IntelligenceToWordCount)
end

-- Recalculate all derived stats
local function recalculateDerivedStats(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then return end

	local newMaxHP = calculateMaxHP(player)
	local newMaxStamina = calculateMaxStamina(player)

	stats.MaxHP.Value = newMaxHP
	stats.MaxStamina.Value = newMaxStamina

	-- Don't exceed new max
	stats.CurrentHP.Value = math.min(stats.CurrentHP.Value, newMaxHP)
	stats.CurrentStamina.Value = math.min(stats.CurrentStamina.Value, newMaxStamina)

	stats.Speed.Value = calculateSpeed(player)
	stats.SpellRange.Value = calculateSpellRange(player)
	stats.WordCount.Value = calculateWordCount(player)

	-- Apply speed to character
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = stats.Speed.Value
		end
	end
end

-- ============================================================================
-- CHARACTER LEVELING (Combat XP - reserved for enemy fights)
-- ============================================================================

local function levelUp(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("Stats")
	if not leaderstats or not stats then return end

	local level = leaderstats.Level
	local xp = stats.XP
	local xpRequired = stats.XPRequired

	xp.Value = xp.Value - xpRequired.Value
	level.Value = level.Value + 1
	xpRequired.Value = math.floor(xpRequired.Value * CONFIG.XPScaling)

	-- Full heal on level up
	stats.CurrentHP.Value = stats.MaxHP.Value
	stats.CurrentStamina.Value = stats.MaxStamina.Value

	-- Recalculate since level bonus now applies to all derived stats
	recalculateDerivedStats(player)

	print("?? " .. player.Name .. " reached Character Level " .. level.Value .. "!")
	print("   All effective stats increased by " .. CONFIG.LevelStatBonus)
	print("   Next Level: " .. xpRequired.Value .. " XP")
end

local function giveXP(player, amount)
	local stats = player:FindFirstChild("Stats")
	if not stats then return end

	stats.XP.Value = stats.XP.Value + amount
	print(player.Name .. " gained " .. amount .. " combat XP!")

	while stats.XP.Value >= stats.XPRequired.Value do
		levelUp(player)
	end
end

-- ============================================================================
-- STAT XP SYSTEM (Minigame XP - raises individual stats)
-- Each stat has its own XP pool with a soft scaling curve
-- ============================================================================

-- Map stat name to its Stats folder IntValue name
local STAT_MAP = {
	Strength = "Strength",
	Dexterity = "Dexterity",
	Constitution = "Constitution",
	Intelligence = "Intelligence",
}

local function giveStatXP(player, statName, amount)
	local stats = player:FindFirstChild("Stats")
	local statProgress = player:FindFirstChild("StatProgress")
	if not stats or not statProgress then
		warn("giveStatXP: Missing Stats or StatProgress for " .. player.Name)
		return false
	end

	-- Validate stat name
	if not STAT_MAP[statName] then
		warn("giveStatXP: Invalid stat name '" .. statName .. "'")
		return false
	end

	local xpValue = statProgress:FindFirstChild(statName .. "XP")
	local xpReqValue = statProgress:FindFirstChild(statName .. "XPRequired")
	local statValue = stats:FindFirstChild(STAT_MAP[statName])

	if not (xpValue and xpReqValue and statValue) then
		warn("giveStatXP: Missing values for " .. statName)
		return false
	end

	xpValue.Value = xpValue.Value + amount
	print(player.Name .. " gained " .. amount .. " " .. statName .. " XP (" .. xpValue.Value .. "/" .. xpReqValue.Value .. ")")

	-- Check for rank-ups (loop in case of large XP grants)
	local rankedUp = false
	while xpValue.Value >= xpReqValue.Value do
		xpValue.Value = xpValue.Value - xpReqValue.Value
		statValue.Value = statValue.Value + 1

		-- Softer scaling curve (1.25 vs 1.5 for character leveling)
		xpReqValue.Value = math.floor(xpReqValue.Value * CONFIG.StatXPScaling)

		recalculateDerivedStats(player)
		rankedUp = true

		print("?? " .. player.Name .. "'s " .. statName .. " increased to " .. statValue.Value .. "!")
		print("   Next rank: " .. xpReqValue.Value .. " XP")
	end

	return rankedUp
end

-- Convenience wrappers for each minigame to call
local function giveStrengthXP(player, amount)
	return giveStatXP(player, "Strength", amount)
end

local function giveDexterityXP(player, amount)
	return giveStatXP(player, "Dexterity", amount)
end

local function giveConstitutionXP(player, amount)
	return giveStatXP(player, "Constitution", amount)
end

local function giveIntelligenceXP(player, amount)
	return giveStatXP(player, "Intelligence", amount)
end

-- ============================================================================
-- ADMIN-ONLY DIRECT STAT ALLOCATION
-- These are only called by AdminCommands.lua, never exposed to clients
-- ============================================================================

local function addStrength(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end
	local statPoints = stats.StatPoints
	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		stats.Strength.Value = stats.Strength.Value + points
		recalculateDerivedStats(player)
		print("[ADMIN] " .. player.Name .. "'s Strength set to " .. stats.Strength.Value)
		return true
	end
	return false
end

local function addDexterity(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end
	local statPoints = stats.StatPoints
	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		stats.Dexterity.Value = stats.Dexterity.Value + points
		recalculateDerivedStats(player)
		print("[ADMIN] " .. player.Name .. "'s Dexterity set to " .. stats.Dexterity.Value)
		return true
	end
	return false
end

local function addConstitution(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end
	local statPoints = stats.StatPoints
	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		stats.Constitution.Value = stats.Constitution.Value + points
		recalculateDerivedStats(player)
		print("[ADMIN] " .. player.Name .. "'s Constitution set to " .. stats.Constitution.Value)
		return true
	end
	return false
end

local function addIntelligence(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end
	local statPoints = stats.StatPoints
	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		stats.Intelligence.Value = stats.Intelligence.Value + points
		recalculateDerivedStats(player)
		print("[ADMIN] " .. player.Name .. "'s Intelligence set to " .. stats.Intelligence.Value)
		return true
	end
	return false
end

-- ============================================================================
-- PLAYER INITIALIZATION
-- ============================================================================

local function initializePlayer(player)
	print("\n" .. player.Name .. " is joining...")
	setupPlayerStats(player)

	local data = DataStoreManager.LoadData(player)
	DataStoreManager.ApplyData(player, data)
	recalculateDerivedStats(player)

	-- Apply speed on character spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local stats = player:FindFirstChild("Stats")
		if stats then
			humanoid.WalkSpeed = stats.Speed.Value

			-- Lock animation speed to prevent silly running at high speeds
			task.spawn(function()
				local animator = humanoid:WaitForChild("Animator", 5)
				if not animator then return end

				local RunService = game:GetService("RunService")
				RunService.Heartbeat:Connect(function()
					for _, track in pairs(animator:GetPlayingAnimationTracks()) do
						local name = track.Name:lower()
						local animId = track.Animation and track.Animation.AnimationId:lower() or ""
						if name:find("run") or animId:find("run") or name:find("walk") or animId:find("walk") then
							track:AdjustSpeed(1.0)
						end
					end
				end)
			end)
		end
	end)

	task.wait(0.5)
	print("? " .. player.Name .. " ready!")
end

Players.PlayerAdded:Connect(initializePlayer)

for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		initializePlayer(player)
	end)
end

-- ============================================================================
-- EXPOSE FUNCTIONS
-- ============================================================================

local StatsManager = {}

-- Combat XP (for enemies)
StatsManager.GiveXP = giveXP

-- Stat XP (for minigames - call these from each minigame's server script)
StatsManager.GiveStatXP = giveStatXP
StatsManager.GiveStrengthXP = giveStrengthXP
StatsManager.GiveDexterityXP = giveDexterityXP
StatsManager.GiveConstitutionXP = giveConstitutionXP
StatsManager.GiveIntelligenceXP = giveIntelligenceXP

-- Admin-only direct allocation (used by AdminCommands.lua)
StatsManager.AddStrength = addStrength
StatsManager.AddDexterity = addDexterity
StatsManager.AddConstitution = addConstitution
StatsManager.AddIntelligence = addIntelligence

-- Calculations
StatsManager.GetPhysicalDamage = function(player)
	return calculatePhysicalDamage(player)
end

StatsManager.GetEffectiveStat = getEffectiveStat
StatsManager.RecalculateDerivedStats = recalculateDerivedStats

-- Data Management
StatsManager.SaveData = function(player)
	return DataStoreManager.SaveData(player)
end

-- Debug display
StatsManager.DisplayStats = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("Stats")
	local statProgress = player:FindFirstChild("StatProgress")
	if not leaderstats or not stats then return end

	local levelBonus = leaderstats.Level.Value * CONFIG.LevelStatBonus

	print("\n========================================")
	print("  " .. player.Name .. " - Character Level " .. leaderstats.Level.Value)
	print("  Level Stat Bonus: +" .. levelBonus .. " to all stats")
	print("========================================")
	print("  HP: " .. math.floor(stats.CurrentHP.Value) .. "/" .. math.floor(stats.MaxHP.Value))
	print("  Stamina: " .. math.floor(stats.CurrentStamina.Value) .. "/" .. math.floor(stats.MaxStamina.Value))
	print("  Combat XP: " .. stats.XP.Value .. "/" .. stats.XPRequired.Value)
	print("----------------------------------------")
	print("  Strength: " .. stats.Strength.Value .. " (Effective: " .. getEffectiveStat(player, "Strength") .. ", Damage: " .. calculatePhysicalDamage(player) .. ")")
	print("  Dexterity: " .. stats.Dexterity.Value .. " (Effective: " .. getEffectiveStat(player, "Dexterity") .. ", Speed: " .. math.floor(stats.Speed.Value) .. ")")
	print("  Constitution: " .. stats.Constitution.Value .. " (Effective: " .. getEffectiveStat(player, "Constitution") .. ")")
	print("  Intelligence: " .. stats.Intelligence.Value .. " (Effective: " .. getEffectiveStat(player, "Intelligence") .. ", Range: " .. stats.SpellRange.Value .. ", Words: " .. stats.WordCount.Value .. ")")

	if statProgress then
		print("----------------------------------------")
		print("  STAT XP PROGRESS:")
		for _, statName in ipairs({"Strength", "Dexterity", "Constitution", "Intelligence"}) do
			local xp = statProgress:FindFirstChild(statName .. "XP")
			local xpReq = statProgress:FindFirstChild(statName .. "XPRequired")
			if xp and xpReq then
				print("  " .. statName .. " XP: " .. xp.Value .. "/" .. xpReq.Value)
			end
		end
	end

	print("----------------------------------------")
	print("  Defense: " .. stats.Defense.Value)
	print("  Stat Points (admin): " .. stats.StatPoints.Value)
	print("========================================\n")
end

print("? PlayerStatsManager loaded!")
print("  Stat XP system active — feed via GiveStrengthXP, GiveDexterityXP, etc.")
print("  Combat XP system ready — feed via GiveXP when enemies are implemented")

return StatsManager
