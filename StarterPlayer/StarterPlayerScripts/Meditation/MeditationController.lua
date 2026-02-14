--[[
	MeditationController.lua (StarterPlayerScripts)
	Client-side meditation and chi flow visualization
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MeditationConfig = require(ReplicatedStorage:WaitForChild("MeditationConfig"))
local RemoteEvents = ReplicatedStorage:WaitForChild("MeditationEvents")
local BeginMeditationEvent = RemoteEvents:WaitForChild("BeginMeditation")
local SubmitFlowEvent = RemoteEvents:WaitForChild("SubmitFlow")
local EnlightenmentEvent = RemoteEvents:WaitForChild("Enlightenment")

-- UI References
local MainUI = playerGui:WaitForChild("MeditationUI")
local MenuFrame = MainUI:WaitForChild("MenuFrame")
local MeditationFrame = MainUI:WaitForChild("MeditationFrame")
local ResultFrame = MainUI:WaitForChild("ResultFrame")
local MandalaGrid = MeditationFrame:WaitForChild("MandalaGrid")
local InfoFrame = MeditationFrame:WaitForChild("InfoFrame")

-- Meditation state
local MeditationState = {
	IsMeditating = false,
	IsShowingFlow = false,
	CurrentPath = {},
	PlayerPath = {},
	CurrentLevel = 1,
	CurrentDifficulty = nil,
	Stones = {}, -- Meditation stones (tiles)
	ChiParticles = {},
	-- Tracing/Swiping mechanic
	IsTracing = false,
	LastTouchedStone = nil,
	TracedStones = {}, -- Track which stones have been traced over
	TraceStartTime = 0
}

-- Sound system
local Sounds = {}

local function createSound(name: string, soundId: string, volume: number): Sound?
	if soundId == "" then
		return nil -- Skip empty sounds
	end

	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume or 0.4
	sound.Parent = SoundService
	return sound
end

-- Initialize sounds
for soundName, soundId in pairs(MeditationConfig.Sounds) do
	local volume = (soundName == "TempleAmbience" or soundName == "MeditationDrone") and 0.2 or 0.4
	Sounds[soundName] = createSound(soundName, soundId, volume)
end

-- Start ambient meditation music (if it exists)
if Sounds.TempleAmbience then
	Sounds.TempleAmbience.Looped = true
	Sounds.TempleAmbience:Play()
end

-- UI Helpers
local function smoothShow(frame: Frame)
	frame.Visible = true
	-- Simple fade in by just making visible
	-- Note: For smooth fades, wrap content in CanvasGroup in future
end

local function smoothHide(frame: Frame)
	-- Simple hide
	frame.Visible = false
end

-- Create meditation stone grid (mandala pattern)
local function createMandalaGrid()
	-- Clear existing stones
	for _, stone in pairs(MeditationState.Stones) do
		stone:Destroy()
	end
	MeditationState.Stones = {}

	if not MandalaGrid then
		warn("❌ MandalaGrid not found! Check UI structure.")
		return
	end

	print("✓ MandalaGrid found at:", MandalaGrid:GetFullName())

	local gridSize = MeditationConfig.GridSize
	local stoneSize = UDim2.new(0.20, 0, 0.20, 0)
	local spacing = 0.03

	print("Creating " .. (gridSize * gridSize) .. " meditation stones in " .. gridSize .. "x" .. gridSize .. " grid...")

	local stonesCreated = 0

	for row = 0, gridSize - 1 do
		for col = 0, gridSize - 1 do
			local stoneIndex = row * gridSize + col + 1

			-- Create meditation stone
			local stone = Instance.new("TextButton")
			stone.Name = "Stone_" .. stoneIndex
			stone.Size = stoneSize
			stone.Position = UDim2.new(
				col * (0.20 + spacing) + 0.1,
				0,
				row * (0.20 + spacing) + 0.1,
				0
			)
			stone.BackgroundColor3 = MeditationConfig.Colors.Chi.Dormant
			stone.BorderSizePixel = 0
			stone.Text = tostring(stoneIndex) -- TEMPORARY: Show numbers for debugging
			stone.TextColor3 = Color3.fromRGB(150, 150, 150)
			stone.TextScaled = true
			stone.AutoButtonColor = false
			stone.Visible = true
			stone.ZIndex = 2
			stone.Parent = MandalaGrid

			-- Rounded stone shape
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.15, 0)
			corner.Parent = stone
			stone.AutoButtonColor = false
			stone.Parent = MandalaGrid

			-- Rounded stone shape
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.15, 0)
			corner.Parent = stone

			-- Subtle glow effect
			local glow = Instance.new("UIStroke")
			glow.Name = "Glow"
			glow.Color = MeditationConfig.Colors.Chi.White
			glow.Thickness = 0
			glow.Transparency = 0.5
			glow.Parent = stone

			-- Store reference
			MeditationState.Stones[stoneIndex] = stone
			stonesCreated = stonesCreated + 1

			-- TRACING/SWIPING HANDLERS (works for both PC drag and mobile swipe)
			stone.InputBegan:Connect(function(input)
				if not (MeditationState.IsMeditating and not MeditationState.IsShowingFlow) then
					return
				end

				-- Start tracing on click/touch
				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					input.UserInputType == Enum.UserInputType.Touch then
					startTracing(stoneIndex)
				end
			end)

			stone.MouseEnter:Connect(function()
				-- Continue trace when mouse enters stone while dragging
				if MeditationState.IsTracing then
					continueTracing(stoneIndex)
				end
			end)

			-- Note: TouchMoved doesn't exist on TextButton
			-- Mobile touch is handled by InputBegan and MouseEnter during drag
		end
	end

	-- Global input handlers for ending trace
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
			endTracing()
		end
	end)

	-- Handle touch drag for mobile (InputChanged detects movement)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and MeditationState.IsTracing then
			-- Check which stone the touch is over
			local touchPos = input.Position

			for stoneIndex, stone in pairs(MeditationState.Stones) do
				local stonePos = stone.AbsolutePosition
				local stoneSize = stone.AbsoluteSize

				if touchPos.X >= stonePos.X and touchPos.X <= stonePos.X + stoneSize.X and
					touchPos.Y >= stonePos.Y and touchPos.Y <= stonePos.Y + stoneSize.Y then
					continueTracing(stoneIndex)
					break
				end
			end
		end
	end)

	-- Count stones properly
	local stoneCount = 0
	for _ in pairs(MeditationState.Stones) do
		stoneCount = stoneCount + 1
	end

	print("✓ Successfully created " .. stonesCreated .. " meditation stones")
	print("   Stones stored in table: " .. stoneCount)
	print("   MandalaGrid children: " .. #MandalaGrid:GetChildren())
end

-- Animate chi flowing through a stone
local function flowChiThroughStone(stoneIndex: number, chiColor: Color3, duration: number, glowIntensity: number)
	local stone = MeditationState.Stones[stoneIndex]
	if not stone then return end

	local glow = stone:FindFirstChild("Glow")
	local originalColor = stone.BackgroundColor3

	-- Create particle effect for chi energy
	if MeditationConfig.Effects.EnableParticles then
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Rate = 30
		particles.Lifetime = NumberRange.new(0.5, 1.0)
		particles.Speed = NumberRange.new(2, 4)
		particles.SpreadAngle = Vector2.new(180, 180)
		particles.Color = ColorSequence.new(chiColor)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1)
		})
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0)
		})
		particles.Parent = stone

		-- Store for cleanup
		table.insert(MeditationState.ChiParticles, particles)

		task.delay(0.3, function()
			particles.Enabled = false
			task.wait(1)
			particles:Destroy()
		end)
	end

	-- Glow pulse
	if glow and MeditationConfig.Effects.EnableGlow then
		TweenService:Create(glow, TweenInfo.new(0.1), {
			Thickness = glowIntensity or 3,
			Transparency = 0.3
		}):Play()
	end

	-- Color flow
	local flowTween = TweenService:Create(stone, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
		BackgroundColor3 = chiColor
	})
	flowTween:Play()

	-- Hold the chi
	task.wait(duration)

	-- Release the chi
	if glow then
		TweenService:Create(glow, TweenInfo.new(0.3), {
			Thickness = 0,
			Transparency = 0.8
		}):Play()
	end

	local releaseTween = TweenService:Create(stone, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
		BackgroundColor3 = MeditationConfig.Colors.Chi.Dormant
	})
	releaseTween:Play()
