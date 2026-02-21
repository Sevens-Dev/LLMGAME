-- HUDVisibility
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Central controller for showing/hiding the HP/Stamina HUD bars
-- Any GUI script can call _G.HideHUD() and _G.ShowHUD() without coupling

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Track how many screens are currently requesting the HUD to be hidden
-- This way if two screens open at once, closing one doesn't prematurely show the HUD
local hideRequestCount = 0

local function getHUDContainer()
	local gui = playerGui:FindFirstChild("HealthStaminaBars")
	if gui then
		return gui:FindFirstChild("Container")
	end
	return nil
end

local function setHUDVisible(visible)
	local container = getHUDContainer()
	if not container then return end

	local targetTransparency = visible and 0 or 1

	TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		GroupTransparency = targetTransparency
	}):Play()
end

-- Called by any GUI that wants to hide the HUD
-- Each caller should call ShowHUD() when it closes
_G.HideHUD = function()
	hideRequestCount = hideRequestCount + 1
	if hideRequestCount == 1 then
		setHUDVisible(false)
	end
end

-- Called by any GUI when it closes
_G.ShowHUD = function()
	hideRequestCount = math.max(0, hideRequestCount - 1)
	if hideRequestCount == 0 then
		setHUDVisible(true)
	end
end

-- Force show (safety net - clears all hide requests)
_G.ForceShowHUD = function()
	hideRequestCount = 0
	setHUDVisible(true)
end

print("? HUDVisibility controller loaded")