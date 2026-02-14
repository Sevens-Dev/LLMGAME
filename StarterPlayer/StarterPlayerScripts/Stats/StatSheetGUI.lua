-- StatSheetGUI
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Creates a detailed stat sheet with allocation buttons

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for stats
local stats = player:WaitForChild("Stats", 10)
local leaderstats = player:WaitForChild("leaderstats", 10)

if not stats or not leaderstats then
	warn("Stats not found - cannot create stat sheet")
	return
end

-- Wait for StatRemote
local statRemote = ReplicatedStorage:WaitForChild("StatRemote", 10)
if not statRemote then
	warn("StatRemote not found")
	return
end

-- Get all stat values
local level = leaderstats:WaitForChild("Level", 5)
local xp = stats:WaitForChild("XP", 5)
local xpRequired = stats:WaitForChild("XPRequired", 5)

-- Primary Stats
local strength = stats:WaitForChild("Strength", 5)
local dexterity = stats:WaitForChild("Dexterity", 5)
local constitution = stats:WaitForChild("Constitution", 5)
local intelligence = stats:WaitForChild("Intelligence", 5)
local statPoints = stats:WaitForChild("StatPoints", 5)

-- Derived Stats
local maxHP = stats:WaitForChild("MaxHP", 5)
local currentHP = stats:WaitForChild("CurrentHP", 5)
local maxStamina = stats:WaitForChild("MaxStamina", 5)
local currentStamina = stats:WaitForChild("CurrentStamina", 5)
local speed = stats:WaitForChild("Speed", 5)
local defense = stats:WaitForChild("Defense", 5)
local spellRange = stats:WaitForChild("SpellRange", 5)
local wordCount = stats:WaitForChild("WordCount", 5)

-- ============================================================================
-- CONFIGURATION
-- ============================================================================
local CONFIG = {
	-- Toggle Key
	ToggleKey = Enum.KeyCode.C, -- Press 'C' to open/close

	-- Colors - Dark fantasy RPG theme
	BackgroundColor = Color3.fromRGB(20, 18, 25),
	HeaderColor = Color3.fromRGB(40, 35, 50),
	PanelColor = Color3.fromRGB(30, 27, 38),
	AccentColor = Color3.fromRGB(180, 140, 230), -- Purple accent
	TextColor = Color3.fromRGB(220, 220, 230),
	SubTextColor = Color3.fromRGB(150, 150, 160),
	ButtonColor = Color3.fromRGB(60, 50, 80),
	ButtonHoverColor = Color3.fromRGB(80, 70, 100),

	-- Stat Colors
	StrengthColor = Color3.fromRGB(220, 80, 80), -- Red
	DexterityColor = Color3.fromRGB(80, 200, 120), -- Green
	ConstitutionColor = Color3.fromRGB(100, 150, 220), -- Blue
	IntelligenceColor = Color3.fromRGB(200, 120, 220), -- Purple

	-- Sizes
	PanelWidth = 450,
	PanelHeight = 600,
}

-- ============================================================================
-- CREATE GUI STRUCTURE
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatSheetGUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Main Panel (hidden by default)
local mainPanel = Instance.new("Frame")
mainPanel.Name = "MainPanel"
mainPanel.Size = UDim2.new(0, CONFIG.PanelWidth, 0, CONFIG.PanelHeight)
mainPanel.Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2)
mainPanel.BackgroundColor3 = CONFIG.BackgroundColor
mainPanel.BorderSizePixel = 0
mainPanel.Visible = false
mainPanel.Parent = screenGui

-- Add subtle border glow
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
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = CONFIG.HeaderColor
header.BorderSizePixel = 0
header.Parent = mainPanel

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -20, 0, 30)
title.Position = UDim2.new(0, 10, 0, 5)
title.BackgroundTransparency = 1
title.Text = "CHARACTER STATS"
title.TextColor3 = CONFIG.AccentColor
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Level & XP Display
local levelXPText = Instance.new("TextLabel")
levelXPText.Name = "LevelXPText"
levelXPText.Size = UDim2.new(1, -20, 0, 20)
levelXPText.Position = UDim2.new(0, 10, 0, 35)
levelXPText.BackgroundTransparency = 1
levelXPText.Text = "Level " .. level.Value .. " | " .. xp.Value .. "/" .. xpRequired.Value .. " XP"
levelXPText.TextColor3 = CONFIG.SubTextColor
levelXPText.Font = Enum.Font.Gotham
levelXPText.TextSize = 14
levelXPText.TextXAlignment = Enum.TextXAlignment.Left
levelXPText.Parent = header

-- Close Button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 10)
closeButton.BackgroundColor3 = CONFIG.ButtonColor
closeButton.BorderSizePixel = 0
closeButton.Text = "X"
closeButton.TextColor3 = CONFIG.TextColor
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 20
closeButton.Parent = header

