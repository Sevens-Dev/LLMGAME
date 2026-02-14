--[[
	MeditationUIBuilder.lua (StarterGui - LocalScript)
	Builds the meditation and martial arts themed interface
--]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MeditationUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Meditation colors
local Colors = {
	Background = Color3.fromRGB(15, 15, 20),
	Temple = Color3.fromRGB(30, 25, 35),
	Stone = Color3.fromRGB(40, 40, 50),
	Chi = Color3.fromRGB(150, 200, 255),
	Gold = Color3.fromRGB(255, 215, 100),
	Text = Color3.fromRGB(240, 240, 250),
	TextDim = Color3.fromRGB(180, 180, 200),
	Accent = Color3.fromRGB(150, 200, 255)
}

-- Helper functions
local function createFrame(name: string, parent: Instance, properties: {[string]: any}): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = parent

	for prop, value in pairs(properties) do
		frame[prop] = value
	end

	return frame
end

local function createTextLabel(name: string, parent: Instance, properties: {[string]: any}): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Colors.Text

	for prop, value in pairs(properties) do
		label[prop] = value
	end

	return label
end

local function createTextButton(name: string, parent: Instance, properties: {[string]: any}): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.Parent = parent
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Colors.Text
	button.BorderSizePixel = 0
	button.AutoButtonColor = true

	for prop, value in pairs(properties) do
		button[prop] = value
	end

	-- Zen corner rounding
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = button

	-- Subtle glow on buttons
	local glow = Instance.new("UIStroke")
	glow.Color = Colors.Chi
	glow.Thickness = 1
	glow.Transparency = 0.7
	glow.Parent = button

	return button
end

local function addZenDecoration(parent: Instance)
	-- Subtle gradient overlay
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))
	}
	gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.95),
		NumberSequenceKeypoint.new(1, 0.85)
	}
	gradient.Rotation = 45
	gradient.Parent = parent
end

-- ============================================
-- MEDITATION OPEN BUTTON (Top right corner)
-- ============================================
local openButton = createTextButton("OpenMeditationButton", screenGui, {
	Size = UDim2.new(0, 140, 0, 50),
	Position = UDim2.new(1, -150, 0, 10),
	Text = "🧘 Meditate",
	TextScaled = false,
	TextSize = 20,
	BackgroundColor3 = Colors.Chi,
	ZIndex = 100
})

-- ============================================
-- MENU FRAME - Temple Entrance (Smaller, centered)
-- ============================================
local menuFrame = createFrame("MenuFrame", screenGui, {
	Size = UDim2.new(0, 400, 0, 500),
	Position = UDim2.new(0.5, -200, 0.5, -250),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0, -- Fully opaque
	Visible = false -- Start hidden
})

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0.04, 0)
menuCorner.Parent = menuFrame

-- Drag handle indicator
local dragHandle = createTextLabel("DragHandle", menuFrame, {
	Size = UDim2.new(0.3, 0, 0.04, 0),
	Position = UDim2.new(0.35, 0, 0.01, 0),
	Text = "⋮⋮⋮",
	TextScaled = true,
	TextColor3 = Color3.fromRGB(120, 120, 140),
	Font = Enum.Font.GothamBold
})

-- Add dark border for better contrast
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(100, 150, 200)
menuStroke.Thickness = 2
menuStroke.Parent = menuFrame

-- Don't add zen decoration - it adds transparency
-- addZenDecoration(menuFrame)

-- Title with zen symbol
local titleLabel = createTextLabel("TitleLabel", menuFrame, {
	Size = UDim2.new(0.8, 0, 0.12, 0),
	Position = UDim2.new(0.1, 0, 0.08, 0),
	Text = "🧘 MEDITATION TRAINING 🧘",
	TextScaled = true,
	TextColor3 = Color3.fromRGB(150, 220, 255)
})

-- Add text stroke for contrast
local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

local subtitleLabel = createTextLabel("SubtitleLabel", menuFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.22, 0),
	Text = "Path of the Focused Mind",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(255, 220, 120)
})

local subtitleStroke = Instance.new("UIStroke")
subtitleStroke.Color = Color3.fromRGB(0, 0, 0)
subtitleStroke.Thickness = 1.5
subtitleStroke.Parent = subtitleLabel

-- Technique description
local techniqueLabel = createTextLabel("TechniqueLabel", menuFrame, {
	Size = UDim2.new(0.85, 0, 0.06, 0),
	Position = UDim2.new(0.075, 0, 0.34, 0),
	Text = "✨ ENERGY FLOW MEDITATION",
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255)
})

local techStroke = Instance.new("UIStroke")
techStroke.Color = Color3.fromRGB(0, 0, 0)
techStroke.Thickness = 1.5
techStroke.Parent = techniqueLabel

