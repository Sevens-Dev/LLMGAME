--[[
	MeditationUIBuilder_Enhanced.lua (StarterGui - LocalScript)
	?? ENHANCED VERSION - Stunning visuals, particles, and animations
	Builds a spectacular meditation interface with chi energy effects
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MeditationUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- ============================================================================
-- ENHANCED COLOR PALETTE - Mystical & Vibrant
-- ============================================================================
local Colors = {
	-- Backgrounds
	Background = Color3.fromRGB(8, 5, 15), -- Deep cosmic purple-black
	Temple = Color3.fromRGB(20, 15, 35),
	Stone = Color3.fromRGB(30, 25, 45),

	-- Chi Energy Colors (Vibrant & Glowing)
	Chi = {
		White = Color3.fromRGB(255, 255, 255),
		Gold = Color3.fromRGB(255, 215, 0),
		Blue = Color3.fromRGB(100, 200, 255),
		Purple = Color3.fromRGB(200, 100, 255),
		Cyan = Color3.fromRGB(0, 255, 255),
		Green = Color3.fromRGB(100, 255, 150),
	},

	-- UI Colors
	Text = Color3.fromRGB(255, 250, 240),
	TextDim = Color3.fromRGB(180, 170, 200),
	Accent = Color3.fromRGB(100, 200, 255),
	AccentGlow = Color3.fromRGB(150, 220, 255),

	-- States
	Active = Color3.fromRGB(255, 200, 50),
	Correct = Color3.fromRGB(100, 255, 150),
	Incorrect = Color3.fromRGB(255, 100, 100),
}

-- ============================================================================
-- PARTICLE SYSTEM - Chi Energy Effects
-- ============================================================================
local ParticleEffects = {}

function ParticleEffects.CreateAmbientParticles(parent)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "AmbientChi"
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 5
	particles.Lifetime = NumberRange.new(3, 5)
	particles.Speed = NumberRange.new(0.5, 1.5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-30, 30)
	particles.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Colors.Chi.Blue),
		ColorSequenceKeypoint.new(0.5, Colors.Chi.Purple),
		ColorSequenceKeypoint.new(1, Colors.Chi.Cyan)
	}
	particles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.4),
		NumberSequenceKeypoint.new(0.7, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	}
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 0.2)
	}
	particles.Parent = parent
	return particles
end

function ParticleEffects.CreateChiExplosion(parent, color)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "ChiExplosion"
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 0
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Color = ColorSequence.new(color)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Parent = parent

	-- Trigger burst
	task.spawn(function()
		particles:Emit(20)
		task.wait(2)
		particles:Destroy()
	end)

	return particles
end

-- ============================================================================
-- HELPER FUNCTIONS - Enhanced with animations
-- ============================================================================
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
	button.AutoButtonColor = false -- We'll handle hover ourselves

	for prop, value in pairs(properties) do
		button[prop] = value
	end

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.15, 0)
	corner.Parent = button

	-- Glowing border
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Color = Colors.AccentGlow
	glow.Thickness = 2
	glow.Transparency = 0.3
	glow.Parent = button

	-- Gradient overlay
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))
	}
	gradient.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(1, 0.9)
	}
	gradient.Rotation = 45
	gradient.Parent = button

	-- Hover effects
	button.MouseEnter:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.2), {
			Thickness = 4,
			Transparency = 0
		}):Play()

		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = UDim2.new(
				button.Size.X.Scale * 1.05,
				button.Size.X.Offset * 1.05,
				button.Size.Y.Scale * 1.05,
				button.Size.Y.Offset * 1.05
			)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(glow, TweenInfo.new(0.2), {
			Thickness = 2,
			Transparency = 0.3
		}):Play()

		-- Reset to original size (store it first)
		local originalSize = button.Size
		TweenService:Create(button, TweenInfo.new(0.2), {
			Size = originalSize
		}):Play()
	end)

	return button
end

local function addGlowingBorder(parent: Instance, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Name = "BorderGlow"
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Transparency = 0.2
	stroke.Parent = parent

	-- Pulse animation
	task.spawn(function()
		while stroke.Parent do
			TweenService:Create(stroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0
			}):Play()
			task.wait(2)
			TweenService:Create(stroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Transparency = 0.5
			}):Play()
			task.wait(2)
		end
	end)

	return stroke