end

-- Show the chi flow path
local function showChiFlow(path: {number}, flowTime: number, chiColor: Color3)
	MeditationState.IsShowingFlow = true
	MeditationState.PlayerPath = {}
	MeditationState.TracedStones = {}


	-- Update UI
	InfoFrame.WisdomLabel.Text = MeditationConfig.TechniqueDescriptions[1]
	InfoFrame.StateLabel.Text = "OBSERVE THE ENERGY FLOW"
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Accent

	-- Breathing preparation
	print("   Preparation phase - " .. MeditationConfig.MeditationPrepareTime .. " seconds...")
	task.wait(MeditationConfig.MeditationPrepareTime)

	-- Play breath in sound
	if Sounds.BreathIn then
		Sounds.BreathIn:Play()
	end

	print("   Displaying sequence...")

	-- Show each stone in the chi path
	for i, stoneIndex in ipairs(path) do
		print("   Stone " .. i .. "/" .. #path .. " - Index: " .. stoneIndex)

		-- Play chi flow sound
		if Sounds.ChiFlow then
			Sounds.ChiFlow:Play()
		end

		-- Visualize chi flowing
		flowChiThroughStone(stoneIndex, chiColor, flowTime, 4)

		-- Breathing rhythm
		task.wait(flowTime + MeditationConfig.ExhaleTime)

		if i < #path and Sounds.BreathOut then
			Sounds.BreathOut:Play()
		end
	end

	MeditationState.IsShowingFlow = false

	-- Update UI for player's turn
	InfoFrame.StateLabel.Text = "RECREATE THE FLOW"
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Chi.Gold
	InfoFrame.WisdomLabel.Text = "Trust your memory. Feel the path."
end

-- TRACING FUNCTIONS (Swipe/Drag mechanic)

-- Start tracing when player clicks/touches first stone
function startTracing(stoneIndex: number)
	if MeditationState.IsTracing then return end

	MeditationState.IsTracing = true
	MeditationState.LastTouchedStone = stoneIndex
	MeditationState.PlayerPath = {}
	MeditationState.TracedStones = {}
	MeditationState.TraceStartTime = tick()

	-- Add first stone
	table.insert(MeditationState.PlayerPath, stoneIndex)
	MeditationState.TracedStones[stoneIndex] = true

	-- Visual & audio feedback
	if Sounds.ChiFlow then
		Sounds.ChiFlow:Play()
	end

	local chiColor = MeditationConfig.GetChiColor(MeditationState.CurrentLevel)
	flowChiThroughStone(stoneIndex, MeditationConfig.Colors.Active, 0.5, 3)

	-- Update UI
	InfoFrame.StateLabel.Text = "TRACE THE PATH..."
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Chi.Gold

	local progressText = string.format("%d / %d", #MeditationState.PlayerPath, #MeditationState.CurrentPath)
	InfoFrame.ProgressLabel.Text = "Flow Progress: " .. progressText

	print("🧘 Started tracing at stone " .. stoneIndex)
end

-- Continue tracing as player drags/swipes over stones
function continueTracing(stoneIndex: number)
	if not MeditationState.IsTracing then return end
	if MeditationState.TracedStones[stoneIndex] then return end -- Already traced this stone
	if stoneIndex == MeditationState.LastTouchedStone then return end -- Same stone

	-- Add to path
	table.insert(MeditationState.PlayerPath, stoneIndex)
	MeditationState.TracedStones[stoneIndex] = true
	MeditationState.LastTouchedStone = stoneIndex

	-- Visual & audio feedback
	if Sounds.ChiFlow then
		Sounds.ChiFlow:Play()
	end

	local chiColor = MeditationConfig.GetChiColor(MeditationState.CurrentLevel)
	flowChiThroughStone(stoneIndex, MeditationConfig.Colors.Active, 0.5, 3)

	-- Update progress
	local progressText = string.format("%d / %d", #MeditationState.PlayerPath, #MeditationState.CurrentPath)
	InfoFrame.ProgressLabel.Text = "Flow Progress: " .. progressText

	print("🧘 Traced through stone " .. stoneIndex .. " (Total: " .. #MeditationState.PlayerPath .. ")")
end

-- End tracing when player releases click/touch
function endTracing()
	if not MeditationState.IsTracing then return end

	MeditationState.IsTracing = false

	local traceTime = tick() - MeditationState.TraceStartTime
	print("🧘 Ended trace - " .. #MeditationState.PlayerPath .. " stones in " .. string.format("%.1f", traceTime) .. "s")

	-- Check if path complete
	if #MeditationState.PlayerPath >= #MeditationState.CurrentPath then
		InfoFrame.StateLabel.Text = "FLOW COMPLETE!"
		task.wait(0.5)
		submitFlow()
	else
		-- Incomplete path
		InfoFrame.StateLabel.Text = "INCOMPLETE - TRY AGAIN"
		InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Incorrect

		-- Reset after short delay
		task.wait(1)
		if not MeditationState.IsShowingFlow and MeditationState.IsMeditating then
			MeditationState.PlayerPath = {}
			MeditationState.TracedStones = {}
			InfoFrame.StateLabel.Text = "RECREATE THE FLOW"
			InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Chi.Gold
			InfoFrame.ProgressLabel.Text = "Flow Progress: 0 / " .. #MeditationState.CurrentPath
		end
	end
end

-- Submit the player's chi flow
function submitFlow()
	MeditationState.IsMeditating = false
	InfoFrame.StateLabel.Text = "HARMONIZING..."
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.TextSecondary

	-- Send to server
	SubmitFlowEvent:FireServer(MeditationState.PlayerPath)
end

-- Handle meditation begin
BeginMeditationEvent.OnClientEvent:Connect(function(data)
	MeditationState.IsMeditating = true
	MeditationState.CurrentLevel = data.Level
	MeditationState.CurrentPath = data.ChiPath
	MeditationState.CurrentDifficulty = data.Difficulty

	-- Update UI
	smoothHide(MenuFrame)
	smoothHide(ResultFrame)
	smoothShow(MeditationFrame)

	local discipline = data.Difficulty.Discipline
	InfoFrame.DisciplineLabel.Text = discipline.Name
	-- Capitalize chi name to match Colors.Chi table
	local chiName = discipline.Chi:sub(1, 1):upper() .. discipline.Chi:sub(2)
	InfoFrame.DisciplineLabel.TextColor3 = MeditationConfig.Colors.Chi[chiName] or MeditationConfig.Colors.Chi.White
	InfoFrame.LevelLabel.Text = "Level " .. data.Level
	InfoFrame.PathLabel.Text = "Path Length: " .. data.Difficulty.PathLength
	InfoFrame.ProgressLabel.Text = "Flow Progress: 0 / " .. #data.ChiPath
	InfoFrame.WisdomLabel.Text = data.Wisdom

	-- Begin chi flow visualization
	task.wait(0.5)
	local chiColor = MeditationConfig.GetChiColor(data.Level)
	showChiFlow(data.ChiPath, data.Difficulty.FlowTime, chiColor)
end)

-- Handle enlightenment (results)
EnlightenmentEvent.OnClientEvent:Connect(function(data)
	if data.Success then
		-- Harmony achieved!
		if Sounds.Harmony then
			Sounds.Harmony:Play()
		end

		InfoFrame.StateLabel.Text = data.PerfectFlow and "PERFECT HARMONY!" or "HARMONY ACHIEVED"
		InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Correct

		-- Show enlightenment gain
		local enlightenmentPopup = InfoFrame.EnlightenmentPopup
		local popupText = "+" .. data.Enlightenment .. " Enlightenment"
		if data.Mindful then
			popupText ..= "\n✨ Mindful Bonus"
		end
		if data.PerfectFlow then
			popupText ..= "\n🔥 Perfect Flow!"
		end

		enlightenmentPopup.Text = popupText
		enlightenmentPopup.Visible = true
		enlightenmentPopup.TextTransparency = 1
		enlightenmentPopup.Position = UDim2.new(0.5, 0, 0.5, 0)

		local popupTween = TweenService:Create(enlightenmentPopup, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
			TextTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.35, 0)
		})
		popupTween:Play()

		-- Wisdom quote
		InfoFrame.WisdomLabel.Text = data.Wisdom

		task.wait(3)

		-- Fade out popup
		TweenService:Create(enlightenmentPopup, TweenInfo.new(0.4), {
			TextTransparency = 1
		}):Play()

		-- Setup next level
		MeditationState.CurrentLevel = data.Level
		MeditationState.CurrentPath = data.NextPath
		MeditationState.CurrentDifficulty = data.NextDifficulty
		MeditationState.IsMeditating = true

		local discipline = data.NextDifficulty.Discipline
		InfoFrame.DisciplineLabel.Text = discipline.Name
		-- Capitalize chi name to match Colors.Chi table
		local chiName = discipline.Chi:sub(1, 1):upper() .. discipline.Chi:sub(2)
		InfoFrame.DisciplineLabel.TextColor3 = MeditationConfig.Colors.Chi[chiName] or MeditationConfig.Colors.Chi.White
		InfoFrame.LevelLabel.Text = "Level " .. data.Level
		InfoFrame.PathLabel.Text = "Path Length: " .. data.NextDifficulty.PathLength
		InfoFrame.HarmonyLabel.Text = "Harmony: x" .. data.Harmony
		InfoFrame.ChiLabel.Text = "Energy: " .. data.Chi .. "%"

		task.wait(0.5)
		local chiColor = MeditationConfig.GetChiColor(data.Level)
		showChiFlow(data.NextPath, data.NextDifficulty.FlowTime, chiColor)

	else
		-- Flow disrupted
		if Sounds.Disruption then
			Sounds.Disruption:Play()
		end

		MeditationState.IsMeditating = false

		InfoFrame.StateLabel.Text = "FLOW DISRUPTED"
		InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Incorrect
		InfoFrame.WisdomLabel.Text = data.Wisdom

		task.wait(3)

		-- Show results
		smoothHide(MeditationFrame)

		local discipline = MeditationConfig.GetDiscipline(data.FinalLevel)
		ResultFrame.DisciplineLabel.Text = "Discipline: " .. discipline.Name
		ResultFrame.LevelLabel.Text = "Level Reached: " .. data.FinalLevel
		ResultFrame.EnlightenmentLabel.Text = "Total Enlightenment: " .. data.FinalEnlightenment
		ResultFrame.BestLabel.Text = "Highest Level: " .. data.HighestLevel
		ResultFrame.PerfectLabel.Text = "Perfect Flows: " .. data.PerfectFlows
		ResultFrame.WisdomLabel.Text = data.Wisdom

		smoothShow(ResultFrame)
	end
end)

-- Menu button handlers
local OpenButton = MainUI:WaitForChild("OpenMeditationButton")

OpenButton.Activated:Connect(function()
	smoothShow(MenuFrame)
end)

MenuFrame.BeginButton.Activated:Connect(function()
	BeginMeditationEvent:FireServer()
end)

MenuFrame.CloseMenuButton.Activated:Connect(function()
	smoothHide(MenuFrame)
end)

MeditationFrame.ExitMeditationButton.Activated:Connect(function()
	-- Exit meditation early
	MeditationState.IsMeditating = false
	MeditationState.IsShowingFlow = false
	smoothHide(MeditationFrame)
end)

ResultFrame.MeditateAgainButton.Activated:Connect(function()
	BeginMeditationEvent:FireServer()
end)

ResultFrame.ReturnButton.Activated:Connect(function()
	smoothHide(ResultFrame)
	smoothShow(MenuFrame)
end)

-- Initialize
createMandalaGrid()
-- Don't show menu automatically - player clicks button to open

print("🧘 Meditation & Martial Arts Training - Client Ready")