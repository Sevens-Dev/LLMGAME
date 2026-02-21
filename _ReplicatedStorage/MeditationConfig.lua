--[[
	MeditationConfig.lua
	Configuration for Meditation & Martial Arts Mental Training
	Incorporates concepts: Chi Flow, Breath Control, Mindfulness, Focus
--]]

local MeditationConfig = {}

-- ========================================
-- MEDITATION & MARTIAL ARTS THEMES
-- ========================================

-- Training Disciplines (Progression Stages)
MeditationConfig.Disciplines = {
	{Name = "Novice Monk", MinLevel = 1, MaxLevel = 3, Chi = "white"},
	{Name = "Student of the Way", MinLevel = 4, MaxLevel = 7, Chi = "blue"},
	{Name = "Focused Warrior", MinLevel = 8, MaxLevel = 12, Chi = "purple"},
	{Name = "Master of Mind", MinLevel = 13, MaxLevel = 17, Chi = "gold"},
	{Name = "Enlightened One", MinLevel = 18, MaxLevel = 999, Chi = "rainbow"}
}

-- Meditation Techniques (Different Game Modes)
MeditationConfig.Techniques = {
	ChiFlow = {
		Name = "Energy Flow Meditation",
		Description = "Follow the path of energy through the grid",
		Icon = "?",
		Style = "sequential" -- Watch and repeat sequence
	},
	BreathControl = {
		Name = "Breath Control",
		Description = "Inhale focus, exhale tension. Match the rhythm.",
		Icon = "???",
		Style = "rhythm" -- Time-based pattern matching
	},
	MindfulAwareness = {
		Name = "Mindful Awareness",
		Description = "Notice what changes in the present moment",
		Icon = "???",
		Style = "difference" -- Spot the difference
	},
	IronWill = {
		Name = "Iron Will Training",
		Description = "Maintain focus as distractions arise",
		Icon = "?",
		Style = "endurance" -- Progressive difficulty
	}
}

-- Current Active Technique
MeditationConfig.ActiveTechnique = "ChiFlow"

-- ========================================
-- DIFFICULTY PROGRESSION (Chi Flow)
-- ========================================

-- Path Complexity
MeditationConfig.StartingPathLength = 3
MeditationConfig.MaxPathLength = 15
MeditationConfig.PathLengthIncrease = 1

-- Meditation Speed (slower is more mindful)
MeditationConfig.StartingFlowTime = 1.2 -- Slow, mindful start
MeditationConfig.MinFlowTime = 0.4 -- Advanced speed
MeditationConfig.FlowTimeDecrease = 0.05

-- Breathing Rhythm
MeditationConfig.InhaleTime = 1.0 -- Time for tiles to light (inhale)
MeditationConfig.ExhaleTime = 0.3 -- Time between tiles (exhale)
MeditationConfig.MeditationPrepareTime = 3.0 -- Center yourself

-- Grid Configuration
MeditationConfig.GridSize = 4 -- 4x4 mandala pattern
MeditationConfig.GridShape = "circle" -- "circle", "cross", "square"

-- ========================================
-- VISUAL THEME: ZEN & MARTIAL ARTS
-- ========================================

MeditationConfig.Colors = {
	-- Background (peaceful temple)
	Background = Color3.fromRGB(15, 15, 20),
	Temple = Color3.fromRGB(30, 25, 35),

	-- Chi Energy Colors
	Chi = {
		Dormant = Color3.fromRGB(40, 40, 50), -- Unlit stone
		White = Color3.fromRGB(220, 220, 240), -- Novice
		Blue = Color3.fromRGB(100, 180, 255), -- Student
		Purple = Color3.fromRGB(180, 100, 255), -- Warrior
		Gold = Color3.fromRGB(255, 215, 100), -- Master
		Rainbow = Color3.fromHSV(0.5, 0.8, 1.0) -- Enlightened (animated)
	},

	-- Flow States
	Flowing = Color3.fromRGB(150, 220, 255), -- Chi flowing through
	Correct = Color3.fromRGB(150, 255, 180), -- Harmony achieved
	Incorrect = Color3.fromRGB(255, 120, 120), -- Disrupted flow
	Active = Color3.fromRGB(255, 230, 150), -- Current focus

	-- UI Elements
	TextPrimary = Color3.fromRGB(240, 240, 250),
	TextSecondary = Color3.fromRGB(180, 180, 200),
	Accent = Color3.fromRGB(150, 200, 255)
}

-- ========================================
-- SCORING: ENLIGHTENMENT POINTS
-- ========================================

MeditationConfig.BaseEnlightenment = 100
MeditationConfig.HarmonyMultiplier = 1.5 -- Consecutive successes
MeditationConfig.PerfectFlowMultiplier = 2.0 -- No mistakes
MeditationConfig.MindfulnessBonus = 50 -- Bonus for slow, deliberate play

