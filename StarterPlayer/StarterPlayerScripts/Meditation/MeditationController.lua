--[[
	MeditationController_Enhanced.lua (StarterPlayerScripts)
	?? ENHANCED VERSION - Spectacular chi flow visualization with particles and effects
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
	Stones = {},
	ChiParticles = {},
	IsTracing = false,
	LastTouchedStone = nil,
	TracedStones = {},
	TraceStartTime = 0
}

-- Sound system
local Sounds = {}

local function createSound(name: string, soundId: string, volume: number): Sound?
	if soundId == "" then
		return nil
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

-- Start ambient music
if Sounds.TempleAmbience then
	Sounds.TempleAmbience.Looped = true
	Sounds.TempleAmbience:Play()
end

-- UI Helpers
local function smoothShow(frame: Frame)
	frame.Visible = true
	frame.BackgroundTransparency = 1
	-- Hide HUD when any significant frame opens
	if frame == MeditationFrame or frame == MenuFrame or frame == ResultFrame then
		if _G.HideHUD then _G.HideHUD() end
	end
	-- Fade in with scale animation
	local originalSize = frame.Size
	frame.Size = UDim2.new(
		originalSize.X.Scale * 0.9,
		originalSize.X.Offset * 0.9,
		originalSize.Y.Scale * 0.9,
		originalSize.Y.Offset * 0.9
	)
	local fadeIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
		Size = originalSize
	})
	fadeIn:Play()
end

local function smoothHide(frame: Frame)
	local fadeOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1
	})
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		frame.Visible = false
		-- Now check AFTER the frame is actually hidden
		if frame == MeditationFrame or frame == MenuFrame or frame == ResultFrame then
			local anyVisible = MeditationFrame.Visible or MenuFrame.Visible or ResultFrame.Visible
			if not anyVisible and _G.ShowHUD then _G.ShowHUD() end
		end
	end)
end

-- ============================================================================
-- ENHANCED PARTICLE EFFECTS
-- ============================================================================

local function createChiParticles(parent: GuiObject, color: Color3): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	particles.Rate = 40
	particles.Lifetime = NumberRange.new(0.6, 1.2)
	particles.Speed = NumberRange.new(3, 6)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-100, 100)
	particles.Color = ColorSequence.new(color)
	particles.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(1, 1)
	}
	particles.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 0.6),
		NumberSequenceKeypoint.new(1, 0.2)
	}
	particles.LightEmission = 1
	particles.LightInfluence = 0
	particles.ZOffset = 1
	particles.Parent = parent

	return particles
end

local function createExplosionEffect(parent: GuiObject, color: Color3)
	-- Burst particles
	local burst = Instance.new("ParticleEmitter")
	burst.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	burst.Rate = 0
	burst.Lifetime = NumberRange.new(0.4, 0.8)
	burst.Speed = NumberRange.new(8, 15)
	burst.SpreadAngle = Vector2.new(180, 180)
	burst.Color = ColorSequence.new(color)
	burst.Transparency = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1)
	}
	burst.Size = NumberSequence.new{
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0)
	}
	burst.LightEmission = 1
	burst.ZOffset = 2
	burst.Parent = parent

	burst:Emit(30)

	task.delay(1.5, function()
		burst:Destroy()
	end)

	return burst
end

