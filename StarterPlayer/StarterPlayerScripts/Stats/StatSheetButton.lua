-- StatSheetOpenerButton
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Creates a button to open stat sheet on mobile/console

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Detect platform
local function isMobile()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function isConsole()
	return GuiService:IsTenFootInterface()
end

-- Only create button if on mobile or console
if not (isMobile() or isConsole()) then
	print("PC detected - using keyboard controls")
	return
end

-- Wait for the main stat sheet GUI with a longer timeout
local statSheetGui = playerGui:WaitForChild("StatSheetGUI", 30)
if not statSheetGui then
	warn("StatSheetGUI not found after 30 seconds")
	return
end

-- Wait for the main panel to exist
local mainPanel = statSheetGui:WaitForChild("MainPanel", 10)
if not mainPanel then
	warn("StatSheetGUI MainPanel not found")
	return
end

-- Create button GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatSheetOpener"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Button
local openButton = Instance.new("TextButton")
openButton.Name = "OpenButton"
openButton.Size = UDim2.new(0, 80, 0, 80)
openButton.Position = UDim2.new(1, -100, 0, 20) -- Top right
openButton.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
openButton.BorderSizePixel = 0
openButton.Text = "📊" -- Stats icon
openButton.TextColor3 = Color3.fromRGB(180, 140, 230)
openButton.Font = Enum.Font.GothamBold
openButton.TextSize = 32
openButton.Parent = screenGui

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = openButton

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(180, 140, 230)
buttonStroke.Thickness = 2
buttonStroke.Transparency = 0.5
buttonStroke.Parent = openButton

-- Label below button
local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, 0, 0, 20)
label.Position = UDim2.new(0, 0, 1, 5)
label.BackgroundTransparency = 1
label.Text = "STATS"
label.TextColor3 = Color3.fromRGB(180, 140, 230)
label.Font = Enum.Font.GothamBold
label.TextSize = 12
label.Parent = openButton

-- Button functionality
openButton.MouseButton1Click:Connect(function()
	-- Toggle the main panel
	mainPanel.Visible = not mainPanel.Visible
end)

print("✓ Stat sheet opener button created for mobile/console")