-- Chi Energy System
MeditationConfig.ChiPerLevel = 10
MeditationConfig.MaxChi = 100

-- ========================================
-- AUDIO: MEDITATION SOUNDS
-- ========================================

MeditationConfig.Sounds = {
	-- Meditation ambience (using valid placeholder sounds)
	TibetanBowl = "rbxasset://sounds/electronicpingshort.wav", -- Gentle ping
	ChiFlow = "rbxasset://sounds/electronicpingshort.wav", -- Gentle chime
	BreathIn = "rbxasset://sounds/button.wav", -- Soft whoosh
	BreathOut = "rbxasset://sounds/button.wav", -- Exhale

	-- Feedback
	Harmony = "rbxasset://sounds/switch.wav", -- Success (peaceful)
	Disruption = "rbxasset://sounds/hit.wav", -- Mistake (gentle gong)
	Enlightenment = "rbxasset://sounds/uuhhh.wav", -- Level up

	-- Ambient (looping) - using empty for now, add your own
	TempleAmbience = "", -- Peaceful background (upload your own)
	MeditationDrone = "" -- Om/drone sound (upload your own)
}

-- ========================================
-- MEDITATIVE MESSAGES
-- ========================================

MeditationConfig.WisdomQuotes = {
	-- Preparation
	"Center your mind...",
	"Breathe deeply...",
	"Focus your chi...",
	"Clear your thoughts...",
	"Enter the flow state...",

	-- Success
	"Harmony achieved",
	"Your focus sharpens",
	"Energy flows freely",
	"The path is clear",
	"Mind and body unite",

	-- Failure (constructive)
	"Even masters stumble",
	"Return to center",
	"Learn from discord",
	"Begin again with peace",
	"The journey continues"
}

MeditationConfig.TechniqueDescriptions = {
	"Follow the energy as it flows through the meditation grid",
	"Like water finding its path, trace the energy's journey",
	"Empty your mind. Observe the pattern without attachment",
	"When ready, recreate the flow with intention and clarity"
}

-- ========================================
-- PARTICLE & VISUAL EFFECTS
-- ========================================

MeditationConfig.Effects = {
	EnableParticles = true,
	EnableGlow = true,
	EnableRipples = true,
	ChiTrailLength = 0.5,
	EnlightenmentBurst = true
}

-- ========================================
-- HELPER FUNCTIONS
-- ========================================

-- Get current discipline based on level
function MeditationConfig.GetDiscipline(level: number)
	for _, discipline in ipairs(MeditationConfig.Disciplines) do
		if level >= discipline.MinLevel and level <= discipline.MaxLevel then
			return discipline
		end
	end
	return MeditationConfig.Disciplines[#MeditationConfig.Disciplines]
end

-- Get difficulty for level
function MeditationConfig.GetDifficultyForLevel(level: number)
	local pathLength = math.min(
		MeditationConfig.StartingPathLength + (level - 1) * MeditationConfig.PathLengthIncrease,
		MeditationConfig.MaxPathLength
	)

	local flowTime = math.max(
		MeditationConfig.StartingFlowTime - (level - 1) * MeditationConfig.FlowTimeDecrease,
		MeditationConfig.MinFlowTime
	)

	return {
		Level = level,
		PathLength = pathLength,
		FlowTime = flowTime,
		Discipline = MeditationConfig.GetDiscipline(level)
	}
end

-- Calculate enlightenment (score)
function MeditationConfig.CalculateEnlightenment(level: number, mistakes: number, harmony: number, timeBonus: boolean)
	local base = MeditationConfig.BaseEnlightenment * level
	local harmonyBonus = math.floor(base * (harmony * 0.1))
	local perfectBonus = mistakes == 0 and math.floor(base * (MeditationConfig.PerfectFlowMultiplier - 1)) or 0
	local mindfulBonus = timeBonus and MeditationConfig.MindfulnessBonus or 0

	return base + harmonyBonus + perfectBonus + mindfulBonus
end

-- Get random wisdom quote
function MeditationConfig.GetWisdom(category: string): string
	local quotes = MeditationConfig.WisdomQuotes
	return quotes[math.random(1, #quotes)]
end

-- Get chi color for level
function MeditationConfig.GetChiColor(level: number): Color3
	local discipline = MeditationConfig.GetDiscipline(level)
	local chiName = discipline.Chi

	-- Capitalize first letter to match Colors.Chi table
	local capitalizedChi = chiName:sub(1, 1):upper() .. chiName:sub(2)

	return MeditationConfig.Colors.Chi[capitalizedChi] or MeditationConfig.Colors.Chi.White
end

return MeditationConfig