--[[
	ClickerUIBuilder.lua (StarterPlayer/StarterPlayerScripts - LocalScript)
	Builds all GUI elements for the Clicker mini-game.
	Run BEFORE ClickerController.
--]]

local Players  = game:GetService("Players")
local player   = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- SCREEN GUI
-- ============================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "ClickerUI"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset  = true
screenGui.Parent          = playerGui

local C = { -- Colors (mirrors ClickerConfig for UI-only use)
	Background  = Color3.fromRGB(10, 10, 18),
	Panel       = Color3.fromRGB(25, 22, 35),
	Accent      = Color3.fromRGB(255, 180, 50),
	AccentHot   = Color3.fromRGB(255, 80, 80),
	Text        = Color3.fromRGB(240, 240, 250),
	TextDim     = Color3.fromRGB(160, 160, 180),
	HitGreen    = Color3.fromRGB(80, 255, 120),
	MissRed     = Color3.fromRGB(255, 60, 60),
	BarFg       = Color3.fromRGB(255, 180, 50),
	BarBg       = Color3.fromRGB(50, 45, 65),
}

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color        = color or Color3.new(1,1,1)
	s.Thickness    = thickness or 1
	s.Transparency = transparency or 0.5
	s.Parent       = parent
end

local function label(name, parent, props)
	local l = Instance.new("TextLabel")
	l.Name                = name
	l.BackgroundTransparency = 1
	l.Font                = Enum.Font.GothamBold
	l.TextColor3          = C.Text
	l.TextScaled          = true
	l.Parent              = parent
	for k, v in pairs(props or {}) do l[k] = v end
	return l
end

local function button(name, parent, props)
	local b = Instance.new("TextButton")
	b.Name            = name
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Font            = Enum.Font.GothamBold
	b.TextColor3      = C.Text
	b.TextScaled      = true
	b.Parent          = parent
	for k, v in pairs(props or {}) do b[k] = v end
	corner(b, 10)
	return b
end

local function frame(name, parent, props)
	local f = Instance.new("Frame")
	f.Name            = name
	f.BorderSizePixel = 0
	f.Parent          = parent
	for k, v in pairs(props or {}) do f[k] = v end
	return f
end

-- ============================================================
-- OPEN BUTTON (always visible, top right)
-- ============================================================

local openBtn = button("OpenClickerButton", screenGui, {
	Size            = UDim2.new(0, 140, 0, 50),
	Position        = UDim2.new(1, -155, 0, 305), -- Below meditation button
	BackgroundColor3 = C.Accent,
	Text            = "?? Clicker",
	TextSize        = 20,
	ZIndex          = 100,
})
stroke(openBtn, C.Accent, 1, 0.6)

-- ============================================================
-- MENU FRAME
-- ============================================================

local menuFrame = frame("MenuFrame", screenGui, {
	Size             = UDim2.new(0, 420, 0, 480),
	Position         = UDim2.new(0.5, -210, 0.5, -240),
	BackgroundColor3  = C.Panel,
	Visible          = false,
	ZIndex           = 50,
})
corner(menuFrame, 14)
stroke(menuFrame, C.Accent, 2, 0.4)

-- Title
label("TitleLabel", menuFrame, {
	Size     = UDim2.new(0.85, 0, 0.12, 0),
	Position = UDim2.new(0.075, 0, 0.05, 0),
	Text     = "?? REFLEX CLICKER",
	TextColor3 = C.Accent,
})

label("SubLabel", menuFrame, {
	Size     = UDim2.new(0.8, 0, 0.07, 0),
	Position = UDim2.new(0.1, 0, 0.18, 0),
	Text     = "Click targets before they vanish!",
	TextColor3 = C.TextDim,
	Font     = Enum.Font.Gotham,
})

-- How-to instructions
local instructions = {
	"• Images appear on screen — click them!",
	"• Miss too many and your combo resets.",
	"• Every level gets faster & harder.",
	"• More targets appear at higher levels.",
	"• Chain clicks for a combo multiplier!",
}
for i, line in ipairs(instructions) do
	label("Instruction" .. i, menuFrame, {
		Size     = UDim2.new(0.85, 0, 0.06, 0),
		Position = UDim2.new(0.075, 0, 0.26 + (i-1) * 0.07, 0),
		Text     = line,
		TextColor3 = C.Text,
		Font     = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = false,
		TextSize = 16,
	})
