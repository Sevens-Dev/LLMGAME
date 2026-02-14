-- HealthStaminaGUI
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Creates and manages HP and Stamina bars

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for stats
local stats = player:WaitForChild("Stats", 10)
if not stats then
	warn("Stats not found - cannot create HP/Stamina bars")
	return
end

local maxHP = stats:WaitForChild("MaxHP", 5)
local currentHP = stats:WaitForChild("CurrentHP", 5)
local maxStamina = stats:WaitForChild("MaxStamina", 5)
local currentStamina = stats:WaitForChild("CurrentStamina", 5)

if not (maxHP and currentHP and maxStamina and currentStamina) then
	warn("HP/Stamina values not found")
	return
end

-- ============================================================================
-- CONFIGURATION - Edit these to customize the appearance
-- ============================================================================
local CONFIG = {
	-- Bar Positioning
	PositionFromBottom = 50, -- Pixels from bottom of screen
	BarWidth = 300, -- Width of bars
	BarHeight = 25, -- Height of each bar
	BarSpacing = 10, -- Space between HP and Stamina bars

	-- Colors
	HPColor = Color3.fromRGB(220, 50, 50), -- Red for HP
	HPBackgroundColor = Color3.fromRGB(80, 20, 20), -- Dark red background
	StaminaColor = Color3.fromRGB(255, 200, 50), -- Yellow/Gold for Stamina
	StaminaBackgroundColor = Color3.fromRGB(100, 80, 20), -- Dark yellow background
	BorderColor = Color3.fromRGB(0, 0, 0), -- Black border

	-- Text
	ShowText = true, -- Show "100/150" text on bars
	TextColor = Color3.fromRGB(255, 255, 255), -- White text
	FontSize = 18,

	-- Animation
	AnimationSpeed = 0.2, -- How fast bars fill/drain (in seconds)
}

-- ============================================================================
-- CREATE GUI
-- ============================================================================

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HealthStaminaBars"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Container frame to hold both bars
local container = Instance.new("Frame")
container.Name = "Container"
container.Size = UDim2.new(0, CONFIG.BarWidth, 0, (CONFIG.BarHeight * 2) + CONFIG.BarSpacing)
container.Position = UDim2.new(0.5, -CONFIG.BarWidth/2, 1, -CONFIG.PositionFromBottom - (CONFIG.BarHeight * 2) - CONFIG.BarSpacing)
container.BackgroundTransparency = 1
container.Parent = screenGui

-- ============================================================================
-- HP BAR
-- ============================================================================

-- HP Background
local hpBackground = Instance.new("Frame")
hpBackground.Name = "HPBackground"
hpBackground.Size = UDim2.new(1, 0, 0, CONFIG.BarHeight)
hpBackground.Position = UDim2.new(0, 0, 0, 0)
hpBackground.BackgroundColor3 = CONFIG.HPBackgroundColor
hpBackground.BorderColor3 = CONFIG.BorderColor
hpBackground.BorderSizePixel = 2
hpBackground.Parent = container

-- HP Bar (fills based on current HP)
local hpBar = Instance.new("Frame")
hpBar.Name = "HPBar"
hpBar.Size = UDim2.new(currentHP.Value / maxHP.Value, 0, 1, 0)
hpBar.Position = UDim2.new(0, 0, 0, 0)
hpBar.BackgroundColor3 = CONFIG.HPColor
hpBar.BorderSizePixel = 0
hpBar.Parent = hpBackground

-- HP Text
local hpText = Instance.new("TextLabel")
hpText.Name = "HPText"
hpText.Size = UDim2.new(1, 0, 1, 0)
hpText.Position = UDim2.new(0, 0, 0, 0)
hpText.BackgroundTransparency = 1
hpText.Text = math.floor(currentHP.Value) .. " / " .. math.floor(maxHP.Value)
hpText.TextColor3 = CONFIG.TextColor
hpText.Font = Enum.Font.SourceSansBold
hpText.TextSize = CONFIG.FontSize
hpText.TextStrokeTransparency = 0.5
hpText.ZIndex = 2
hpText.Visible = CONFIG.ShowText
hpText.Parent = hpBackground

-- HP Icon/Label
local hpLabel = Instance.new("TextLabel")
hpLabel.Name = "HPLabel"
hpLabel.Size = UDim2.new(0, 60, 1, 0)
hpLabel.Position = UDim2.new(0, -65, 0, 0)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "HP"
hpLabel.TextColor3 = CONFIG.HPColor
hpLabel.Font = Enum.Font.SourceSansBold
hpLabel.TextSize = CONFIG.FontSize
hpLabel.TextXAlignment = Enum.TextXAlignment.Right
hpLabel.Parent = hpBackground

-- ============================================================================
-- STAMINA BAR
-- ============================================================================

