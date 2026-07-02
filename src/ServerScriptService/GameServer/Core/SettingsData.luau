--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))
local SettingsSchema = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Settings"):WaitForChild("SettingsSchema"))

local Data = {}
Data.__index = Data

function Data.new()
    return setmetatable({ Store = DataStoreService:GetDataStore(Config.Networking.SettingsDataStoreName), Remote = nil, Cache = {} }, Data)
end

function Data:Start()
    self.Remote = Net.GetRemoteFunction(Net.RemoteFunctions.Settings)
    self.Remote.OnServerInvoke = function(player, mode, payload)
        if mode == "Load" then return self:Load(player) end
        if mode == "Save" then return self:Save(player, payload) end
        return nil
    end
end

function Data:Load(player)
    local key = "settings_" .. player.UserId
    if self.Cache[player] then return self.Cache[player] end
    local ok, data = pcall(function() return self.Store:GetAsync(key) end)
    data = SettingsSchema.SanitizePayload((ok and typeof(data) == "table") and data or nil)
    self.Cache[player] = data
    return data
end

function Data:Save(player, payload)
    if typeof(payload) ~= "table" then return false end
    local key = "settings_" .. player.UserId
    local sanitized = SettingsSchema.SanitizePayload(payload)
    self.Cache[player] = sanitized
    task.spawn(function()
        pcall(function() self.Store:SetAsync(key, sanitized) end)
    end)
    return sanitized
end

return Data
