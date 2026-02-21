--[[
	ClickerController.lua (StarterPlayer/StarterPlayerScripts - LocalScript)
	Client-side game logic for the Clicker mini-game.
	Handles target spawning, clicking, animations and HUD updates.

	SETUP REMINDER:
	Replace image IDs in ClickerConfig with your own:
	  "rbxassetid://YOUR_ID_HERE"
--]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService     = game:GetService("TweenService")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ClickerConfig = require(ReplicatedStorage:WaitForChild("ClickerConfig"))

-- Wait for RemoteEvents
local ClickerEvents      = ReplicatedStorage:WaitForChild("ClickerEvents", 15)
local BeginClickerEvent  = ClickerEvents:WaitForChild("BeginClicker")
local TargetClickedEvent = ClickerEvents:WaitForChild("TargetClicked")
local TargetMissedEvent  = ClickerEvents:WaitForChild("TargetMissed")
local EndClickerEvent    = ClickerEvents:WaitForChild("EndClicker")
local RegisterTargetEvent = ClickerEvents:WaitForChild("RegisterTarget")
local SessionUpdateEvent = ClickerEvents:WaitForChild("SessionUpdate")
local GameOverEvent      = ClickerEvents:WaitForChild("GameOver")

-- Wait for UI (built by ClickerUIBuilder)
local ClickerUI     = playerGui:WaitForChild("ClickerUI", 15)
local OpenBtn       = ClickerUI:WaitForChild("OpenClickerButton")
local MenuFrame     = ClickerUI:WaitForChild("MenuFrame")
local GameFrame     = ClickerUI:WaitForChild("GameFrame")
local ResultFrame   = ClickerUI:WaitForChild("ResultFrame")

-- HUD refs
local HUD           = GameFrame:WaitForChild("HUD")
local LevelLabel    = HUD:WaitForChild("LevelLabel")
local LevelBarFg    = HUD:WaitForChild("LevelBarBg"):WaitForChild("LevelBarFg")
local ScoreLabel    = HUD:WaitForChild("ScoreLabel")
local ComboLabel    = HUD:WaitForChild("ComboLabel")
local ExitButton    = HUD:WaitForChild("ExitButton")
local TargetArea    = GameFrame:WaitForChild("TargetArea")
local FeedbackLabel = GameFrame:WaitForChild("FeedbackLabel")
local LevelUpPopup  = GameFrame:WaitForChild("LevelUpPopup")

-- Menu refs
local BestScoreLabel = MenuFrame:WaitForChild("StatsRow"):WaitForChild("BestScoreLabel")
local BestLevelLabel = MenuFrame:WaitForChild("StatsRow"):WaitForChild("BestLevelLabel")

-- Result refs
local ResultLevel    = ResultFrame:WaitForChild("ResultLevel")
local ResultScore    = ResultFrame:WaitForChild("ResultScore")
local ResultClicks   = ResultFrame:WaitForChild("ResultClicks")
local ResultMisses   = ResultFrame:WaitForChild("ResultMisses")
local ResultCombo    = ResultFrame:WaitForChild("ResultCombo")
local ResultXP       = ResultFrame:WaitForChild("ResultXP")
local ResultBestScore = ResultFrame:WaitForChild("ResultBestScore")

-- ============================================================
-- SOUNDS
-- ============================================================

local Sounds = {}
for name, id in pairs(ClickerConfig.Sounds) do
	if id ~= "" then
		local s = Instance.new("Sound")
		s.Name     = name
		s.SoundId  = id
		s.Volume   = 0.5
		s.Parent   = SoundService
		Sounds[name] = s
	end
end

local function playSound(name)
	local s = Sounds[name]
	if s then s:Play() end
end

-- ============================================================
-- STATE
-- ============================================================

local GameState = {
	IsPlaying       = false,
	Level           = 1,
	Score           = 0,
	ClicksThisLevel = 0,
	ClicksNeeded    = ClickerConfig.ClicksToLevelUp,
	Combo           = 0,
	TargetCount     = 1,
	Lifetime        = ClickerConfig.TargetLifetimeBase,
	TargetSize      = ClickerConfig.TargetSizeBase,
	ActiveTargets   = {},   -- { [targetId] = { button, timerConn, expireAt } }
	SpawnThreads    = {},   -- coroutines/tasks to cancel on exit
}

-- Simple GUID generator for target IDs
local guidCounter = 0
local function newId()
	guidCounter += 1
	return tostring(player.UserId) .. "_" .. tostring(guidCounter) .. "_" .. tostring(tick())
end

-- ============================================================
-- FEEDBACK POPUP
-- ============================================================

local feedbackTween = nil

local function showFeedback(text, color, x, y)
	if feedbackTween then feedbackTween:Cancel() end
	local stroke = FeedbackLabel:FindFirstChildOfClass("UIStroke")

	FeedbackLabel.Text       = text
	FeedbackLabel.TextColor3 = color or ClickerConfig.Colors.HitColor
	FeedbackLabel.Position   = UDim2.new(x or 0.35, 0, y or 0.4, 0)
	FeedbackLabel.TextTransparency = 0
	FeedbackLabel.Visible    = true
	if stroke then stroke.Transparency = 0 end

	feedbackTween = TweenService:Create(FeedbackLabel,
		TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1,
			Position = UDim2.new(x or 0.35, 0, (y or 0.4) - 0.06, 0),
		})
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	end
	feedbackTween:Play()
	feedbackTween.Completed:Connect(function()
		FeedbackLabel.Visible = false
	end)