end

local function createAnimatedBackground(parent: Instance)
	-- Cosmic background with stars
	local bg = Instance.new("Frame")
	bg.Name = "AnimatedBackground"
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.Position = UDim2.new(0, 0, 0, 0)
	bg.BackgroundColor3 = Colors.Background
	bg.BorderSizePixel = 0
	bg.ZIndex = 0
	bg.Parent = parent

	-- Gradient overlay for depth
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 10, 40)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 5, 15)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 15, 50))
	}
	gradient.Rotation = 90
	gradient.Parent = bg

	-- Animated gradient rotation
	task.spawn(function()
		while bg.Parent do
			TweenService:Create(gradient, TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Rotation = gradient.Rotation + 360
			}):Play()
			task.wait(10)
		end
	end)

	-- Add floating particles
	ParticleEffects.CreateAmbientParticles(bg)

	return bg
end

-- ============================================================================
-- OPEN BUTTON - Mystical Portal Style
-- ============================================================================
local openButton = createTextButton("OpenMeditationButton", screenGui, {
	Size = UDim2.new(0, 160, 0, 60),
	Position = UDim2.new(1, -170, 0, 10),
	Text = "?? MEDITATE",
	TextScaled = false,
	TextSize = 20,
	BackgroundColor3 = Color3.fromRGB(80, 40, 140),
	ZIndex = 100
})

-- Add pulsing glow to open button
addGlowingBorder(openButton, Colors.Chi.Purple)

-- ============================================================================
-- MENU FRAME - Temple Entrance
-- ============================================================================
local menuFrame = createFrame("MenuFrame", screenGui, {
	Size = UDim2.new(0, 500, 0, 600),
	Position = UDim2.new(0.5, -250, 0.5, -300),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.fromRGB(15, 10, 30),
	BackgroundTransparency = 0.05,
	Visible = false
})

-- Animated background
createAnimatedBackground(menuFrame)

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0.04, 0)
menuCorner.Parent = menuFrame

-- Glowing border
addGlowingBorder(menuFrame, Colors.AccentGlow)

-- Drag handle indicator with glow
local dragHandle = createTextLabel("DragHandle", menuFrame, {
	Size = UDim2.new(0.3, 0, 0.04, 0),
	Position = UDim2.new(0.35, 0, 0.01, 0),
	Text = "???",
	TextScaled = true,
	TextColor3 = Colors.AccentGlow,
	Font = Enum.Font.GothamBold,
	ZIndex = 2
})

-- Pulsing title with glow effect
local titleLabel = createTextLabel("TitleLabel", menuFrame, {
	Size = UDim2.new(0.8, 0, 0.12, 0),
	Position = UDim2.new(0.1, 0, 0.08, 0),
	Text = "?? MEDITATION MASTERY ??",
	TextScaled = true,
	TextColor3 = Colors.Chi.Gold,
	ZIndex = 2
})

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(100, 50, 0)
titleStroke.Thickness = 3
titleStroke.Parent = titleLabel

-- Pulse animation for title
task.spawn(function()
	while titleLabel.Parent do
		TweenService:Create(titleLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextColor3 = Colors.Chi.Cyan
		}):Play()
		task.wait(1.5)
		TweenService:Create(titleLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextColor3 = Colors.Chi.Gold
		}):Play()
		task.wait(1.5)
	end
end)

local subtitleLabel = createTextLabel("SubtitleLabel", menuFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.22, 0),
	Text = "? Path of the Focused Mind ?",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Chi.Purple,
	ZIndex = 2
})

local subtitleStroke = Instance.new("UIStroke")
subtitleStroke.Color = Color3.fromRGB(0, 0, 0)
subtitleStroke.Thickness = 2
subtitleStroke.Parent = subtitleLabel

-- Technique description with animated gradient
local techniqueLabel = createTextLabel("TechniqueLabel", menuFrame, {
	Size = UDim2.new(0.85, 0, 0.06, 0),
	Position = UDim2.new(0.075, 0, 0.34, 0),
	Text = "? ENERGY FLOW MEDITATION ?",
	TextScaled = true,
	Font = Enum.Font.GothamBold,
	TextColor3 = Colors.AccentGlow,
	ZIndex = 2
})