local closeButtonCorner = Instance.new("UICorner")
closeButtonCorner.CornerRadius = UDim.new(0, 8)
closeButtonCorner.Parent = closeButton

-- Content Area (scrolling)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -80)
contentFrame.Position = UDim2.new(0, 10, 0, 70)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 6
contentFrame.ScrollBarImageColor3 = CONFIG.AccentColor
contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800) -- Will adjust dynamically
contentFrame.Parent = mainPanel

-- Stat Points Display (prominent)
local statPointsPanel = Instance.new("Frame")
statPointsPanel.Name = "StatPointsPanel"
statPointsPanel.Size = UDim2.new(1, 0, 0, 70)
statPointsPanel.Position = UDim2.new(0, 0, 0, 0)
statPointsPanel.BackgroundColor3 = CONFIG.PanelColor
statPointsPanel.BorderSizePixel = 0
statPointsPanel.Parent = contentFrame

local statPointsPanelCorner = Instance.new("UICorner")
statPointsPanelCorner.CornerRadius = UDim.new(0, 8)
statPointsPanelCorner.Parent = statPointsPanel

local statPointsLabel = Instance.new("TextLabel")
statPointsLabel.Size = UDim2.new(1, -20, 0, 25)
statPointsLabel.Position = UDim2.new(0, 10, 0, 10)
statPointsLabel.BackgroundTransparency = 1
statPointsLabel.Text = "Available Stat Points"
statPointsLabel.TextColor3 = CONFIG.SubTextColor
statPointsLabel.Font = Enum.Font.Gotham
statPointsLabel.TextSize = 14
statPointsLabel.TextXAlignment = Enum.TextXAlignment.Left
statPointsLabel.Parent = statPointsPanel

local statPointsValue = Instance.new("TextLabel")
statPointsValue.Name = "StatPointsValue"
statPointsValue.Size = UDim2.new(1, -20, 0, 35)
statPointsValue.Position = UDim2.new(0, 10, 0, 30)
statPointsValue.BackgroundTransparency = 1
statPointsValue.Text = tostring(statPoints.Value)
statPointsValue.TextColor3 = CONFIG.AccentColor
statPointsValue.Font = Enum.Font.GothamBold
statPointsValue.TextSize = 28
statPointsValue.TextXAlignment = Enum.TextXAlignment.Left
statPointsValue.Parent = statPointsPanel

-- ============================================================================
-- STAT ROW CREATION FUNCTION
-- ============================================================================

local yPos = 90 -- Starting Y position (after stat points panel)

local function createStatRow(statName, statValue, color, description, yPosition)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = statName .. "Row"
	rowFrame.Size = UDim2.new(1, 0, 0, 90)
	rowFrame.Position = UDim2.new(0, 0, 0, yPosition)
	rowFrame.BackgroundColor3 = CONFIG.PanelColor
	rowFrame.BorderSizePixel = 0
	rowFrame.Parent = contentFrame

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = rowFrame

	-- Stat name (top left)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.6, 0, 0, 25)
	nameLabel.Position = UDim2.new(0, 10, 0, 10)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = statName
	nameLabel.TextColor3 = color
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = rowFrame

	-- Current value (top right)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.4, -10, 0, 25)
	valueLabel.Position = UDim2.new(0.6, 0, 0, 10)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(statValue.Value)
	valueLabel.TextColor3 = CONFIG.TextColor
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 20
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = rowFrame

	-- Description (below name)
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 25)
	descLabel.Position = UDim2.new(0, 10, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = CONFIG.SubTextColor
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 12
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = rowFrame

	-- Add button (bottom right)
	local addButton = Instance.new("TextButton")
	addButton.Name = "AddButton"
	addButton.Size = UDim2.new(0, 80, 0, 30)
	addButton.Position = UDim2.new(1, -90, 1, -38)
	addButton.BackgroundColor3 = CONFIG.ButtonColor
	addButton.BorderSizePixel = 0
	addButton.Text = "+ Add"
	addButton.TextColor3 = CONFIG.TextColor
	addButton.Font = Enum.Font.GothamBold
	addButton.TextSize = 14
	addButton.Parent = rowFrame

	local addButtonCorner = Instance.new("UICorner")
	addButtonCorner.CornerRadius = UDim.new(0, 6)
	addButtonCorner.Parent = addButton

	-- Button hover effects
	addButton.MouseEnter:Connect(function()
		if statPoints.Value > 0 then
			TweenService:Create(addButton, TweenInfo.new(0.1), {
				BackgroundColor3 = CONFIG.ButtonHoverColor
			}):Play()
		end
	end)

	addButton.MouseLeave:Connect(function()
		TweenService:Create(addButton, TweenInfo.new(0.1), {
			BackgroundColor3 = CONFIG.ButtonColor
		}):Play()
	end)

	-- Button click handler
	addButton.MouseButton1Click:Connect(function()
		if statPoints.Value > 0 then
			-- Visual feedback
			local originalSize = addButton.Size
			TweenService:Create(addButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 75, 0, 28)
			}):Play()
			task.wait(0.1)
			TweenService:Create(addButton, TweenInfo.new(0.1), {
				Size = originalSize
			}):Play()

			-- Send request to server with proper command format
			-- Convert "STRENGTH" to "AddStrength", "DEXTERITY" to "AddDexterity", etc.
			local commandName = "Add" .. statName:sub(1,1) .. statName:sub(2):lower()
			statRemote:FireServer(commandName, 1)
		end
	end)

	-- Update button state when stat points change
	statPoints.Changed:Connect(function()
		if statPoints.Value > 0 then
			addButton.BackgroundColor3 = CONFIG.ButtonColor
			addButton.TextTransparency = 0
		else
			addButton.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
			addButton.TextTransparency = 0.5
		end
	end)

	-- Initialize button state
	if statPoints.Value <= 0 then
		addButton.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
		addButton.TextTransparency = 0.5
	end

	-- Update value when stat changes
	statValue.Changed:Connect(function()
		valueLabel.Text = tostring(statValue.Value)
	end)

	return rowFrame, valueLabel, descLabel