end

-- ============================================================
-- LEVEL UP POPUP
-- ============================================================

local function showLevelUp(msg)
	local stroke = LevelUpPopup:FindFirstChildOfClass("UIStroke")

	LevelUpPopup.Text             = msg or "? LEVEL UP!"
	LevelUpPopup.TextTransparency = 1
	LevelUpPopup.Visible          = true
	LevelUpPopup.Size             = UDim2.new(0.4, 0, 0.08, 0)
	if stroke then stroke.Transparency = 1 end

	local tIn = TweenService:Create(LevelUpPopup,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			Size = UDim2.new(0.6, 0, 0.1, 0),
		})
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(0.25), { Transparency = 0 }):Play()
	end
	tIn:Play()
	tIn.Completed:Connect(function()
		task.wait(0.8)
		TweenService:Create(LevelUpPopup,
			TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		end
	end)
end
-- ============================================================
-- UPDATE HUD
-- ============================================================

local function updateHUD(data)
	LevelLabel.Text = "LVL " .. data.Level

	-- Level progress bar
	local ratio = math.clamp(data.ClicksThisLevel / data.ClicksNeeded, 0, 1)
	TweenService:Create(LevelBarFg,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()

	-- Score (pop animation when changes)
	if data.ScoreGained and data.ScoreGained > 0 then
		ScoreLabel.Text = tostring(data.TotalScore)
		TweenService:Create(ScoreLabel,
			TweenInfo.new(0.05), { TextSize = 32 }):Play()
		task.delay(0.05, function()
			TweenService:Create(ScoreLabel,
				TweenInfo.new(0.1), { TextSize = 28 }):Play()
		end)
	end

	-- Combo
	local combo = data.Combo or 1
	ComboLabel.Text = "x" .. combo
	if combo >= 5 then
		ComboLabel.TextColor3 = ClickerConfig.Colors.AccentHot
	elseif combo >= 2 then
		ComboLabel.TextColor3 = ClickerConfig.Colors.ComboColor
	else
		ComboLabel.TextColor3 = ClickerConfig.Colors.HitColor
	end
end

-- ============================================================
-- TARGET: SPAWN
-- ============================================================

local function removeTarget(targetId, missed)
	local entry = GameState.ActiveTargets[targetId]
	if not entry then return end

	-- Cancel timer
	if entry.timerConn then entry.timerConn:Disconnect() end

	-- Destroy button
	if entry.button and entry.button.Parent then
		entry.button:Destroy()
	end

	GameState.ActiveTargets[targetId] = nil

	if missed then
		TargetMissedEvent:FireServer(targetId)
	end
end

local function spawnTarget()
	if not GameState.IsPlaying then return end

	local targetId = newId()

	-- Pick a random cell position inside TargetArea, avoiding HUD overlap
	local areaW = TargetArea.AbsoluteSize.X
	local areaH = TargetArea.AbsoluteSize.Y
	local sz    = GameState.TargetSize

	-- Margin so target stays fully on screen
	local margin = sz / 2 + 5
	local randX  = math.random(margin, math.max(margin + 1, areaW - margin))
	local randY  = math.random(margin, math.max(margin + 1, areaH - margin))

	-- Create the ImageButton
	local btn = Instance.new("ImageButton")
	btn.Name             = "Target_" .. targetId
	btn.Size             = UDim2.new(0, sz, 0, sz)
	btn.Position         = UDim2.new(0, randX - sz / 2, 0, randY - sz / 2)
	btn.BackgroundTransparency = 1
	btn.BorderSizePixel  = 0
	btn.AutoButtonColor  = false
	btn.ZIndex           = 20
	-- Pick a random image from config
	local images = ClickerConfig.Images
	btn.Image = images[math.random(1, #images)]
	btn.ScaleType = Enum.ScaleType.Fit  -- ADD THIS LINE
	btn.Parent = TargetArea

	-- Pop-in animation
	btn.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(btn,
		TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, sz, 0, sz)
		}):Play()

	-- Urgency shrink: target slowly shrinks as it approaches expiry
	local lifetime = GameState.Lifetime
	local shrinkTarget = math.max(sz * 0.6, ClickerConfig.TargetSizeMin)
	local shrinkTween = TweenService:Create(btn,
		TweenInfo.new(lifetime, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, shrinkTarget, 0, shrinkTarget)
		})
	shrinkTween:Play()

	-- Store reference
	local expireAt = tick() + lifetime
	local entry = { button = btn, timerConn = nil, expireAt = expireAt }
	GameState.ActiveTargets[targetId] = entry

	-- Register with server for validation
	RegisterTargetEvent:FireServer(targetId)

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		if not GameState.IsPlaying then return end
		if not GameState.ActiveTargets[targetId] then return end

		-- Click animation (quick burst)
		TweenService:Create(btn,
			TweenInfo.new(0.06, Enum.EasingStyle.Bounce), {
				Size = UDim2.new(0, sz * 1.35, 0, sz * 1.35),
				ImageTransparency = 1,
			}):Play()

		removeTarget(targetId, false)
		playSound("Hit")
		TargetClickedEvent:FireServer(targetId)

		-- Feedback position (relative to target in screen space)
		local abPos  = btn.AbsolutePosition
		local screenW = TargetArea.AbsoluteSize.X
		local screenH = TargetArea.AbsoluteSize.Y
		local fx = math.clamp((abPos.X + sz / 2) / screenW - 0.1, 0, 0.8)
		local fy = math.clamp((abPos.Y + 70)     / (screenH + 70) - 0.05, 0.05, 0.85)
		showFeedback("+HIT!", ClickerConfig.Colors.HitColor, fx, fy)
	end)

	-- Expire timer
	local timerConn
	timerConn = RunService.Heartbeat:Connect(function()
		if tick() >= expireAt then
			timerConn:Disconnect()
			if GameState.ActiveTargets[targetId] then
				-- Flash red before disappearing
				TweenService:Create(btn,
					TweenInfo.new(0.15), { ImageTransparency = 0.7 }):Play()
				task.wait(0.15)
				removeTarget(targetId, true)
				playSound("Miss")
				showFeedback("MISS!", ClickerConfig.Colors.MissColor)
			end
		end
	end)
	entry.timerConn = timerConn
