-- AnimationSpeedLocker
-- This will lock run/walk animation speeds to prevent them from looking ridiculous at high speeds

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid")

-- Configuration: Set these to whatever speed looks good
local LOCKED_RUN_SPEED = 1.0  -- Normal speed
local LOCKED_WALK_SPEED = 1.0 -- Normal speed

print("AnimationSpeedLocker: Initializing for", player.Name)

-- Wait for animator to exist
local animator = humanoid:WaitForChild("Animator", 10)
if not animator then
	return
end


-- Track which animations we've already locked
local lockedTracks = {}

-- Function to lock animation speeds
local function lockAnimationSpeeds()
	local tracks = animator:GetPlayingAnimationTracks()

	for _, track in pairs(tracks) do
		-- Get animation name and ID
		local animName = track.Name:lower()
		local animId = ""
		if track.Animation then
			animId = track.Animation.AnimationId:lower()
		end

		-- Check if this is a movement animation
		local isRun = animName:find("run") or animId:find("run")
		local isWalk = animName:find("walk") or animId:find("walk")

		if isRun then
			if track.Speed ~= LOCKED_RUN_SPEED then
				track:AdjustSpeed(LOCKED_RUN_SPEED)
				if not lockedTracks[track] then
					lockedTracks[track] = true
				end
			end
		elseif isWalk then
			if track.Speed ~= LOCKED_WALK_SPEED then
				track:AdjustSpeed(LOCKED_WALK_SPEED)
				if not lockedTracks[track] then
					lockedTracks[track] = true
				end
			end
		end
	end
end

-- Clean up tracked animations that stopped playing
local function cleanupStoppedTracks()
	local playingTracks = animator:GetPlayingAnimationTracks()
	local playingSet = {}

	for _, track in pairs(playingTracks) do
		playingSet[track] = true
	end

	for track, _ in pairs(lockedTracks) do
		if not playingSet[track] then
			lockedTracks[track] = nil
		end
	end
end

-- Run on every heartbeat to continuously lock speeds
local heartbeatConnection = RunService.Heartbeat:Connect(function()
	lockAnimationSpeeds()
end)

-- Clean up stopped tracks periodically
task.spawn(function()
	while task.wait(2) do
		cleanupStoppedTracks()
	end
end)

-- Also lock when WalkSpeed changes
humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	task.wait(0.1) -- Small delay for animations to update
	lockAnimationSpeeds()
end)

-- Initial lock after a short delay
task.wait(1)
lockAnimationSpeeds()

print("AnimationSpeedLocker: Active and monitoring animations")

-- Cleanup when character is removed
character.AncestryChanged:Connect(function()
	if not character:IsDescendantOf(game) then
		heartbeatConnection:Disconnect()
		print("AnimationSpeedLocker: Disconnected")
	end
end)