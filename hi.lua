local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore")


local saveInterval = 60 
local lagSwitchDuration = 30 


local lastSaveTimestamps = {}
local lagSwitchEndTimes = {}


local function getCurrentTime()
    return os.time()
end


local function getLastSaveTimestamp(player)
    return lastSaveTimestamps[player.UserId] or 0
end


local function setLastSaveTimestamp(player, timestamp)
    lastSaveTimestamps[player.UserId] = timestamp
end


local function canSave(player)
    local lastSaveTimestamp = getLastSaveTimestamp(player)
    local currentTime = getCurrentTime()
    local isLagged = lagSwitchEndTimes[player.UserId] and currentTime < lagSwitchEndTimes[player.UserId]
    return (currentTime - lastSaveTimestamp) >= saveInterval and not isLagged
end


local function activateLagSwitch(player)
    local currentTime = getCurrentTime()
    lagSwitchEndTimes[player.UserId] = currentTime + lagSwitchDuration
end


local function saveData(player)
    if canSave(player) then
        local playerData = {
            score = player.leaderstats.Score.Value,
            level = player.leaderstats.Level.Value
        }

  
        local success, errorMessage = pcall(function()
            playerDataStore:SetAsync(player.UserId, playerData)
        end)

        if success then
            print("data saved.")
            setLastSaveTimestamp(player, getCurrentTime())
        else
            warn("failed to save data: " .. errorMessage)
        end
    else
        print("saving is currently disabled.")
    end
end


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local newStatsRemote = ReplicatedStorage:WaitForChild("newstats")

newStatsRemote.OnServerEvent:Connect(function(player, newStats)
    if player and player:IsA("Player") then
        
        player.leaderstats.Score.Value = newStats.score
        player.leaderstats.Level.Value = newStats.level

        )
        activateLagSwitch(player)

        
        saveData(player)
    end
end)


game.Players.PlayerAdded:Connect(function(player)
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player

    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats

    local level = Instance.new("IntValue")
    level.Name = "Level"
    level.Value = 1
    level.Parent = leaderstats

    
    setLastSaveTimestamp(player, 0)
    lagSwitchEndTimes[player.UserId] = 0
end)
