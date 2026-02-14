-- PlayerStatsManager
-- Place this as a ModuleScript in ServerScriptService
-- Handles player leveling and stat systems for Roblox

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
			print("✓ Successfully loaded StatDataStoreManager")
		end
	end
until DataStoreManager

-- ============================================================================
-- CONFIGURATION - EDIT THESE VALUES TO BALANCE THE GAME
-- ============================================================================
local CONFIG = {
	-- Leveling
	StartingLevel = 1,
	StartingXP = 0,
	BaseXPRequired = 100,
	XPScaling = 1.5, -- XP requirement multiplier per level
	StatPointsPerLevel = 3,

	-- Primary Stats (starting values)
	StartingStrength = 1,
	StartingDexterity = 1,
	StartingConstitution = 1,
	StartingIntelligence = 1,

	-- Stat Conversions
	StrengthToDamage = 2, -- Each STR point adds this much physical damage
	DexterityToSpeed = 0.5, -- Each DEX point adds this much speed
	ConstitutionToHP = 10, -- Each CON point adds this much max HP
	ConstitutionToStamina = 5, -- Each CON point adds this much max stamina
	IntelligenceToSpellRange = 1, -- Each INT point adds this much spell range
	IntelligenceToWordCount = 0.5, -- Each INT point adds this much to word count (rounded down)

	-- Base Values
	BasePhysicalDamage = 5,
	BaseHP = 100,
	BaseStamina = 100,
	BaseSpeed = 16, -- Roblox default WalkSpeed
	BaseSpellRange = 50, -- Base spell range in studs
	BaseWordCount = 10, -- Base word count for spells

	-- Caps
	MaxSpeed = 80, -- Maximum speed cap (5x normal walking speed)

	-- Equipment (defaults)
	DefaultDefense = 0,
	DefaultEquipmentWeight = 0
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

	-- Stats folder (hidden stats)
	local stats = Instance.new("Folder")
	stats.Name = "Stats"
	stats.Parent = player

	-- XP System
	local xpValue = Instance.new("IntValue")
	xpValue.Name = "XP"
	xpValue.Value = CONFIG.StartingXP
	xpValue.Parent = stats

	local xpRequiredValue = Instance.new("IntValue")
	xpRequiredValue.Name = "XPRequired"
	xpRequiredValue.Value = CONFIG.BaseXPRequired
	xpRequiredValue.Parent = stats

	-- Primary Stats
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

	-- Derived Stats (NumberValue for decimals)
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

	-- Misc
	local statPointsValue = Instance.new("IntValue")
	statPointsValue.Name = "StatPoints"
	statPointsValue.Value = 0
	statPointsValue.Parent = stats

	print("✓ " .. player.Name .. " stats initialized!")
end

-- ============================================================================
-- STAT CALCULATION FUNCTIONS
-- ============================================================================

local function calculateMaxHP(constitution)
	return CONFIG.BaseHP + (constitution * CONFIG.ConstitutionToHP)
end

local function calculateMaxStamina(constitution)
	return CONFIG.BaseStamina + (constitution * CONFIG.ConstitutionToStamina)
end

local function calculateSpeed(dexterity, equipmentWeight)
	local speed = CONFIG.BaseSpeed + (dexterity * CONFIG.DexterityToSpeed) - equipmentWeight
	return math.clamp(speed, 0, CONFIG.MaxSpeed) -- Apply cap and minimum 0
end

local function calculatePhysicalDamage(strength)
	return CONFIG.BasePhysicalDamage + (strength * CONFIG.StrengthToDamage)
end

local function calculateSpellRange(intelligence)
	return CONFIG.BaseSpellRange + (intelligence * CONFIG.IntelligenceToSpellRange)
end

local function calculateWordCount(intelligence)
	return CONFIG.BaseWordCount + math.floor(intelligence * CONFIG.IntelligenceToWordCount)
end

-- Recalculate all derived stats
local function recalculateDerivedStats(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then return end

	local constitution = stats.Constitution.Value
	local dexterity = stats.Dexterity.Value
	local intelligence = stats.Intelligence.Value
	local equipmentWeight = stats.EquipmentWeight.Value

	-- Update MaxHP and MaxStamina
	local newMaxHP = calculateMaxHP(constitution)
	local newMaxStamina = calculateMaxStamina(constitution)

	-- Scale current HP/Stamina proportionally if max changed
	local hpRatio = stats.CurrentHP.Value / stats.MaxHP.Value
	local staminaRatio = stats.CurrentStamina.Value / stats.MaxStamina.Value

	stats.MaxHP.Value = newMaxHP
	stats.MaxStamina.Value = newMaxStamina

	stats.CurrentHP.Value = math.min(stats.CurrentHP.Value, newMaxHP) -- Don't exceed new max
	stats.CurrentStamina.Value = math.min(stats.CurrentStamina.Value, newMaxStamina)

	-- Update Speed
	stats.Speed.Value = calculateSpeed(dexterity, equipmentWeight)

	-- Update Spell Stats
	stats.SpellRange.Value = calculateSpellRange(intelligence)
	stats.WordCount.Value = calculateWordCount(intelligence)

	-- Apply speed to character
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = stats.Speed.Value
		end
	end
end

-- ============================================================================
-- LEVELING SYSTEM
-- ============================================================================

local function levelUp(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("Stats")
	if not leaderstats or not stats then return end

	local level = leaderstats.Level
	local xp = stats.XP
	local xpRequired = stats.XPRequired
	local statPoints = stats.StatPoints

	-- Deduct XP and increase level
	xp.Value = xp.Value - xpRequired.Value
	level.Value = level.Value + 1

	-- Scale XP requirement
	xpRequired.Value = math.floor(xpRequired.Value * CONFIG.XPScaling)

	-- Grant stat points
	statPoints.Value = statPoints.Value + CONFIG.StatPointsPerLevel

	-- Full heal on level up
	stats.CurrentHP.Value = stats.MaxHP.Value
	stats.CurrentStamina.Value = stats.MaxStamina.Value

	-- Notify player
	print("🎉 " .. player.Name .. " leveled up to Level " .. level.Value .. "!")
	print("   Stat Points: +" .. CONFIG.StatPointsPerLevel)
	print("   Next Level: " .. xpRequired.Value .. " XP")
end

local function giveXP(player, amount)
	local stats = player:FindFirstChild("Stats")
	if not stats then return end

	local xp = stats.XP
	local xpRequired = stats.XPRequired

	xp.Value = xp.Value + amount
	print(player.Name .. " gained " .. amount .. " XP!")

	while xp.Value >= xpRequired.Value do
		levelUp(player)
	end
end

-- ============================================================================
-- STAT ALLOCATION FUNCTIONS
-- ============================================================================

local function addStrength(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end

	local statPoints = stats.StatPoints
	local strength = stats.Strength

	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		strength.Value = strength.Value + points
		print(player.Name .. "'s Strength increased to " .. strength.Value .. "!")
		return true
	end
	return false
end

local function addDexterity(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end

	local statPoints = stats.StatPoints
	local dexterity = stats.Dexterity

	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		dexterity.Value = dexterity.Value + points
		recalculateDerivedStats(player)
		print(player.Name .. "'s Dexterity increased to " .. dexterity.Value .. "!")
		return true
	end
	return false
end

local function addConstitution(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end

	local statPoints = stats.StatPoints
	local constitution = stats.Constitution

	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		constitution.Value = constitution.Value + points
		recalculateDerivedStats(player)
		print(player.Name .. "'s Constitution increased to " .. constitution.Value .. "!")
		return true
	end
	return false
end

local function addIntelligence(player, points)
	local stats = player:FindFirstChild("Stats")
	if not stats then return false end

	local statPoints = stats.StatPoints
	local intelligence = stats.Intelligence

	if statPoints.Value >= points then
		statPoints.Value = statPoints.Value - points
		intelligence.Value = intelligence.Value + points
		recalculateDerivedStats(player)
		print(player.Name .. "'s Intelligence increased to " .. intelligence.Value .. "!")
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
	-- Recalculate all derived stats after loading
	recalculateDerivedStats(player)
	-- Apply speed to character when they spawn
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local stats = player:FindFirstChild("Stats")
		if stats then
			humanoid.WalkSpeed = stats.Speed.Value

			-- Lock animation speed so running doesn't look ridiculous at high speeds
			task.spawn(function()
				local animator = humanoid:WaitForChild("Animator", 5)
				if not animator then return end

				local RunService = game:GetService("RunService")

				-- Continuously monitor and lock animation speeds
				RunService.Heartbeat:Connect(function()
					for _, track in pairs(animator:GetPlayingAnimationTracks()) do
						local name = track.Name:lower()
						local animId = track.Animation.AnimationId:lower()

						-- Lock run and walk animations to normal speed (1.0)
						if name:find("run") or animId:find("run") or name:find("walk") or animId:find("walk") then
							track:AdjustSpeed(1.0)
						end
					end
				end)
			end)
		end
	end)
	task.wait(0.5)
	print("✓ " .. player.Name .. " ready!")
end
-- Connect to players
Players.PlayerAdded:Connect(initializePlayer)
-- Handle players already in game
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		initializePlayer(player)
	end)
end
-- ============================================================================
-- EXPOSE FUNCTIONS
-- ============================================================================

local StatsManager = {}

-- XP & Leveling
StatsManager.GiveXP = giveXP

-- Stat Allocation
StatsManager.AddStrength = addStrength
StatsManager.AddDexterity = addDexterity
StatsManager.AddConstitution = addConstitution
StatsManager.AddIntelligence = addIntelligence

-- Stat Calculations
StatsManager.GetPhysicalDamage = function(player)
	local stats = player:FindFirstChild("Stats")
	if not stats then return 0 end
	return calculatePhysicalDamage(stats.Strength.Value)
end

StatsManager.RecalculateDerivedStats = recalculateDerivedStats

-- Data Management
StatsManager.SaveData = function(player)
	return DataStoreManager.SaveData(player)
end

-- Display stats (for debugging)
StatsManager.DisplayStats = function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local stats = player:FindFirstChild("Stats")
	if not leaderstats or not stats then return end

	print("\n========================================")
	print("  " .. player.Name .. " - Level " .. leaderstats.Level.Value)
	print("========================================")
	print("  HP: " .. math.floor(stats.CurrentHP.Value) .. "/" .. math.floor(stats.MaxHP.Value))
	print("  Stamina: " .. math.floor(stats.CurrentStamina.Value) .. "/" .. math.floor(stats.MaxStamina.Value))
	print("  XP: " .. stats.XP.Value .. "/" .. stats.XPRequired.Value)
	print("----------------------------------------")
	print("  Strength: " .. stats.Strength.Value .. " (Damage: " .. StatsManager.GetPhysicalDamage(player) .. ")")
	print("  Dexterity: " .. stats.Dexterity.Value .. " (Speed: " .. math.floor(stats.Speed.Value) .. ")")
	print("  Constitution: " .. stats.Constitution.Value)
	print("  Intelligence: " .. stats.Intelligence.Value .. " (Range: " .. stats.SpellRange.Value .. ", Words: " .. stats.WordCount.Value .. ")")
	print("----------------------------------------")
	print("  Defense: " .. stats.Defense.Value)
	print("  Equipment Weight: " .. stats.EquipmentWeight.Value)
	print("  Stat Points: " .. stats.StatPoints.Value)
	print("========================================\n")
end

print("✓ PlayerStatsManager loaded and initialized!")

return StatsManager