end

-- ============================================================================
-- PRIMARY STATS
-- ============================================================================

local primaryStatsTitle = Instance.new("TextLabel")
primaryStatsTitle.Size = UDim2.new(1, 0, 0, 30)
primaryStatsTitle.Position = UDim2.new(0, 0, 0, yPos)
primaryStatsTitle.BackgroundTransparency = 1
primaryStatsTitle.Text = "PRIMARY STATS"
primaryStatsTitle.TextColor3 = CONFIG.AccentColor
primaryStatsTitle.Font = Enum.Font.GothamBold
primaryStatsTitle.TextSize = 16
primaryStatsTitle.TextXAlignment = Enum.TextXAlignment.Left
primaryStatsTitle.Parent = contentFrame
yPos = yPos + 40

-- Create stat rows
local _, strValueLabel, strDescLabel = createStatRow(
	"STRENGTH",
	strength,
	CONFIG.StrengthColor,
	"Physical damage - Currently: " .. (5 + strength.Value * 2) .. " damage",
	yPos
)
yPos = yPos + 100

local _, dexValueLabel, dexDescLabel = createStatRow(
	"DEXTERITY",
	dexterity,
	CONFIG.DexterityColor,
	"Movement speed - Currently: " .. math.floor(speed.Value) .. " speed",
	yPos
)
yPos = yPos + 100

local _, conValueLabel, conDescLabel = createStatRow(
	"CONSTITUTION",
	constitution,
	CONFIG.ConstitutionColor,
	"HP and Stamina - Currently: " .. math.floor(maxHP.Value) .. " HP, " .. math.floor(maxStamina.Value) .. " STA",
	yPos
)
yPos = yPos + 100

local _, intValueLabel, intDescLabel = createStatRow(
	"INTELLIGENCE",
	intelligence,
	CONFIG.IntelligenceColor,
	"Spell range & words - Currently: " .. spellRange.Value .. " range, " .. wordCount.Value .. " words",
	yPos
)
yPos = yPos + 100

-- Divider
local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 2)
divider.Position = UDim2.new(0, 0, 0, yPos)
divider.BackgroundColor3 = CONFIG.HeaderColor
divider.BorderSizePixel = 0
divider.Parent = contentFrame
yPos = yPos + 20

-- ============================================================================
-- DERIVED STATS DISPLAY (Read-only)
-- ============================================================================

local derivedStatsTitle = Instance.new("TextLabel")
derivedStatsTitle.Size = UDim2.new(1, 0, 0, 30)
derivedStatsTitle.Position = UDim2.new(0, 0, 0, yPos)
derivedStatsTitle.BackgroundTransparency = 1
derivedStatsTitle.Text = "DERIVED STATS"
derivedStatsTitle.TextColor3 = CONFIG.AccentColor
derivedStatsTitle.Font = Enum.Font.GothamBold
derivedStatsTitle.TextSize = 16
derivedStatsTitle.TextXAlignment = Enum.TextXAlignment.Left
derivedStatsTitle.Parent = contentFrame
yPos = yPos + 40