-- Instructions with martial arts wisdom
createTextLabel("InstructionsLabel", menuFrame, {
	Size = UDim2.new(0.85, 0, 0.28, 0),
	Position = UDim2.new(0.075, 0, 0.42, 0),
	Text = [[
• OBSERVE the energy flow

• REMEMBER the path clearly

• RECREATE with precision

The path grows longer and faster.
How deep is your focus?]],
	TextScaled = false,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(240, 240, 250),
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left
})

createTextButton("BeginButton", menuFrame, {
	Size = UDim2.new(0.5, 0, 0.1, 0),
	Position = UDim2.new(0.25, 0, 0.8, 0),
	Text = "BEGIN MEDITATION",
	TextScaled = true,
	BackgroundColor3 = Colors.Chi
})

createTextButton("CloseMenuButton", menuFrame, {
	Size = UDim2.new(0.5, 0, 0.08, 0),
	Position = UDim2.new(0.25, 0, 0.91, 0),
	Text = "Close",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(80, 80, 100)
})

-- ============================================
-- MEDITATION FRAME - Training Space
-- ============================================
local meditationFrame = createFrame("MeditationFrame", screenGui, {
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Colors.Background,
	BackgroundTransparency = 0,
	Visible = false
})

-- Info panel with meditation stats
local infoFrame = createFrame("InfoFrame", meditationFrame, {
	Size = UDim2.new(0.9, 0, 0.18, 0),
	Position = UDim2.new(0.05, 0, 0.04, 0),
	BackgroundColor3 = Colors.Temple,
	BackgroundTransparency = 0.2
})

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0.08, 0)
infoCorner.Parent = infoFrame

-- Discipline rank (top left)
createTextLabel("DisciplineLabel", infoFrame, {
	Size = UDim2.new(0.35, 0, 0.22, 0),
	Position = UDim2.new(0.03, 0, 0.08, 0),
	Text = "Novice Monk",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Colors.Gold
})

-- Level indicator
createTextLabel("LevelLabel", infoFrame, {
	Size = UDim2.new(0.25, 0, 0.18, 0),
	Position = UDim2.new(0.72, 0, 0.08, 0),
	Text = "Level 1",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham
})

-- Current state (center, large)
createTextLabel("StateLabel", infoFrame, {
	Size = UDim2.new(0.7, 0, 0.28, 0),
	Position = UDim2.new(0.15, 0, 0.36, 0),
	Text = "CENTER YOURSELF",
	TextScaled = true,
	TextColor3 = Colors.Accent
})

-- Wisdom text (bottom)
createTextLabel("WisdomLabel", infoFrame, {
	Size = UDim2.new(0.9, 0, 0.16, 0),
	Position = UDim2.new(0.05, 0, 0.72, 0),
	Text = "Breathe deeply...",
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextColor3 = Colors.TextDim
})

-- Stats row (left side)
createTextLabel("PathLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.03, 0, 0.35, 0),
	Text = "Path: 3",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
	TextSize = 14
})

createTextLabel("ProgressLabel", infoFrame, {
	Size = UDim2.new(0.25, 0, 0.14, 0),
	Position = UDim2.new(0.03, 0, 0.52, 0),
	Text = "Progress: 0 / 3",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
	TextSize = 14
})

-- Stats row (right side)
createTextLabel("HarmonyLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.75, 0, 0.35, 0),
	Text = "Harmony: x0",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Gold,
	TextSize = 14
})

createTextLabel("ChiLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.75, 0, 0.52, 0),
	Text = "Control: 0%",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Accent,
	TextSize = 14
})

-- Exit button (top right of meditation frame)
local exitMeditationButton = createTextButton("ExitMeditationButton", meditationFrame, {
	Size = UDim2.new(0, 100, 0, 40),
	Position = UDim2.new(1, -110, 0, 10),
	Text = "Exit",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(200, 80, 80),
	ZIndex = 10
})

-- Enlightenment popup (hidden by default)
local enlightenmentPopup = createTextLabel("EnlightenmentPopup", infoFrame, {
	Size = UDim2.new(0.5, 0, 0.5, 0),
	Position = UDim2.new(0.25, 0, 0.5, 0),
	Text = "+100 Enlightenment",
	TextScaled = true,
	TextColor3 = Colors.Gold,
	Visible = false,
	ZIndex = 10,
	Font = Enum.Font.GothamBold
})

-- Add stroke to popup
local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(0, 0, 0)
popupStroke.Thickness = 3
popupStroke.Parent = enlightenmentPopup

