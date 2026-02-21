-- StatSheetGUI
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Read-only stat sheet showing stats, derived values, and individual stat XP progress
-- Stat allocation is admin-only via chat commands

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for stats
local stats = player:WaitForChild("Stats", 10)
local leaderstats = player:WaitForChild("leaderstats", 10)
local statProgress = player:WaitForChild("StatProgress", 10)

if not stats or not leaderstats then
	warn("Stats not found - cannot create stat sheet")
	return
end

-- Core values
local level = leaderstats:WaitForChild("Level", 5)
local xp = stats:WaitForChild("XP", 5)
local xpRequired = stats:WaitForChild("XPRequired", 5)

-- Primary stats
local strength = stats:WaitForChild("Strength", 5)
local dexterity = stats:WaitForChild("Dexterity", 5)
local constitution = stats:WaitForChild("Constitution", 5)
local intelligence = stats:WaitForChild("Intelligence", 5)

-- Derived stats
local maxHP = stats:WaitForChild("MaxHP", 5)
local currentHP = stats:WaitForChild("CurrentHP", 5)
local maxStamina = stats:WaitForChild("MaxStamina", 5)
local currentStamina = stats:WaitForChild("CurrentStamina", 5)
local speed = stats:WaitForChild("Speed", 5)
local defense = stats:WaitForChild("Defense", 5)
local spellRange = stats:WaitForChild("SpellRange", 5)
local wordCount = stats:WaitForChild("WordCount", 5)

-- Stat XP progress values
local strXP, strXPReq, dexXP, dexXPReq, conXP, conXPReq, intXP, intXPReq
if statProgress then
	strXP = statProgress:WaitForChild("StrengthXP", 5)
	strXPReq = statProgress:WaitForChild("StrengthXPRequired", 5)
	dexXP = statProgress:WaitForChild("DexterityXP", 5)
	dexXPReq = statProgress:WaitForChild("DexterityXPRequired", 5)
	conXP = statProgress:WaitForChild("ConstitutionXP", 5)
	conXPReq = statProgress:WaitForChild("ConstitutionXPRequired", 5)
	intXP = statProgress:WaitForChild("IntelligenceXP", 5)
	intXPReq = statProgress:WaitForChild("IntelligenceXPRequired", 5)
end

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local CONFIG = {
	ToggleKey = Enum.KeyCode.C,

	-- Colors
	BackgroundColor = Color3.fromRGB(20, 18, 25),
	HeaderColor = Color3.fromRGB(40, 35, 50),
	PanelColor = Color3.fromRGB(30, 27, 38),
	AccentColor = Color3.fromRGB(180, 140, 230),
	TextColor = Color3.fromRGB(220, 220, 230),
	SubTextColor = Color3.fromRGB(150, 150, 160),
	ButtonColor = Color3.fromRGB(60, 50, 80),
	ButtonHoverColor = Color3.fromRGB(80, 70, 100),

	-- Stat Colors
	StrengthColor = Color3.fromRGB(220, 80, 80),
	DexterityColor = Color3.fromRGB(80, 200, 120),
	ConstitutionColor = Color3.fromRGB(100, 150, 220),
	IntelligenceColor = Color3.fromRGB(200, 120, 220),

	-- XP Bar Colors
	StrengthXPColor = Color3.fromRGB(180, 50, 50),
	DexterityXPColor = Color3.fromRGB(50, 160, 90),
	ConstitutionXPColor = Color3.fromRGB(70, 110, 190),
	IntelligenceXPColor = Color3.fromRGB(160, 80, 190),
	XPBarBackground = Color3.fromRGB(20, 18, 28),

	PanelWidth = 480,
	PanelHeight = 650,
}

-- Level bonus per level (must match PlayerStatsManager CONFIG.LevelStatBonus)
local LEVEL_STAT_BONUS = 0.5

local function getEffectiveStatDisplay(rawValue)
	local bonus = level.Value * LEVEL_STAT_BONUS
	return (rawValue + bonus) .. " (base " .. rawValue .. ")"
end

