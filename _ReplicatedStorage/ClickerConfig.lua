--[[
	ClickerConfig.lua (ReplicatedStorage - ModuleScript)
	Shared configuration for the Clicker mini-game
	
	HOW TO USE CUSTOM IMAGES:
	1. In Studio, open Asset Manager (View ? Asset Manager)
	2. Upload button (?) ? Image ? select your PNG/JPG
	3. Right-click uploaded image ? Copy ID
	4. Paste below as "rbxassetid://YOUR_ID_HERE"
--]]

local ClickerConfig = {}

-- ============================================================================
-- CUSTOM IMAGES - Replace these with your own asset IDs!
-- ============================================================================
ClickerConfig.Images = {
	-- Main target images (add as many as you want)
	-- Format: "rbxassetid://YOUR_ID_HERE"
	"rbxassetid://128543846808831"
}

-- ============================================================================
-- GAME SETTINGS
-- ============================================================================

-- Grid size for where targets can spawn (screen is divided into a grid)
ClickerConfig.GridColumns = 4
ClickerConfig.GridRows    = 3

-- Image size in pixels (targets are square)
ClickerConfig.TargetSizeBase = 120 -- Starting size at level 1
ClickerConfig.TargetSizeMin  = 50  -- Minimum size at high levels

-- How long a target stays on screen before disappearing (seconds)
ClickerConfig.TargetLifetimeBase = 3.0  -- Level 1
ClickerConfig.TargetLifetimeMin  = 0.6  -- Absolute minimum

-- How quickly a new target spawns after clicking (seconds)
ClickerConfig.SpawnDelayBase = 0.3
ClickerConfig.SpawnDelayMin  = 0.05

-- ============================================================================
-- LEVEL PROGRESSION
-- ============================================================================

-- How many successful clicks to advance a level
ClickerConfig.ClicksToLevelUp = 10

-- At what level does a second target appear, third, etc.
ClickerConfig.MultiTargetThresholds = {
	[1]  = 1, -- Level 1:  1 target
	[5]  = 2, -- Level 5:  2 targets
	[10] = 3, -- Level 10: 3 targets
	[18] = 4, -- Level 18: 4 targets
	[28] = 5, -- Level 28: 5 targets
}

-- ============================================================================
-- SCORING & XP
-- ============================================================================

-- Base score per click
ClickerConfig.BaseScore = 10

-- Combo multiplier: each consecutive click within ComboWindow seconds adds this
ClickerConfig.ComboWindow       = 1.5  -- seconds
ClickerConfig.ComboMultiplier   = 0.5  -- +0.5x per combo hit (so 2nd click = 1.5x, 3rd = 2.0x, etc.)
ClickerConfig.MaxComboMultiplier = 8.0 -- Cap at 8x

-- XP awarded per click (scales with level)
-- Formula: BaseXP * level^XPLevelExponent
ClickerConfig.BaseXP           = 5
ClickerConfig.XPLevelExponent  = 1.2

-- Bonus XP for surviving a full round (all targets caught, none missed)
ClickerConfig.PerfectRoundXPBonus = 50

-- ============================================================================
-- DIFFICULTY SCALING FUNCTIONS
-- ============================================================================

-- Returns number of simultaneous targets for a given level
function ClickerConfig.GetTargetCount(level: number): number
	local count = 1
	for threshold, num in pairs(ClickerConfig.MultiTargetThresholds) do
		if level >= threshold then
			count = math.max(count, num)
		end
	end
	return count
end

-- Returns how long a target survives on screen
function ClickerConfig.GetTargetLifetime(level: number): number
	local t = ClickerConfig.TargetLifetimeBase - (level - 1) * 0.08
	return math.max(t, ClickerConfig.TargetLifetimeMin)
end

-- Returns target size in pixels
function ClickerConfig.GetTargetSize(level: number): number
	local s = ClickerConfig.TargetSizeBase - (level - 1) * 3
	return math.max(s, ClickerConfig.TargetSizeMin)
end

-- Returns spawn delay (gap between targets appearing)
function ClickerConfig.GetSpawnDelay(level: number): number
	local d = ClickerConfig.SpawnDelayBase - (level - 1) * 0.005
	return math.max(d, ClickerConfig.SpawnDelayMin)
end

-- Returns XP per click
function ClickerConfig.GetXPPerClick(level: number): number
	return math.floor(ClickerConfig.BaseXP * (level ^ ClickerConfig.XPLevelExponent))
end

-- Returns score per click (before combo)
function ClickerConfig.GetScorePerClick(level: number): number
	return ClickerConfig.BaseScore + (level - 1) * 2
end

-- ============================================================================
-- VISUAL
-- ============================================================================

ClickerConfig.Colors = {
	Background    = Color3.fromRGB(10, 10, 18),
	Panel         = Color3.fromRGB(25, 22, 35),
	Accent        = Color3.fromRGB(255, 180, 50),   -- Gold
	AccentHot     = Color3.fromRGB(255, 80, 80),    -- Red for urgency
	ComboColor    = Color3.fromRGB(255, 220, 50),
	MissColor     = Color3.fromRGB(255, 60, 60),
	HitColor      = Color3.fromRGB(80, 255, 120),
	Text          = Color3.fromRGB(240, 240, 250),
	TextDim       = Color3.fromRGB(160, 160, 180),
}

-- ============================================================================
-- SOUNDS (leave "" to skip)
-- ============================================================================
ClickerConfig.Sounds = {
	Hit      = "rbxassetid://4590662766",  -- Click hit sound
	Miss     = "rbxassetid://4590657945",  -- Target expired sound
	Combo    = "rbxassetid://4107693819",  -- Combo streak sound
	LevelUp  = "rbxassetid://4403506847",  -- Level up fanfare
	GameOver = "rbxassetid://4106962396",  -- Session end
}

-- ============================================================================
-- FLAVOUR TEXT
-- ============================================================================
ClickerConfig.LevelUpMessages = {
	"? FASTER!",
	"?? HEATING UP!",
	"?? UNSTOPPABLE!",
	"? LIGHTNING REFLEXES!",
	"?? TIME SLOWS FOR NO ONE!",
	"?? PRECISION MASTER!",
}

function ClickerConfig.GetLevelUpMessage(): string
	return ClickerConfig.LevelUpMessages[math.random(1, #ClickerConfig.LevelUpMessages)]
end

print("? ClickerConfig loaded!")
return ClickerConfig