-- Mandala grid (meditation stones)
local mandalaGrid = createFrame("MandalaGrid", meditationFrame, {
	Size = UDim2.new(0.65, 0, 0.65, 0),
	Position = UDim2.new(0.175, 0, 0.27, 0),
	BackgroundTransparency = 1
})

-- Decorative circle behind grid
local circle = Instance.new("ImageLabel")
circle.Name = "MandalaCircle"
circle.Size = UDim2.new(1.1, 0, 1.1, 0)
circle.Position = UDim2.new(-0.05, 0, -0.05, 0)
circle.BackgroundTransparency = 1
circle.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
circle.ImageColor3 = Colors.Temple
circle.ImageTransparency = 0.7
circle.ZIndex = 0
circle.Parent = mandalaGrid

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

-- ============================================
-- RESULT FRAME - Reflection (Smaller, centered)
-- ============================================
local resultFrame = createFrame("ResultFrame", screenGui, {
	Size = UDim2.new(0, 450, 0, 550),
	Position = UDim2.new(0.5, -225, 0.5, -275),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.fromRGB(20, 20, 30),
	BackgroundTransparency = 0,
	Visible = false
})

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0.04, 0)
resultCorner.Parent = resultFrame

-- Drag handle indicator
local dragHandleResult = createTextLabel("DragHandle", resultFrame, {
	Size = UDim2.new(0.3, 0, 0.04, 0),
	Position = UDim2.new(0.35, 0, 0.01, 0),
	Text = "⋮⋮⋮",
	TextScaled = true,
	TextColor3 = Color3.fromRGB(120, 120, 140),
	Font = Enum.Font.GothamBold
})

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = Color3.fromRGB(100, 150, 200)
resultStroke.Thickness = 2
resultStroke.Parent = resultFrame

-- Don't add zen decoration - it adds transparency
-- addZenDecoration(resultFrame)

local endTitleLabel = createTextLabel("EndTitleLabel", resultFrame, {
	Size = UDim2.new(0.85, 0, 0.1, 0),
	Position = UDim2.new(0.075, 0, 0.08, 0),
	Text = "MEDITATION COMPLETE",
	TextScaled = true,
	TextColor3 = Color3.fromRGB(150, 220, 255)
})

local endTitleStroke = Instance.new("UIStroke")
endTitleStroke.Color = Color3.fromRGB(0, 0, 0)
endTitleStroke.Thickness = 2
endTitleStroke.Parent = endTitleLabel

local disciplineResultLabel = createTextLabel("DisciplineLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.22, 0),
	Text = "Discipline: Novice Monk",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(255, 220, 120)
})

local disciplineStroke = Instance.new("UIStroke")
disciplineStroke.Color = Color3.fromRGB(0, 0, 0)
disciplineStroke.Thickness = 1.5
disciplineStroke.Parent = disciplineResultLabel

createTextLabel("LevelLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.32, 0),
	Text = "Level Reached: 5",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(255, 255, 255)
})

createTextLabel("EnlightenmentLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.42, 0),
	Text = "Total Enlightenment: 1500",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(255, 255, 255)
})

createTextLabel("BestLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.52, 0),
	Text = "Highest Level: 7",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(150, 220, 255)
})

createTextLabel("PerfectLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.62, 0),
	Text = "Perfect Flows: 3",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Color3.fromRGB(255, 220, 120)
})

-- Wisdom quote at bottom
createTextLabel("WisdomLabel", resultFrame, {
	Size = UDim2.new(0.85, 0, 0.09, 0),
	Position = UDim2.new(0.075, 0, 0.73, 0),
	Text = "The journey of a thousand miles begins with a single step.",
	TextScaled = false,
	TextSize = 15,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	TextColor3 = Color3.fromRGB(200, 200, 220)
})

-- Buttons
createTextButton("MeditateAgainButton", resultFrame, {
	Size = UDim2.new(0.42, 0, 0.09, 0),
	Position = UDim2.new(0.05, 0, 0.87, 0),
	Text = "MEDITATE AGAIN",
	TextScaled = true,
	BackgroundColor3 = Colors.Chi
})

createTextButton("ReturnButton", resultFrame, {
	Size = UDim2.new(0.42, 0, 0.09, 0),
	Position = UDim2.new(0.53, 0, 0.87, 0),
	Text = "RETURN",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(80, 80, 100)
})

-- ============================================
-- MAKE FRAMES DRAGGABLE
-- ============================================

local function makeDraggable(frame)
	local UserInputService = game:GetService("UserInputService")

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or
			input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Make both menu and result frames draggable
makeDraggable(menuFrame)
makeDraggable(resultFrame)

print("🧘 Meditation UI - Built Successfully (Draggable)")