-- ============================================================================
-- CREATE GUI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatSheetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, CONFIG.PanelWidth, 0, CONFIG.PanelHeight)
mainPanel.Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2)
mainPanel.BackgroundColor3 = CONFIG.BackgroundColor
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

local mainPanelStroke = Instance.new("UIStroke")
mainPanelStroke.Color = CONFIG.AccentColor
mainPanelStroke.Thickness = 2
mainPanelStroke.Transparency = 0.5
mainPanelStroke.Parent = mainPanel

local mainPanelCorner = Instance.new("UICorner")
mainPanelCorner.CornerRadius = UDim.new(0, 12)
mainPanelCorner.Parent = mainPanel

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 60)
header.BackgroundColor3 = CONFIG.HeaderColor
header.BorderSizePixel = 0
header.Parent = mainPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 30)
title.Position = UDim2.new(0, 15, 0, 5)
title.BackgroundTransparency = 1
title.Text = "CHARACTER STATS"
title.TextColor3 = CONFIG.AccentColor
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local levelXPText = Instance.new("TextLabel")
levelXPText.Name = "LevelXPText"
levelXPText.Size = UDim2.new(1, -70, 0, 20)
levelXPText.Position = UDim2.new(0, 15, 0, 35)
levelXPText.BackgroundTransparency = 1
levelXPText.Text = "Level " .. level.Value .. "  |  Combat XP: " .. xp.Value .. " / " .. xpRequired.Value
levelXPText.TextColor3 = CONFIG.SubTextColor
levelXPText.Font = Enum.Font.Gotham
levelXPText.TextSize = 13
levelXPText.TextXAlignment = Enum.TextXAlignment.Left
levelXPText.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 38, 0, 38)
closeButton.Position = UDim2.new(1, -48, 0, 11)
closeButton.BackgroundColor3 = CONFIG.ButtonColor
closeButton.BorderSizePixel = 0
closeButton.Text = "?"
closeButton.TextColor3 = CONFIG.TextColor
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

-- Scrollable content
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -70)
contentFrame.Position = UDim2.new(0, 10, 0, 65)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 5
contentFrame.ScrollBarImageColor3 = CONFIG.AccentColor
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 900)
contentFrame.Parent = mainPanel

-- ============================================================================
-- LEVEL BONUS NOTICE
-- ============================================================================

local bonusNotice = Instance.new("Frame")
bonusNotice.Name = "BonusNotice"
bonusNotice.Size = UDim2.new(1, 0, 0, 40)
bonusNotice.Position = UDim2.new(0, 0, 0, 0)
bonusNotice.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
bonusNotice.BorderSizePixel = 0
bonusNotice.Parent = contentFrame

local bonusCorner = Instance.new("UICorner")
bonusCorner.CornerRadius = UDim.new(0, 8)
bonusCorner.Parent = bonusNotice

local bonusText = Instance.new("TextLabel")
bonusText.Name = "BonusText"
bonusText.Size = UDim2.new(1, -15, 1, 0)
bonusText.Position = UDim2.new(0, 15, 0, 0)
bonusText.BackgroundTransparency = 1
bonusText.Text = "? Level Bonus: +" .. (level.Value * LEVEL_STAT_BONUS) .. " to all stats  |  Train minigames to raise individual stats"
bonusText.TextColor3 = CONFIG.AccentColor
bonusText.Font = Enum.Font.Gotham
bonusText.TextSize = 12
bonusText.TextXAlignment = Enum.TextXAlignment.Left
bonusText.TextWrapped = true
bonusText.Parent = bonusNotice

-- ============================================================================
-- STAT ROW WITH XP BAR (read-only, no allocation button)
-- ============================================================================

local yPos = 50