local techStroke = Instance.new("UIStroke")
techStroke.Color = Colors.Chi.Blue
techStroke.Thickness = 2
techStroke.Parent = techniqueLabel

-- Instructions
createTextLabel("InstructionsLabel", menuFrame, {
	Size = UDim2.new(0.85, 0, 0.28, 0),
	Position = UDim2.new(0.075, 0, 0.42, 0),
	Text = [[
? OBSERVE the energy flow carefully

?? REMEMBER the path with clarity

? RECREATE with perfect precision

? Each level increases difficulty
?? Test the limits of your focus!]],
	TextScaled = false,
	TextSize = 17,
	Font = Enum.Font.GothamBold,
	TextWrapped = true,
	TextColor3 = Colors.Text,
	TextYAlignment = Enum.TextYAlignment.Top,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 2
})

-- Begin button with special effects
local beginButton = createTextButton("BeginButton", menuFrame, {
	Size = UDim2.new(0.6, 0, 0.12, 0),
	Position = UDim2.new(0.2, 0, 0.78, 0),
	Text = "? BEGIN MEDITATION ?",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(100, 50, 200),
	ZIndex = 2
})

-- Add extra glow to begin button
local beginGlow = Instance.new("UIStroke")
beginGlow.Name = "ExtraGlow"
beginGlow.Color = Colors.Chi.Purple
beginGlow.Thickness = 4
beginGlow.Transparency = 0.1
beginGlow.Parent = beginButton

createTextButton("CloseMenuButton", menuFrame, {
	Size = UDim2.new(0.4, 0, 0.08, 0),
	Position = UDim2.new(0.3, 0, 0.91, 0),
	Text = "Close",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(60, 40, 80),
	ZIndex = 2
})

-- ============================================================================
-- MEDITATION FRAME - Enhanced Training Space
-- ============================================================================
local meditationFrame = createFrame("MeditationFrame", screenGui, {
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = Colors.Background,
	BackgroundTransparency = 0,
	Visible = false
})

-- Cosmic animated background
createAnimatedBackground(meditationFrame)

-- Info panel with glowing effects
local infoFrame = createFrame("InfoFrame", meditationFrame, {
	Size = UDim2.new(0.9, 0, 0.18, 0),
	Position = UDim2.new(0.05, 0, 0.04, 0),
	BackgroundColor3 = Color3.fromRGB(20, 15, 40),
	BackgroundTransparency = 0.1,
	ZIndex = 2
})

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0.08, 0)
infoCorner.Parent = infoFrame

addGlowingBorder(infoFrame, Colors.AccentGlow)

-- Discipline rank (animated)
local disciplineLabel = createTextLabel("DisciplineLabel", infoFrame, {
	Size = UDim2.new(0.35, 0, 0.22, 0),
	Position = UDim2.new(0.03, 0, 0.08, 0),
	Text = "Novice Monk",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextColor3 = Colors.Chi.Gold,
	ZIndex = 3
})

local disciplineStroke = Instance.new("UIStroke")
disciplineStroke.Color = Color3.fromRGB(100, 50, 0)
disciplineStroke.Thickness = 2
disciplineStroke.Parent = disciplineLabel

-- Level indicator
createTextLabel("LevelLabel", infoFrame, {
	Size = UDim2.new(0.25, 0, 0.18, 0),
	Position = UDim2.new(0.72, 0, 0.08, 0),
	Text = "Level 1",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham,
	ZIndex = 3
})

-- Current state (large, animated)
local stateLabel = createTextLabel("StateLabel", infoFrame, {
	Size = UDim2.new(0.7, 0, 0.28, 0),
	Position = UDim2.new(0.15, 0, 0.36, 0),
	Text = "CENTER YOURSELF",
	TextScaled = true,
	TextColor3 = Colors.Accent,
	ZIndex = 3
})