end

-- ============================================================
-- TARGET: SPAWN LOOP
-- ============================================================

local function startSpawnLoop()
	-- Spawns the correct number of targets and keeps them refreshed
	local spawnTask = task.spawn(function()
		-- Initial burst
		for _ = 1, GameState.TargetCount do
			spawnTarget()
			task.wait(0.05)
		end

		while GameState.IsPlaying do
			-- Count living targets
			local alive = 0
			for _ in pairs(GameState.ActiveTargets) do alive += 1 end

			-- Spawn up to the required count
			while alive < GameState.TargetCount and GameState.IsPlaying do
				spawnTarget()
				alive += 1
				task.wait(ClickerConfig.GetSpawnDelay(GameState.Level))
			end

			task.wait(0.05) -- Tight loop is fine; most time is spent waiting in targets
		end
	end)
	table.insert(GameState.SpawnThreads, spawnTask)
end

-- ============================================================
-- CLEAR ALL TARGETS
-- ============================================================

local function clearAllTargets()
	for targetId, entry in pairs(GameState.ActiveTargets) do
		if entry.timerConn then entry.timerConn:Disconnect() end
		if entry.button and entry.button.Parent then entry.button:Destroy() end
	end
	GameState.ActiveTargets = {}
end

-- ============================================================
-- START / END GAME
-- ============================================================

local function startGame()
	GameState.IsPlaying       = true
	GameState.Level           = 1
	GameState.Score           = 0
	GameState.ClicksThisLevel = 0
	GameState.Combo           = 0
	GameState.ActiveTargets   = {}
	GameState.SpawnThreads    = {}

	MenuFrame.Visible   = false
	ResultFrame.Visible = false
	GameFrame.Visible   = true
	if _G.HideHUD then _G.HideHUD() end

	-- Reset HUD
	ScoreLabel.Text = "0"
	ComboLabel.Text = "x1"
	LevelLabel.Text = "LVL 1"
	LevelBarFg.Size = UDim2.new(0, 0, 1, 0)

	BeginClickerEvent:FireServer()
	startSpawnLoop()
end