local function createStatSection(statName, statValue, xpValue, xpReqValue, color, xpBarColor, description, yPosition)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = statName .. "Row"
	rowFrame.Size = UDim2.new(1, 0, 0, 100)
	rowFrame.Position = UDim2.new(0, 0, 0, yPosition)
	rowFrame.BackgroundColor3 = CONFIG.PanelColor
	rowFrame.BorderSizePixel = 0
	rowFrame.Parent = contentFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = rowFrame

	-- Colored left accent bar
	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 4, 1, -16)
	accentBar.Position = UDim2.new(0, 0, 0, 8)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = rowFrame

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accentBar

	-- Stat name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 0, 24)
	nameLabel.Position = UDim2.new(0, 14, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = statName
	nameLabel.TextColor3 = color
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 15
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = rowFrame

	-- Raw value + effective value (top right)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.45, -10, 0, 24)
	valueLabel.Position = UDim2.new(0.55, 0, 0, 10)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = getEffectiveStatDisplay(statValue.Value)
	valueLabel.TextColor3 = CONFIG.TextColor
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 13
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = rowFrame

	-- Description
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, -18, 0, 20)
	descLabel.Position = UDim2.new(0, 14, 0, 36)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = CONFIG.SubTextColor
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = rowFrame

	-- XP Bar background
	local xpBarBG = Instance.new("Frame")
	xpBarBG.Name = "XPBarBG"
	xpBarBG.Size = UDim2.new(1, -18, 0, 14)
	xpBarBG.Position = UDim2.new(0, 14, 0, 62)
	xpBarBG.BackgroundColor3 = CONFIG.XPBarBackground
	xpBarBG.BorderSizePixel = 0
	xpBarBG.Parent = rowFrame

	local xpBarBGCorner = Instance.new("UICorner")
	xpBarBGCorner.CornerRadius = UDim.new(1, 0)
	xpBarBGCorner.Parent = xpBarBG

	-- XP Bar fill
	local xpRatio = 0
	if xpValue and xpReqValue and xpReqValue.Value > 0 then
		xpRatio = math.clamp(xpValue.Value / xpReqValue.Value, 0, 1)
	end

	local xpBarFill = Instance.new("Frame")
	xpBarFill.Name = "XPBarFill"
	xpBarFill.Size = UDim2.new(xpRatio, 0, 1, 0)
	xpBarFill.BackgroundColor3 = xpBarColor
	xpBarFill.BorderSizePixel = 0
	xpBarFill.Parent = xpBarBG

	local xpFillCorner = Instance.new("UICorner")
	xpFillCorner.CornerRadius = UDim.new(1, 0)
	xpFillCorner.Parent = xpBarFill

	-- XP Text
	local xpText = Instance.new("TextLabel")
	xpText.Name = "XPText"
	xpText.Size = UDim2.new(1, -18, 0, 14)
	xpText.Position = UDim2.new(0, 14, 0, 80)
	xpText.BackgroundTransparency = 1

	if xpValue and xpReqValue then
		xpText.Text = "Training XP: " .. xpValue.Value .. " / " .. xpReqValue.Value
	else
		xpText.Text = "Training XP: train via minigames"
	end

	xpText.TextColor3 = CONFIG.SubTextColor
	xpText.Font = Enum.Font.Gotham
	xpText.TextSize = 11
	xpText.TextXAlignment = Enum.TextXAlignment.Left
	xpText.Parent = rowFrame

	-- Connect XP bar updates
	if xpValue and xpReqValue then
		local function updateXPBar()
			local ratio = math.clamp(xpValue.Value / math.max(xpReqValue.Value, 1), 0, 1)
			TweenService:Create(xpBarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
				Size = UDim2.new(ratio, 0, 1, 0)
			}):Play()
			xpText.Text = "Training XP: " .. xpValue.Value .. " / " .. xpReqValue.Value
		end
		xpValue.Changed:Connect(updateXPBar)
		xpReqValue.Changed:Connect(updateXPBar)
	end

	-- Update value label when stat changes
	statValue.Changed:Connect(function()
		valueLabel.Text = getEffectiveStatDisplay(statValue.Value)
	end)

	return rowFrame, descLabel
end

-- ============================================================================
-- PRIMARY STATS SECTION
-- ============================================================================