-- Stamina Background
local staminaBackground = Instance.new("Frame")
staminaBackground.Name = "StaminaBackground"
staminaBackground.Size = UDim2.new(1, 0, 0, CONFIG.BarHeight)
staminaBackground.Position = UDim2.new(0, 0, 0, CONFIG.BarHeight + CONFIG.BarSpacing)
staminaBackground.BackgroundColor3 = CONFIG.StaminaBackgroundColor
staminaBackground.BorderColor3 = CONFIG.BorderColor
staminaBackground.BorderSizePixel = 2
staminaBackground.Parent = container

-- Stamina Bar
local staminaBar = Instance.new("Frame")
staminaBar.Name = "StaminaBar"
staminaBar.Size = UDim2.new(currentStamina.Value / maxStamina.Value, 0, 1, 0)
staminaBar.Position = UDim2.new(0, 0, 0, 0)
staminaBar.BackgroundColor3 = CONFIG.StaminaColor
staminaBar.BorderSizePixel = 0
staminaBar.Parent = staminaBackground

-- Stamina Text
local staminaText = Instance.new("TextLabel")
staminaText.Name = "StaminaText"
staminaText.Size = UDim2.new(1, 0, 1, 0)
staminaText.Position = UDim2.new(0, 0, 0, 0)
staminaText.BackgroundTransparency = 1
staminaText.Text = math.floor(currentStamina.Value) .. " / " .. math.floor(maxStamina.Value)
staminaText.TextColor3 = CONFIG.TextColor
staminaText.Font = Enum.Font.SourceSansBold
staminaText.TextSize = CONFIG.FontSize
staminaText.TextStrokeTransparency = 0.5
staminaText.ZIndex = 2
staminaText.Visible = CONFIG.ShowText
staminaText.Parent = staminaBackground

-- Stamina Icon/Label
local staminaLabel = Instance.new("TextLabel")
staminaLabel.Name = "StaminaLabel"
staminaLabel.Size = UDim2.new(0, 60, 1, 0)
staminaLabel.Position = UDim2.new(0, -65, 0, 0)
staminaLabel.BackgroundTransparency = 1
staminaLabel.Text = "STA"
staminaLabel.TextColor3 = CONFIG.StaminaColor
staminaLabel.Font = Enum.Font.SourceSansBold
staminaLabel.TextSize = CONFIG.FontSize
staminaLabel.TextXAlignment = Enum.TextXAlignment.Right
staminaLabel.Parent = staminaBackground

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================

local TweenService = game:GetService("TweenService")

local function updateHPBar()
	local ratio = math.clamp(currentHP.Value / maxHP.Value, 0, 1)

	-- Animate bar size
	local tweenInfo = TweenInfo.new(CONFIG.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(hpBar, tweenInfo, {
		Size = UDim2.new(ratio, 0, 1, 0)
	})
	tween:Play()

	-- Update text
	hpText.Text = math.floor(currentHP.Value) .. " / " .. math.floor(maxHP.Value)

	-- Flash red if taking damage
	if ratio < 0.3 then
		hpBar.BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Lighter red when low
	else
		hpBar.BackgroundColor3 = CONFIG.HPColor
	end
end

local function updateStaminaBar()
	local ratio = math.clamp(currentStamina.Value / maxStamina.Value, 0, 1)

	-- Animate bar size
	local tweenInfo = TweenInfo.new(CONFIG.AnimationSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(staminaBar, tweenInfo, {
		Size = UDim2.new(ratio, 0, 1, 0)
	})
	tween:Play()

	-- Update text
	staminaText.Text = math.floor(currentStamina.Value) .. " / " .. math.floor(maxStamina.Value)

	-- Dim color when low
	if ratio < 0.3 then
		staminaBar.BackgroundColor3 = Color3.fromRGB(180, 140, 40) -- Darker yellow when low
	else
		staminaBar.BackgroundColor3 = CONFIG.StaminaColor
	end
end

local function updateMaxValues()
	-- Update text to show new max values
	hpText.Text = math.floor(currentHP.Value) .. " / " .. math.floor(maxHP.Value)
	staminaText.Text = math.floor(currentStamina.Value) .. " / " .. math.floor(maxStamina.Value)

	-- Recalculate ratios
	updateHPBar()
	updateStaminaBar()
end

-- ============================================================================
-- CONNECT TO STAT CHANGES
-- ============================================================================

currentHP.Changed:Connect(updateHPBar)
maxHP.Changed:Connect(updateMaxValues)

currentStamina.Changed:Connect(updateStaminaBar)
maxStamina.Changed:Connect(updateMaxValues)

-- Initial update
updateHPBar()
updateStaminaBar()

print("✓ Health and Stamina bars created!")