local function createChiTrail(stone: TextButton, targetStone: TextButton, color: Color3)
	-- Create a beam-like effect using a Frame
	local trail = Instance.new("Frame")
	trail.Name = "ChiTrail"
	trail.BackgroundColor3 = color
	trail.BorderSizePixel = 0
	trail.ZIndex = 1
	trail.Parent = MandalaGrid

	-- Calculate position and size
	local startPos = stone.AbsolutePosition
	local endPos = targetStone.AbsolutePosition
	local midX = (startPos.X + endPos.X) / 2
	local midY = (startPos.Y + endPos.Y) / 2

	local deltaX = endPos.X - startPos.X
	local deltaY = endPos.Y - startPos.Y
	local distance = math.sqrt(deltaX^2 + deltaY^2)
	local angle = math.deg(math.atan2(deltaY, deltaX))

	trail.Size = UDim2.new(0, distance, 0, 4)
	trail.Position = UDim2.new(0, midX - distance/2, 0, midY - 2)
	trail.Rotation = angle
	trail.AnchorPoint = Vector2.new(0.5, 0.5)

	-- Gradient effect
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, color)
	}
	gradient.Parent = trail

	-- Glow
	local glow = Instance.new("UIStroke")
	glow.Color = color
	glow.Thickness = 3
	glow.Transparency = 0.3
	glow.Parent = trail

	-- Animate in
	trail.BackgroundTransparency = 1
	glow.Transparency = 1

	TweenService:Create(trail, TweenInfo.new(0.2), {
		BackgroundTransparency = 0.3
	}):Play()

	TweenService:Create(glow, TweenInfo.new(0.2), {
		Transparency = 0
	}):Play()

	-- Fade out after a bit
	task.delay(0.5, function()
		TweenService:Create(trail, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()

		TweenService:Create(glow, TweenInfo.new(0.3), {
			Transparency = 1
		}):Play()

		task.wait(0.3)
		trail:Destroy()
	end)
end

-- ============================================================================
-- CREATE MEDITATION STONE GRID
-- ============================================================================

local function createMandalaGrid()
	-- Clear existing stones
	for _, stone in pairs(MeditationState.Stones) do
		stone:Destroy()
	end
	MeditationState.Stones = {}

	if not MandalaGrid then
		warn("? MandalaGrid not found!")
		return
	end

	local gridSize = MeditationConfig.GridSize
	local stoneSize = UDim2.new(0.20, 0, 0.20, 0)
	local spacing = 0.03

	print("Creating " .. (gridSize * gridSize) .. " meditation stones...")

	for row = 0, gridSize - 1 do
		for col = 0, gridSize - 1 do
			local stoneIndex = row * gridSize + col + 1

			-- Create stone
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
			stone.Text = "" -- No numbers in production
			stone.TextColor3 = Color3.fromRGB(150, 150, 150)
			stone.TextScaled = true
			stone.AutoButtonColor = false
			stone.Visible = true
			stone.ZIndex = 2
			stone.Parent = MandalaGrid

			-- Rounded corners
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0.2, 0)
			corner.Parent = stone

			-- Glowing stroke
			local glow = Instance.new("UIStroke")
			glow.Name = "Glow"
			glow.Color = Color3.fromRGB(100, 200, 255)
			glow.Thickness = 0
			glow.Transparency = 0.5
			glow.Parent = stone

			-- Inner shadow/depth
			local gradient = Instance.new("UIGradient")
			gradient.Color = ColorSequence.new{
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 120))
			}
			gradient.Transparency = NumberSequence.new{
				NumberSequenceKeypoint.new(0, 0.7),
				NumberSequenceKeypoint.new(1, 0.3)
			}
			gradient.Rotation = 45
			gradient.Parent = stone

			-- Store reference
			MeditationState.Stones[stoneIndex] = stone

			-- Input handlers
			stone.InputBegan:Connect(function(input)
				if not (MeditationState.IsMeditating and not MeditationState.IsShowingFlow) then
					return
				end

				if input.UserInputType == Enum.UserInputType.MouseButton1 or 
					input.UserInputType == Enum.UserInputType.Touch then
					startTracing(stoneIndex)
				end
			end)

			stone.MouseEnter:Connect(function()
				if MeditationState.IsTracing then
					continueTracing(stoneIndex)
				end
			end)
		end
	end

	-- Global input handlers
	local UserInputService = game:GetService("UserInputService")

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or
			input.UserInputType == Enum.UserInputType.Touch then
			endTracing()
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and MeditationState.IsTracing then
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

	print("? Created " .. #MeditationState.Stones .. " meditation stones with effects!")
end

-- ============================================================================
-- SPECTACULAR CHI FLOW ANIMATION
-- ============================================================================

local function flowChiThroughStone(stoneIndex: number, chiColor: Color3, duration: number, glowIntensity: number)
	local stone = MeditationState.Stones[stoneIndex]
	if not stone then return end

	local glow = stone:FindFirstChild("Glow")

	-- EXPLOSIVE PARTICLE EFFECT
	if MeditationConfig.Effects.EnableParticles then
		createChiParticles(stone, chiColor)
		createExplosionEffect(stone, chiColor)
	end

	-- INTENSE GLOW PULSE
	if glow and MeditationConfig.Effects.EnableGlow then
		-- Pulse multiple times
		for i = 1, 2 do
			TweenService:Create(glow, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Thickness = glowIntensity * 1.5,
				Transparency = 0,
				Color = chiColor
			}):Play()

			task.wait(0.15)

			TweenService:Create(glow, TweenInfo.new(0.1), {
				Thickness = glowIntensity,
				Transparency = 0.2
			}):Play()

			task.wait(0.1)
		end
	end

	-- VIBRANT COLOR FLOW with bounce
	local colorTween = TweenService:Create(stone, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundColor3 = chiColor,
		Size = UDim2.new(
			stone.Size.X.Scale * 1.1,
			stone.Size.X.Offset * 1.1,
			stone.Size.Y.Scale * 1.1,
			stone.Size.Y.Offset * 1.1
		)
	})
	colorTween:Play()

	-- Hold the chi
	task.wait(duration)

	-- Release with elegant fade
	if glow then
		TweenService:Create(glow, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Thickness = 0,
			Transparency = 0.8
		}):Play()
	end

	local releaseTween = TweenService:Create(stone, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundColor3 = MeditationConfig.Colors.Chi.Dormant,
		Size = UDim2.new(0.20, 0, 0.20, 0)
	})
	releaseTween:Play()
