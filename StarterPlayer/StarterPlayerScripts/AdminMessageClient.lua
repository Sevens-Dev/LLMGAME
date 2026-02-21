-- AdminMessageClient
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts
-- Displays admin command messages in chat using TextChatService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

print("AdminMessageClient: Starting...")

-- Wait for the AdminMessage remote
local adminMessageRemote = ReplicatedStorage:WaitForChild("AdminMessage", 10)
if not adminMessageRemote then
	warn("AdminMessageClient: AdminMessage RemoteEvent not found!")
	return
end

print("AdminMessageClient: Found AdminMessage RemoteEvent")

-- Get the general text channel
local textChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral", 10)
if not textChannel then
	warn("AdminMessageClient: Could not find RBXGeneral text channel!")
	return
end

print("AdminMessageClient: Connected to text channel")

-- Function to display message in chat
local function displayMessage(message)
	local success = pcall(function()
		textChannel:DisplaySystemMessage("[ADMIN] " .. message)
	end)

	if success then
		print("AdminMessageClient: Displayed: " .. message)
	else
		warn("AdminMessageClient: Failed to display: " .. message)
	end

	return success
end

-- Wait for chat to load
task.wait(2)

-- Test message
displayMessage("Admin commands ready! Type !help")

-- Listen for messages from server
adminMessageRemote.OnClientEvent:Connect(function(message)
	print("AdminMessageClient: Received: " .. message)
	displayMessage(message)
end)

print("? AdminMessageClient loaded and ready!")