-- AdminCommands (Server)
-- Place this SCRIPT in ServerScriptService

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create RemoteEvent for admin messages
local adminMessageRemote = ReplicatedStorage:FindFirstChild("AdminMessage")
if not adminMessageRemote then
	adminMessageRemote = Instance.new("RemoteEvent")
	adminMessageRemote.Name = "AdminMessage"
	adminMessageRemote.Parent = ReplicatedStorage
end

-- Wait for PlayerStatsManager to load
local StatsManager
repeat
	task.wait(0.1)
	local statsScript = ServerScriptService:FindFirstChild("PlayerStatsManager")
	if statsScript then
		local success, result = pcall(function()
			return require(statsScript)
		end)
		if success then
			StatsManager = result
			print("? AdminCommands loaded StatsManager")
		end
	end
until StatsManager

-- List of admin user IDs
local ADMINS = {
	4800479518, -- Your UserId
}

-- Send message to player's chat
local function sendMessage(player, message)
	adminMessageRemote:FireClient(player, message)
	print("[To " .. player.Name .. "] " .. message)
end

-- Check if player is admin
local function isAdmin(player)
	for _, adminId in pairs(ADMINS) do
		if player.UserId == adminId then
			return true
		end
	end
	return false
end

-- Process commands
local function processCommand(player, message)
	if not isAdmin(player) then return end

	local args = string.split(message, " ")
	local command = string.lower(args[1])

	-- !givexp [amount]
	if command == "!givexp" then
		local amount = tonumber(args[2]) or 100
		StatsManager.GiveXP(player, amount)
		sendMessage(player, "? Added " .. amount .. " XP!")

		-- !addstr [points]
	elseif command == "!addstr" then
		local points = tonumber(args[2]) or 1
		if StatsManager.AddStrength(player, points) then
			sendMessage(player, "? Added " .. points .. " Strength!")
		else
			sendMessage(player, "? Not enough stat points!")
		end

		-- !adddex [points]
	elseif command == "!adddex" then
		local points = tonumber(args[2]) or 1
		if StatsManager.AddDexterity(player, points) then
			local stats = player:FindFirstChild("Stats")
			if stats then
				sendMessage(player, "? Added " .. points .. " Dexterity! (Speed: " .. math.floor(stats.Speed.Value) .. ")")
			end
		else
			sendMessage(player, "? Not enough stat points!")
		end

		-- !addcon [points]
	elseif command == "!addcon" then
		local points = tonumber(args[2]) or 1
		if StatsManager.AddConstitution(player, points) then
			local stats = player:FindFirstChild("Stats")
			if stats then
				sendMessage(player, "? Added " .. points .. " Constitution! (HP: " .. math.floor(stats.MaxHP.Value) .. ")")
			end
		else
			sendMessage(player, "? Not enough stat points!")
		end

		-- !addint [points]
	elseif command == "!addint" then
		local points = tonumber(args[2]) or 1
		if StatsManager.AddIntelligence(player, points) then
			local stats = player:FindFirstChild("Stats")
			if stats then
				sendMessage(player, "? Added " .. points .. " Intelligence! (Range: " .. stats.SpellRange.Value .. ", Words: " .. stats.WordCount.Value .. ")")
			end
		else
			sendMessage(player, "? Not enough stat points!")
		end

		-- !stats
	elseif command == "!stats" then
		local stats = player:FindFirstChild("Stats")
		local leaderstats = player:FindFirstChild("leaderstats")
		if stats and leaderstats then
			sendMessage(player, "========== YOUR STATS ==========")
			sendMessage(player, "Level: " .. leaderstats.Level.Value .. " | XP: " .. stats.XP.Value .. "/" .. stats.XPRequired.Value)
			sendMessage(player, "HP: " .. math.floor(stats.CurrentHP.Value) .. "/" .. math.floor(stats.MaxHP.Value) .. " | Stamina: " .. math.floor(stats.CurrentStamina.Value) .. "/" .. math.floor(stats.MaxStamina.Value))
			sendMessage(player, "STR: " .. stats.Strength.Value .. " | DEX: " .. stats.Dexterity.Value .. " | CON: " .. stats.Constitution.Value .. " | INT: " .. stats.Intelligence.Value)
			sendMessage(player, "Speed: " .. math.floor(stats.Speed.Value) .. " | Defense: " .. stats.Defense.Value .. " | Stat Points: " .. stats.StatPoints.Value)
		end
		StatsManager.DisplayStats(player) -- Also print to console

		-- !save
	elseif command == "!save" then
		if StatsManager.SaveData(player) then
			sendMessage(player, "? Data saved successfully!")
		else
			sendMessage(player, "? Save failed!")
		end

		-- !damage
	elseif command == "!damage" then
		local damage = StatsManager.GetPhysicalDamage(player)
		sendMessage(player, "Physical Damage: " .. damage)

		-- !heal
	elseif command == "!heal" then
		local stats = player:FindFirstChild("Stats")
		if stats then
			stats.CurrentHP.Value = stats.MaxHP.Value
			stats.CurrentStamina.Value = stats.MaxStamina.Value
			sendMessage(player, "? Fully healed!")
		end

		-- !resetstats
	elseif command == "!resetstats" then
		local stats = player:FindFirstChild("Stats")
		local leaderstats = player:FindFirstChild("leaderstats")

		if stats and leaderstats then
			leaderstats.Level.Value = 1
			stats.XP.Value = 0
			stats.XPRequired.Value = 100
			stats.Strength.Value = 1
			stats.Dexterity.Value = 1
			stats.Constitution.Value = 1
			stats.Intelligence.Value = 1
			stats.StatPoints.Value = 0
			StatsManager.RecalculateDerivedStats(player)
			sendMessage(player, "? Stats reset to default!")
		end

		-- !help
	elseif command == "!help" then
		sendMessage(player, "========== ADMIN COMMANDS ==========")
		sendMessage(player, "!givexp [amount] - Give XP")
		sendMessage(player, "!addstr [points] - Add Strength")
		sendMessage(player, "!adddex [points] - Add Dexterity")
		sendMessage(player, "!addcon [points] - Add Constitution")
		sendMessage(player, "!addint [points] - Add Intelligence")
		sendMessage(player, "!stats - Display stats")
		sendMessage(player, "!damage - Show damage")
		sendMessage(player, "!heal - Full heal")
		sendMessage(player, "!save - Save data")
		sendMessage(player, "!resetstats - Reset stats")
	end
end

-- Listen for chat messages
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		processCommand(player, message)
	end)
end)

-- Handle players already in game
for _, player in pairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(message)
		processCommand(player, message)
	end)
end

print("? AdminCommands loaded! Type !help for commands")