local function createDerivedStatRow(name, valueGetter, yPosition)
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = name .. "DerivedRow"
	rowFrame.Size = UDim2.new(1, 0, 0, 35)
	rowFrame.Position = UDim2.new(0, 0, 0, yPosition)
	rowFrame.BackgroundTransparency = 1
	rowFrame.Parent = contentFrame

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.Position = UDim2.new(0, 10, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = CONFIG.SubTextColor
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = rowFrame

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(0.5, -10, 1, 0)
	valueLabel.Position = UDim2.new(0.5, 0, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = valueGetter()
	valueLabel.TextColor3 = CONFIG.TextColor
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextSize = 14
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Parent = rowFrame

	return rowFrame, valueLabel
end

local _, physDamageLabel = createDerivedStatRow("Physical Damage", function()
	return tostring(5 + strength.Value * 2)
end, yPos)
yPos = yPos + 35

local _, speedLabel = createDerivedStatRow("Speed", function()
	return math.floor(speed.Value) .. " / 80"
end, yPos)
yPos = yPos + 35

local _, defenseLabel = createDerivedStatRow("Defense", function()
	return tostring(defense.Value)
end, yPos)
yPos = yPos + 35

local _, spellRangeLabel = createDerivedStatRow("Spell Range", function()
	return tostring(spellRange.Value) .. " studs"
end, yPos)
yPos = yPos + 35

local _, wordCountLabel = createDerivedStatRow("Spell Words", function()
	return tostring(wordCount.Value) .. " words"
end, yPos)
yPos = yPos + 35

-- Update canvas size
contentFrame.CanvasSize = UDim2.new(0, 0, 0, yPos + 20)

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================

local function updateDerivedStats()
	-- Update derived stat labels
	physDamageLabel.Text = tostring(5 + strength.Value * 2)
	speedLabel.Text = math.floor(speed.Value) .. " / 80"
	defenseLabel.Text = tostring(defense.Value)
	spellRangeLabel.Text = tostring(spellRange.Value) .. " studs"
	wordCountLabel.Text = tostring(wordCount.Value) .. " words"

	-- Update descriptions in primary stat rows
	strDescLabel.Text = "Physical damage - Currently: " .. (5 + strength.Value * 2) .. " damage"
	dexDescLabel.Text = "Movement speed - Currently: " .. math.floor(speed.Value) .. " speed"
	conDescLabel.Text = "HP and Stamina - Currently: " .. math.floor(maxHP.Value) .. " HP, " .. math.floor(maxStamina.Value) .. " STA"
	intDescLabel.Text = "Spell range & words - Currently: " .. spellRange.Value .. " range, " .. wordCount.Value .. " words"
end

-- Connect to stat changes
strength.Changed:Connect(updateDerivedStats)
dexterity.Changed:Connect(updateDerivedStats)
constitution.Changed:Connect(updateDerivedStats)
intelligence.Changed:Connect(updateDerivedStats)
speed.Changed:Connect(updateDerivedStats)
defense.Changed:Connect(updateDerivedStats)
spellRange.Changed:Connect(updateDerivedStats)
wordCount.Changed:Connect(updateDerivedStats)
maxHP.Changed:Connect(updateDerivedStats)
maxStamina.Changed:Connect(updateDerivedStats)

statPoints.Changed:Connect(function()
	statPointsValue.Text = tostring(statPoints.Value)
end)

level.Changed:Connect(function()
	levelXPText.Text = "Level " .. level.Value .. " | " .. xp.Value .. "/" .. xpRequired.Value .. " XP"
end)

xp.Changed:Connect(function()
	levelXPText.Text = "Level " .. level.Value .. " | " .. xp.Value .. "/" .. xpRequired.Value .. " XP"
end)

xpRequired.Changed:Connect(function()
	levelXPText.Text = "Level " .. level.Value .. " | " .. xp.Value .. "/" .. xpRequired.Value .. " XP"
end)

-- ============================================================================
-- TOGGLE FUNCTIONALITY
-- ============================================================================

local isOpen = false

local function togglePanel()
	isOpen = not isOpen
	mainPanel.Visible = isOpen

	if isOpen then
		-- Fade in animation
		mainPanel.GroupTransparency = 1
		mainPanel.Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2 - 20)

		local tween = TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			GroupTransparency = 0,
			Position = UDim2.new(0.5, -CONFIG.PanelWidth/2, 0.5, -CONFIG.PanelHeight/2)
		})
		tween:Play()
	end
end

-- Close button
closeButton.MouseButton1Click:Connect(togglePanel)

-- Close button hover
closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.ButtonHoverColor}):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.1), {BackgroundColor3 = CONFIG.ButtonColor}):Play()
end)

-- Keyboard toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == CONFIG.ToggleKey then
		togglePanel()
	end
end)

print("✓ Stat Sheet GUI loaded! Press 'C' to open/close")