end

-- Show the chi flow path with trails
local function showChiFlow(path: {number}, flowTime: number, chiColor: Color3)
	MeditationState.IsShowingFlow = true
	MeditationState.PlayerPath = {}
	MeditationState.TracedStones = {}

	InfoFrame.WisdomLabel.Text = MeditationConfig.TechniqueDescriptions[1]
	InfoFrame.StateLabel.Text = "? OBSERVE THE ENERGY ?"
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.Accent

	-- Breathing preparation
	print("   Preparation phase...")
	task.wait(MeditationConfig.MeditationPrepareTime)

	if Sounds.BreathIn then
		Sounds.BreathIn:Play()
	end

	print("   Displaying chi flow sequence...")

	-- Show path with connecting trails
	for i, stoneIndex in ipairs(path) do
		print("   Stone " .. i .. "/" .. #path .. " - Index: " .. stoneIndex)

		if Sounds.ChiFlow then
			Sounds.ChiFlow:Play()
		end

		-- Create trail to previous stone
		if i > 1 then
			local prevStone = MeditationState.Stones[path[i-1]]
			local currentStone = MeditationState.Stones[stoneIndex]
			if prevStone and currentStone then
				createChiTrail(prevStone, currentStone, chiColor)
			end
		end

		-- Spectacular chi flow
		flowChiThroughStone(stoneIndex, chiColor, flowTime, 6)

		task.wait(flowTime + MeditationConfig.ExhaleTime)

		if i < #path and Sounds.BreathOut then
			Sounds.BreathOut:Play()
		end
	end

	MeditationState.IsShowingFlow = false

	-- Player's turn
	InfoFrame.StateLabel.Text = "?? RECREATE THE FLOW ??"
	InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	InfoFrame.WisdomLabel.Text = "Trust your instincts. Feel the energy."
end

-- ============================================================================
-- TRACING FUNCTIONS
-- ============================================================================

function startTracing(stoneIndex: number)
	if MeditationState.IsTracing then return end

	MeditationState.IsTracing = true
	MeditationState.LastTouchedStone = stoneIndex
	MeditationState.PlayerPath = {}
	MeditationState.TracedStones = {}
	MeditationState.TraceStartTime = tick()

	table.insert(MeditationState.PlayerPath, stoneIndex)
	MeditationState.TracedStones[stoneIndex] = true

	if Sounds.ChiFlow then
		Sounds.ChiFlow:Play()
	end

	local chiColor = MeditationConfig.GetChiColor(MeditationState.CurrentLevel)
	flowChiThroughStone(stoneIndex, Color3.fromRGB(255, 215, 0), 0.5, 4)

	InfoFrame.StateLabel.Text = "? TRACING PATH... ?"
	InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

	local progressText = string.format("%d / %d", #MeditationState.PlayerPath, #MeditationState.CurrentPath)
	InfoFrame.ProgressLabel.Text = "Progress: " .. progressText

	print("?? Started tracing at stone " .. stoneIndex)
end

function continueTracing(stoneIndex: number)
	if not MeditationState.IsTracing then return end
	if MeditationState.TracedStones[stoneIndex] then return end
	if stoneIndex == MeditationState.LastTouchedStone then return end

	table.insert(MeditationState.PlayerPath, stoneIndex)
	MeditationState.TracedStones[stoneIndex] = true

	-- Create trail from last stone
	local lastStone = MeditationState.Stones[MeditationState.LastTouchedStone]
	local currentStone = MeditationState.Stones[stoneIndex]
	if lastStone and currentStone then
		createChiTrail(lastStone, currentStone, Color3.fromRGB(255, 215, 0))
	end

	MeditationState.LastTouchedStone = stoneIndex

	if Sounds.ChiFlow then
		Sounds.ChiFlow:Play()
	end

	flowChiThroughStone(stoneIndex, Color3.fromRGB(255, 215, 0), 0.5, 4)

	local progressText = string.format("%d / %d", #MeditationState.PlayerPath, #MeditationState.CurrentPath)
	InfoFrame.ProgressLabel.Text = "Progress: " .. progressText

	print("?? Traced through stone " .. stoneIndex)
end

function endTracing()
	if not MeditationState.IsTracing then return end

	MeditationState.IsTracing = false

	local traceTime = tick() - MeditationState.TraceStartTime
	print("?? Ended trace - " .. #MeditationState.PlayerPath .. " stones in " .. string.format("%.1f", traceTime) .. "s")

	if #MeditationState.PlayerPath >= #MeditationState.CurrentPath then
		InfoFrame.StateLabel.Text = "? FLOW COMPLETE!"
		InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(100, 255, 150)
		task.wait(0.5)
		submitFlow()
	else
		InfoFrame.StateLabel.Text = "? INCOMPLETE - TRY AGAIN"
		InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

		task.wait(1)
		if not MeditationState.IsShowingFlow and MeditationState.IsMeditating then
			MeditationState.PlayerPath = {}
			MeditationState.TracedStones = {}
			InfoFrame.StateLabel.Text = "?? RECREATE THE FLOW ??"
			InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
			InfoFrame.ProgressLabel.Text = "Progress: 0 / " .. #MeditationState.CurrentPath
		end
	end
end

function submitFlow()
	MeditationState.IsMeditating = false
	InfoFrame.StateLabel.Text = "? HARMONIZING..."
	InfoFrame.StateLabel.TextColor3 = MeditationConfig.Colors.TextSecondary

	SubmitFlowEvent:FireServer(MeditationState.PlayerPath)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

BeginMeditationEvent.OnClientEvent:Connect(function(data)
	MeditationState.IsMeditating = true
	MeditationState.CurrentLevel = data.Level
	MeditationState.CurrentPath = data.ChiPath
	MeditationState.CurrentDifficulty = data.Difficulty

	smoothHide(MenuFrame)
	smoothHide(ResultFrame)
	smoothShow(MeditationFrame)

	local discipline = data.Difficulty.Discipline
	InfoFrame.DisciplineLabel.Text = discipline.Name
	local chiName = discipline.Chi:sub(1, 1):upper() .. discipline.Chi:sub(2)
	InfoFrame.DisciplineLabel.TextColor3 = MeditationConfig.Colors.Chi[chiName] or MeditationConfig.Colors.Chi.White
	InfoFrame.LevelLabel.Text = "Level " .. data.Level
	InfoFrame.PathLabel.Text = "Path: " .. data.Difficulty.PathLength
	InfoFrame.ProgressLabel.Text = "Progress: 0 / " .. #data.ChiPath
	InfoFrame.WisdomLabel.Text = data.Wisdom

	task.wait(0.5)
	local chiColor = MeditationConfig.GetChiColor(data.Level)
	showChiFlow(data.ChiPath, data.Difficulty.FlowTime, chiColor)
end)

EnlightenmentEvent.OnClientEvent:Connect(function(data)
	if data.Success then
		if Sounds.Harmony then
			Sounds.Harmony:Play()
		end

		InfoFrame.StateLabel.Text = data.PerfectFlow and "?? PERFECT HARMONY! ??" or "? HARMONY ACHIEVED ?"
		InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(100, 255, 150)

		-- Spectacular enlightenment popup
		local enlightenmentPopup = InfoFrame.EnlightenmentPopup
		local popupText = "+" .. data.Enlightenment .. " Enlightenment"
		if data.Mindful then
			popupText ..= "\n? Mindful Bonus"
		end
		if data.PerfectFlow then
			popupText ..= "\n?? PERFECT FLOW!"
		end

		enlightenmentPopup.Text = popupText
		enlightenmentPopup.Visible = true
		enlightenmentPopup.TextTransparency = 1
		enlightenmentPopup.Position = UDim2.new(0.5, 0, 0.5, 0)

		-- Create explosion effect
		createExplosionEffect(enlightenmentPopup, Color3.fromRGB(255, 215, 0))

		local popupTween = TweenService:Create(enlightenmentPopup, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			Position = UDim2.new(0.5, 0, 0.3, 0),
			TextStrokeTransparency = 0
		})
		popupTween:Play()

		InfoFrame.WisdomLabel.Text = data.Wisdom

		task.wait(3)

		TweenService:Create(enlightenmentPopup, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()

		-- Continue to next level
		MeditationState.CurrentLevel = data.Level
		MeditationState.CurrentPath = data.NextPath
		MeditationState.CurrentDifficulty = data.NextDifficulty
		MeditationState.IsMeditating = true

		local discipline = data.NextDifficulty.Discipline
		InfoFrame.DisciplineLabel.Text = discipline.Name
		local chiName = discipline.Chi:sub(1, 1):upper() .. discipline.Chi:sub(2)
		InfoFrame.DisciplineLabel.TextColor3 = MeditationConfig.Colors.Chi[chiName] or MeditationConfig.Colors.Chi.White
		InfoFrame.LevelLabel.Text = "Level " .. data.Level
		InfoFrame.PathLabel.Text = "Path: " .. data.NextDifficulty.PathLength
		InfoFrame.HarmonyLabel.Text = "Harmony: x" .. data.Harmony
		InfoFrame.ChiLabel.Text = "Energy: " .. data.Chi .. "%"

		task.wait(0.5)
		local chiColor = MeditationConfig.GetChiColor(data.Level)
		showChiFlow(data.NextPath, data.NextDifficulty.FlowTime, chiColor)

	else
		if Sounds.Disruption then
			Sounds.Disruption:Play()
		end

		MeditationState.IsMeditating = false

		InfoFrame.StateLabel.Text = "?? FLOW DISRUPTED"
		InfoFrame.StateLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		InfoFrame.WisdomLabel.Text = data.Wisdom

		task.wait(3)

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

print("?? ENHANCED Meditation Controller - Ready with SPECTACULAR effects!")