local stateStroke = Instance.new("UIStroke")
stateStroke.Color = Colors.Chi.Blue
stateStroke.Thickness = 2
stateStroke.Parent = stateLabel

-- Wisdom text
createTextLabel("WisdomLabel", infoFrame, {
	Size = UDim2.new(0.9, 0, 0.16, 0),
	Position = UDim2.new(0.05, 0, 0.72, 0),
	Text = "Breathe deeply...",
	TextScaled = true,
	Font = Enum.Font.GothamMedium,
	TextColor3 = Colors.TextDim,
	ZIndex = 3
})

-- Stats with glowing text
createTextLabel("PathLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.03, 0, 0.35, 0),
	Text = "Path: 3",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	ZIndex = 3
})

createTextLabel("ProgressLabel", infoFrame, {
	Size = UDim2.new(0.25, 0, 0.14, 0),
	Position = UDim2.new(0.03, 0, 0.52, 0),
	Text = "Progress: 0 / 3",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Left,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	ZIndex = 3
})

createTextLabel("HarmonyLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.75, 0, 0.35, 0),
	Text = "Harmony: x0",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Chi.Gold,
	TextSize = 14,
	ZIndex = 3
})

createTextLabel("ChiLabel", infoFrame, {
	Size = UDim2.new(0.22, 0, 0.14, 0),
	Position = UDim2.new(0.75, 0, 0.52, 0),
	Text = "Energy: 0%",
	TextScaled = true,
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Accent,
	TextSize = 14,
	ZIndex = 3
})

-- Exit button
local exitMeditationButton = createTextButton("ExitMeditationButton", meditationFrame, {
	Size = UDim2.new(0, 120, 0, 50),
	Position = UDim2.new(1, -130, 0, 10),
	Text = "Exit",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(200, 50, 50),
	ZIndex = 10
})

-- Enlightenment popup with explosive effects
local enlightenmentPopup = createTextLabel("EnlightenmentPopup", infoFrame, {
	Size = UDim2.new(0.6, 0, 0.6, 0),
	Position = UDim2.new(0.2, 0, 0.5, 0),
	Text = "+100 Enlightenment",
	TextScaled = true,
	TextColor3 = Colors.Chi.Gold,
	Visible = false,
	ZIndex = 20,
	Font = Enum.Font.GothamBold
})

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(150, 75, 0)
popupStroke.Thickness = 4
popupStroke.Parent = enlightenmentPopup

-- ============================================================================
-- MANDALA GRID - Sacred Geometry
-- ============================================================================
local mandalaGrid = createFrame("MandalaGrid", meditationFrame, {
	Size = UDim2.new(0.7, 0, 0.7, 0),
	Position = UDim2.new(0.15, 0, 0.25, 0),
	BackgroundTransparency = 1,
	ZIndex = 1
})

-- Sacred circle background with animated glow
local circle = Instance.new("Frame")
circle.Name = "MandalaCircle"
circle.Size = UDim2.new(1.1, 0, 1.1, 0)
circle.Position = UDim2.new(-0.05, 0, -0.05, 0)
circle.BackgroundColor3 = Color3.fromRGB(40, 20, 80)
circle.BackgroundTransparency = 0.3
circle.ZIndex = 0
circle.Parent = mandalaGrid

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circle

-- Animated rotating glow
local circleGlow = Instance.new("UIStroke")
circleGlow.Color = Colors.Chi.Purple
circleGlow.Thickness = 6
circleGlow.Transparency = 0.4
circleGlow.Parent = circle

task.spawn(function()
	while circle.Parent do
		TweenService:Create(circleGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Thickness = 10,
			Transparency = 0.1
		}):Play()
		task.wait(2)
		TweenService:Create(circleGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Thickness = 6,
			Transparency = 0.4
		}):Play()
		task.wait(2)
	end
end)

-- Gradient for depth
local circleGradient = Instance.new("UIGradient")
circleGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 40, 160)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 20, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 120))
}
circleGradient.Rotation = 45
circleGradient.Parent = circle

-- Rotate gradient slowly
task.spawn(function()
	while circleGradient.Parent do
		TweenService:Create(circleGradient, TweenInfo.new(20, Enum.EasingStyle.Linear), {
			Rotation = circleGradient.Rotation + 360
		}):Play()
		task.wait(20)
	end
end)