end

-- Stats display inside menu
local statsRow = frame("StatsRow", menuFrame, {
	Size             = UDim2.new(0.85, 0, 0.1, 0),
	Position         = UDim2.new(0.075, 0, 0.63, 0),
	BackgroundColor3  = Color3.fromRGB(35, 30, 48),
})
corner(statsRow, 8)

label("BestScoreLabel", statsRow, {
	Size     = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	Text     = "Best Score: –",
	TextColor3 = C.Accent,
	Font     = Enum.Font.Gotham,
})
label("BestLevelLabel", statsRow, {
	Size     = UDim2.new(0.5, 0, 1, 0),
	Position = UDim2.new(0.5, 0, 0, 0),
	Text     = "Best Level: –",
	TextColor3 = C.TextDim,
	Font     = Enum.Font.Gotham,
})

-- Buttons
button("BeginButton", menuFrame, {
	Size             = UDim2.new(0.5, 0, 0.1, 0),
	Position         = UDim2.new(0.25, 0, 0.78, 0),
	BackgroundColor3  = C.Accent,
	Text             = "START",
})
button("CloseMenuButton", menuFrame, {
	Size             = UDim2.new(0.5, 0, 0.08, 0),
	Position         = UDim2.new(0.25, 0, 0.9, 0),
	BackgroundColor3  = Color3.fromRGB(70, 65, 90),
	Text             = "Close",
})

-- ============================================================
-- GAME FRAME (full screen during play)
-- ============================================================

local gameFrame = frame("GameFrame", screenGui, {
	Size             = UDim2.new(1, 0, 1, 0),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3  = C.Background,
	Visible          = false,
	ZIndex           = 40,
})

-- HUD panel (top strip)
local hud = frame("HUD", gameFrame, {
	Size             = UDim2.new(1, 0, 0, 70),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3  = C.Panel,
})

-- Level
label("LevelLabel", hud, {
	Size     = UDim2.new(0.15, 0, 0.55, 0),
	Position = UDim2.new(0.02, 0, 0.1, 0),
	Text     = "LVL 1",
	TextColor3 = C.Accent,
})

-- Level progress bar
local barBg = frame("LevelBarBg", hud, {
	Size             = UDim2.new(0.28, 0, 0.22, 0),
	Position         = UDim2.new(0.02, 0, 0.68, 0),
	BackgroundColor3  = C.BarBg,
})
corner(barBg, 4)
local barFg = frame("LevelBarFg", barBg, {
	Size             = UDim2.new(0, 0, 1, 0),
	Position         = UDim2.new(0, 0, 0, 0),
	BackgroundColor3  = C.BarFg,
})
corner(barFg, 4)

-- Score
label("ScoreLabel", hud, {
	Size     = UDim2.new(0.25, 0, 0.55, 0),
	Position = UDim2.new(0.375, 0, 0.1, 0),
	Text     = "0",
	TextColor3 = C.Text,
	TextXAlignment = Enum.TextXAlignment.Center,
})
label("ScoreSublabel", hud, {
	Size     = UDim2.new(0.25, 0, 0.3, 0),
	Position = UDim2.new(0.375, 0, 0.65, 0),
	Text     = "SCORE",
	TextColor3 = C.TextDim,
	Font     = Enum.Font.Gotham,
})

-- Combo
label("ComboLabel", hud, {
	Size     = UDim2.new(0.2, 0, 0.55, 0),
	Position = UDim2.new(0.68, 0, 0.1, 0),
	Text     = "x1",
	TextColor3 = C.HitGreen,
})
label("ComboSublabel", hud, {
	Size     = UDim2.new(0.2, 0, 0.3, 0),
	Position = UDim2.new(0.68, 0, 0.65, 0),
	Text     = "COMBO",
	TextColor3 = C.TextDim,
	Font     = Enum.Font.Gotham,
})