local primaryTitle = Instance.new("TextLabel")
primaryTitle.Size = UDim2.new(1, 0, 0, 28)
primaryTitle.Position = UDim2.new(0, 5, 0, yPos)
primaryTitle.BackgroundTransparency = 1
primaryTitle.Text = "PRIMARY STATS"
primaryTitle.TextColor3 = CONFIG.AccentColor
primaryTitle.Font = Enum.Font.GothamBold
primaryTitle.TextSize = 14
primaryTitle.TextXAlignment = Enum.TextXAlignment.Left
primaryTitle.Parent = contentFrame
yPos = yPos + 35

local _, strDesc = createStatSection(
	"STRENGTH", strength,
	strXP, strXPReq,
	CONFIG.StrengthColor, CONFIG.StrengthXPColor,
	"Physical damage — currently " .. (5 + strength.Value * 2) .. " dmg  |  Train: Swordsmanship",
	yPos
)
yPos = yPos + 110

local _, dexDesc = createStatSection(
	"DEXTERITY", dexterity,
	dexXP, dexXPReq,
	CONFIG.DexterityColor, CONFIG.DexterityXPColor,
	"Movement speed — currently " .. math.floor(speed.Value) .. " speed  |  Train: Clicker",
	yPos
)
yPos = yPos + 110

local _, conDesc = createStatSection(
	"CONSTITUTION", constitution,
	conXP, conXPReq,
	CONFIG.ConstitutionColor, CONFIG.ConstitutionXPColor,
	"HP & Stamina — currently " .. math.floor(maxHP.Value) .. " HP, " .. math.floor(maxStamina.Value) .. " STA  |  Train: Endurance",
	yPos
)
yPos = yPos + 110

local _, intDesc = createStatSection(
	"INTELLIGENCE", intelligence,
	intXP, intXPReq,
	CONFIG.IntelligenceColor, CONFIG.IntelligenceXPColor,
	"Spell range & words — currently " .. spellRange.Value .. " range, " .. wordCount.Value .. " words  |  Train: Meditation",
	yPos
)
yPos = yPos + 110

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, yPos)
divider.BackgroundColor3 = CONFIG.HeaderColor
divider.BorderSizePixel = 0
divider.Parent = contentFrame
yPos = yPos + 15

-- ============================================================================
-- DERIVED STATS (read-only display)
-- ============================================================================

local derivedTitle = Instance.new("TextLabel")
derivedTitle.Size = UDim2.new(1, 0, 0, 28)
derivedTitle.Position = UDim2.new(0, 5, 0, yPos)
derivedTitle.BackgroundTransparency = 1
derivedTitle.Text = "DERIVED STATS"
derivedTitle.TextColor3 = CONFIG.AccentColor
derivedTitle.Font = Enum.Font.GothamBold
derivedTitle.TextSize = 14
derivedTitle.TextXAlignment = Enum.TextXAlignment.Left
derivedTitle.Parent = contentFrame
yPos = yPos + 35