local function endGame()
	GameState.IsPlaying = false

	-- Cancel spawn loops
	for _, t in ipairs(GameState.SpawnThreads) do
		task.cancel(t)
	end
	GameState.SpawnThreads = {}
	clearAllTargets()

	EndClickerEvent:FireServer()
	GameFrame.Visible = false
	if _G.ShowHUD then _G.ShowHUD() end
end

-- ============================================================
-- SERVER UPDATES
-- ============================================================

SessionUpdateEvent.OnClientEvent:Connect(function(data)
	-- Update local state
	GameState.Level           = data.Level
	GameState.ClicksThisLevel = data.ClicksThisLevel
	GameState.TargetCount     = data.TargetCount
	GameState.Lifetime        = data.Lifetime
	GameState.TargetSize      = data.TargetSize

	updateHUD(data)

	-- Level up
	if data.LeveledUp then
		playSound("LevelUp")
		showLevelUp(data.LevelUpMsg)
	end

	-- Combo sound
	if data.Hit and data.Combo and data.Combo >= 3 then
		playSound("Combo")
	end
end)

GameOverEvent.OnClientEvent:Connect(function(data)
	GameState.IsPlaying = false
	clearAllTargets()
	playSound("GameOver")

	GameFrame.Visible = false

	-- Populate result frame
	ResultFrame:WaitForChild("ResultTitle").Text = "YOU MISSED! ??"
	ResultFrame:WaitForChild("ResultTitle").TextColor3 = Color3.fromRGB(255, 60, 60)
	ResultLevel.Text     = "Level Reached: " .. data.Level
	ResultScore.Text     = "Score: "          .. data.TotalScore
	ResultClicks.Text    = "Clicks: "         .. data.TotalClicks
	ResultMisses.Text    = "Misses: "         .. data.TotalMisses
	ResultCombo.Text     = "Best Combo: x"    .. data.BestCombo
	ResultXP.Text        = "XP Earned: +"     .. data.TotalXP
	ResultBestScore.Text = "All-Time Best: "  .. data.BestScore

	ResultFrame.Visible = true
	if _G.HideHUD then _G.HideHUD() end

	-- Update menu stats
	local cs = player:FindFirstChild("ClickerStats")
	if cs then
		BestScoreLabel.Text = "Best Score: " .. cs.BestScore.Value
		BestLevelLabel.Text = "Best Level: " .. cs.BestLevel.Value
	end
end)

-- ============================================================
-- BUTTON WIRING
-- ============================================================

OpenBtn.MouseButton1Click:Connect(function()
	-- Update menu stats display
	local cs = player:FindFirstChild("ClickerStats")
	if cs then
		BestScoreLabel.Text = "Best Score: " .. cs.BestScore.Value
		BestLevelLabel.Text = "Best Level: " .. cs.BestLevel.Value
	end
	MenuFrame.Visible = not MenuFrame.Visible
	if MenuFrame.Visible then
		if _G.HideHUD then _G.HideHUD() end
	else
		if _G.ShowHUD then _G.ShowHUD() end
	end
end)

MenuFrame:WaitForChild("BeginButton").MouseButton1Click:Connect(function()
	startGame()
end)

MenuFrame:WaitForChild("CloseMenuButton").MouseButton1Click:Connect(function()
	MenuFrame.Visible = false
	if _G.ShowHUD then _G.ShowHUD() end
end)

ExitButton.MouseButton1Click:Connect(function()
	endGame()
end)

ResultFrame:WaitForChild("PlayAgainButton").MouseButton1Click:Connect(function()
	ResultFrame.Visible = false
	if _G.ShowHUD then _G.ShowHUD() end
	startGame()
end)

ResultFrame:WaitForChild("ReturnMenuButton").MouseButton1Click:Connect(function()
	ResultFrame.Visible = false
	if _G.ShowHUD then _G.ShowHUD() end
	MenuFrame.Visible   = true
	if _G.HideHUD then _G.HideHUD() end
end)

-- ============================================================
-- HOVER EFFECTS ON BUTTONS
-- ============================================================

local function addHover(btn, normalColor, hoverColor)
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = hoverColor }):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.1), { BackgroundColor3 = normalColor }):Play()
	end)
end

local accent     = ClickerConfig.Colors.Accent
local accentDark = Color3.fromRGB(200, 140, 30)
local dimColor   = Color3.fromRGB(70, 65, 90)
local dimDark    = Color3.fromRGB(90, 85, 115)

addHover(MenuFrame.BeginButton,         accent,   accentDark)
addHover(MenuFrame.CloseMenuButton,     dimColor, dimDark)
addHover(ResultFrame.PlayAgainButton,   accent,   accentDark)
addHover(ResultFrame.ReturnMenuButton,  dimColor, dimDark)

print("?? ClickerController: Ready!")