-- Exit button
button("ExitButton", hud, {
	Size             = UDim2.new(0, 80, 0, 36),
	Position         = UDim2.new(1, -90, 0.5, -18),
	BackgroundColor3  = Color3.fromRGB(180, 50, 50),
	Text             = "Exit",
	TextSize         = 16,
	TextScaled       = false,
})

-- Target area (everything below HUD)
local targetArea = frame("TargetArea", gameFrame, {
	Size             = UDim2.new(1, 0, 1, -70),
	Position         = UDim2.new(0, 0, 0, 70),
	BackgroundTransparency = 1,
})
targetArea.ClipsDescendants = true

-- Floating feedback label ("+100 x3!" popups)
local feedbackLabel = label("FeedbackLabel", gameFrame, {
	Size     = UDim2.new(0.3, 0, 0.08, 0),
	Position = UDim2.new(0.35, 0, 0.4, 0),
	Text     = "",
	TextColor3 = C.HitGreen,
	ZIndex   = 60,
	Visible  = false,
})
local feedbackStroke = Instance.new("UIStroke")
feedbackStroke.Color        = Color3.new(0,0,0)
feedbackStroke.Thickness    = 2
feedbackStroke.Parent       = feedbackLabel

-- Level-up popup (centre screen)
local levelUpPopup = label("LevelUpPopup", gameFrame, {
	Size     = UDim2.new(0.6, 0, 0.1, 0),
	Position = UDim2.new(0.2, 0, 0.45, 0),
	Text     = "? LEVEL UP!",
	TextColor3 = C.Accent,
	ZIndex   = 65,
	Visible  = false,
})
local lvlStroke = Instance.new("UIStroke")
lvlStroke.Color     = Color3.new(0,0,0)
lvlStroke.Thickness = 3
lvlStroke.Parent    = levelUpPopup

-- ============================================================
-- RESULT / GAME OVER FRAME
-- ============================================================

local resultFrame = frame("ResultFrame", screenGui, {
	Size             = UDim2.new(0, 450, 0, 520),
	Position         = UDim2.new(0.5, -225, 0.5, -260),
	BackgroundColor3  = C.Panel,
	Visible          = false,
	ZIndex           = 70,
})
corner(resultFrame, 14)
stroke(resultFrame, C.Accent, 2, 0.4)

label("ResultTitle", resultFrame, {
	Size     = UDim2.new(0.85, 0, 0.1, 0),
	Position = UDim2.new(0.075, 0, 0.04, 0),
	Text     = "SESSION OVER",
	TextColor3 = C.Accent,
})

local statNames = {
	{ name = "ResultLevel",   text = "Level Reached: –"   },
	{ name = "ResultScore",   text = "Score: –"            },
	{ name = "ResultClicks",  text = "Clicks: –"           },
	{ name = "ResultMisses",  text = "Misses: –"           },
	{ name = "ResultCombo",   text = "Best Combo: –"       },
	{ name = "ResultXP",      text = "XP Earned: –"        },
	{ name = "ResultBestScore", text = "All-Time Best: –"  },
}

for i, s in ipairs(statNames) do
	label(s.name, resultFrame, {
		Size     = UDim2.new(0.85, 0, 0.07, 0),
		Position = UDim2.new(0.075, 0, 0.14 + (i-1) * 0.08, 0),
		Text     = s.text,
		TextColor3 = (i % 2 == 0) and C.TextDim or C.Text,
		Font     = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

button("PlayAgainButton", resultFrame, {
	Size             = UDim2.new(0.44, 0, 0.09, 0),
	Position         = UDim2.new(0.04, 0, 0.87, 0),
	BackgroundColor3  = C.Accent,
	Text             = "PLAY AGAIN",
})
button("ReturnMenuButton", resultFrame, {
	Size             = UDim2.new(0.44, 0, 0.09, 0),
	Position         = UDim2.new(0.52, 0, 0.87, 0),
	BackgroundColor3  = Color3.fromRGB(70, 65, 90),
	Text             = "MENU",
})

print("?? ClickerUIBuilder: UI constructed")