local function createDerivedRow(name, valueGetter, yPosition)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 32)
	row.Position = UDim2.new(0, 0, 0, yPosition)
	row.BackgroundTransparency = 1
	row.Parent = contentFrame

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size = UDim2.new(0.55, 0, 1, 0)
	nameLbl.Position = UDim2.new(0, 10, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = name
	nameLbl.TextColor3 = CONFIG.SubTextColor
	nameLbl.Font = Enum.Font.Gotham
	nameLbl.TextSize = 13
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Name = "ValueLabel"
	valLbl.Size = UDim2.new(0.45, -10, 1, 0)
	valLbl.Position = UDim2.new(0.55, 0, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Text = valueGetter()
	valLbl.TextColor3 = CONFIG.TextColor
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextSize = 13
	valLbl.TextXAlignment = Enum.TextXAlignment.Right
	valLbl.Parent = row

	return row, valLbl
end

local _, physDmgLabel = createDerivedRow("Physical Damage", function()
	return tostring(5 + strength.Value * 2)
end, yPos)
yPos = yPos + 32

local _, speedLabel = createDerivedRow("Speed", function()
	return math.floor(speed.Value) .. " / 80"
end, yPos)
yPos = yPos + 32

local _, defLabel = createDerivedRow("Defense", function()
	return tostring(defense.Value)
end, yPos)
yPos = yPos + 32

local _, rangeLabel = createDerivedRow("Spell Range", function()
	return tostring(spellRange.Value) .. " studs"
end, yPos)
yPos = yPos + 32

local _, wordsLabel = createDerivedRow("Spell Words", function()
	return tostring(wordCount.Value) .. " words"
end, yPos)
yPos = yPos + 40

-- Update canvas height
contentFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================================================
-- UPDATE LISTENERS
-- ============================================================================

local function refreshAll()
	local strRow = contentFrame:FindFirstChild("STRENGTHRow")
	local dexRow = contentFrame:FindFirstChild("DEXTERITYRow")
	local conRow = contentFrame:FindFirstChild("CONSTITUTIONRow")
	local intRow = contentFrame:FindFirstChild("INTELLIGENCERow")

	if strRow then strRow:FindFirstChild("ValueLabel").Text = getEffectiveStatDisplay(strength.Value) end
	if dexRow then dexRow:FindFirstChild("ValueLabel").Text = getEffectiveStatDisplay(dexterity.Value) end
	if conRow then conRow:FindFirstChild("ValueLabel").Text = getEffectiveStatDisplay(constitution.Value) end
	if intRow then intRow:FindFirstChild("ValueLabel").Text = getEffectiveStatDisplay(intelligence.Value) end
	physDmgLabel.Text = tostring(5 + strength.Value * 2)
	speedLabel.Text = math.floor(speed.Value) .. " / 80"
	defLabel.Text = tostring(defense.Value)
	rangeLabel.Text = tostring(spellRange.Value) .. " studs"
	wordsLabel.Text = tostring(wordCount.Value) .. " words"

	strDesc.Text = "Physical damage — currently " .. (5 + strength.Value * 2) .. " dmg  |  Train: Swordsmanship"
	dexDesc.Text = "Movement speed — currently " .. math.floor(speed.Value) .. " speed  |  Train: Clicker"
	conDesc.Text = "HP & Stamina — currently " .. math.floor(maxHP.Value) .. " HP, " .. math.floor(maxStamina.Value) .. " STA  |  Train: Endurance"
	intDesc.Text = "Spell range & words — currently " .. spellRange.Value .. " range, " .. wordCount.Value .. " words  |  Train: Meditation"

	bonusText.Text = "? Level Bonus: +" .. (level.Value * LEVEL_STAT_BONUS) .. " to all stats  |  Train minigames to raise individual stats"
	levelXPText.Text = "Level " .. level.Value .. "  |  Combat XP: " .. xp.Value .. " / " .. xpRequired.Value
end

strength.Changed:Connect(refreshAll)
dexterity.Changed:Connect(refreshAll)
constitution.Changed:Connect(refreshAll)
intelligence.Changed:Connect(refreshAll)
speed.Changed:Connect(refreshAll)
defense.Changed:Connect(refreshAll)
spellRange.Changed:Connect(refreshAll)
wordCount.Changed:Connect(refreshAll)
maxHP.Changed:Connect(refreshAll)
maxStamina.Changed:Connect(refreshAll)
level.Changed:Connect(refreshAll)
xp.Changed:Connect(refreshAll)
xpRequired.Changed:Connect(refreshAll)

-- ============================================================================
-- TOGGLE
-- ============================================================================

local isOpen = false

local function togglePanel()
	isOpen = not isOpen
	mainPanel.Visible = isOpen

	if isOpen then
		if _G.HideHUD then _G.HideHUD() end
		mainPanel.Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2 - 15)
		TweenService:Create(mainPanel, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2)
		}):Play()
	else
		if _G.ShowHUD then _G.ShowHUD() end
	end
end

closeButton.MouseButton1Click:Connect(togglePanel)

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.ButtonHoverColor}):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.ButtonColor}):Play()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == CONFIG.ToggleKey then
		togglePanel()
	end
end)

print("? Stat Sheet GUI loaded! Press 'C' to open/close")
print("  Showing stat XP progress bars — stats raised by minigame training")