-- ============================================================================
-- RESULT FRAME - Reflection
-- ============================================================================
local resultFrame = createFrame("ResultFrame", screenGui, {
	Size = UDim2.new(0, 550, 0, 650),
	Position = UDim2.new(0.5, -275, 0.5, -325),
	AnchorPoint = Vector2.new(0, 0),
	BackgroundColor3 = Color3.fromRGB(15, 10, 30),
	BackgroundTransparency = 0.05,
	Visible = false
})

-- Animated background
createAnimatedBackground(resultFrame)

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0.04, 0)
resultCorner.Parent = resultFrame

addGlowingBorder(resultFrame, Colors.AccentGlow)

-- Drag handle
local dragHandleResult = createTextLabel("DragHandle", resultFrame, {
	Size = UDim2.new(0.3, 0, 0.04, 0),
	Position = UDim2.new(0.35, 0, 0.01, 0),
	Text = "???",
	TextScaled = true,
	TextColor3 = Colors.AccentGlow,
	Font = Enum.Font.GothamBold,
	ZIndex = 2
})

-- Title with animation
local endTitleLabel = createTextLabel("EndTitleLabel", resultFrame, {
	Size = UDim2.new(0.85, 0, 0.1, 0),
	Position = UDim2.new(0.075, 0, 0.08, 0),
	Text = "? MEDITATION COMPLETE ?",
	TextScaled = true,
	TextColor3 = Colors.Chi.Gold,
	ZIndex = 2
})

local endTitleStroke = Instance.new("UIStroke")
endTitleStroke.Color = Color3.fromRGB(100, 50, 0)
endTitleStroke.Thickness = 3
endTitleStroke.Parent = endTitleLabel

-- Stats labels
local disciplineResultLabel = createTextLabel("DisciplineLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.22, 0),
	Text = "Discipline: Novice Monk",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Chi.Purple,
	ZIndex = 2
})

createTextLabel("LevelLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.32, 0),
	Text = "Level Reached: 5",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Text,
	ZIndex = 2
})

createTextLabel("EnlightenmentLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.42, 0),
	Text = "Total Enlightenment: 1500",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Text,
	ZIndex = 2
})

createTextLabel("BestLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.52, 0),
	Text = "Highest Level: 7",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.AccentGlow,
	ZIndex = 2
})

createTextLabel("PerfectLabel", resultFrame, {
	Size = UDim2.new(0.8, 0, 0.08, 0),
	Position = UDim2.new(0.1, 0, 0.62, 0),
	Text = "Perfect Flows: 3",
	TextScaled = true,
	Font = Enum.Font.Gotham,
	TextColor3 = Colors.Chi.Gold,
	ZIndex = 2
})

createTextLabel("WisdomLabel", resultFrame, {
	Size = UDim2.new(0.85, 0, 0.09, 0),
	Position = UDim2.new(0.075, 0, 0.73, 0),
	Text = "The journey of a thousand miles begins with a single step.",
	TextScaled = false,
	TextSize = 15,
	Font = Enum.Font.GothamMedium,
	TextWrapped = true,
	TextColor3 = Colors.TextDim,
	ZIndex = 2
})

-- Buttons
createTextButton("MeditateAgainButton", resultFrame, {
	Size = UDim2.new(0.42, 0, 0.09, 0),
	Position = UDim2.new(0.05, 0, 0.87, 0),
	Text = "? MEDITATE AGAIN",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(100, 50, 200),
	ZIndex = 2
})

createTextButton("ReturnButton", resultFrame, {
	Size = UDim2.new(0.42, 0, 0.09, 0),
	Position = UDim2.new(0.53, 0, 0.87, 0),
	Text = "Return",
	TextScaled = true,
	BackgroundColor3 = Color3.fromRGB(60, 40, 80),
	ZIndex = 2
})

-- ============================================================================
-- MAKE FRAMES DRAGGABLE
-- ============================================================================
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

makeDraggable(menuFrame)
makeDraggable(resultFrame)

print("?? Enhanced Meditation UI - Built with SPECTACULAR visuals!")