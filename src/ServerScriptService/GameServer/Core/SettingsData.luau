--!nonstrict
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

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
    data = (ok and typeof(data) == "table") and data or { Settings = {}, Rebinds = {} }
    self.Cache[player] = data
    return data
end

function Data:Save(player, payload)
    if typeof(payload) ~= "table" then return false end
    local key = "settings_" .. player.UserId
    self.Cache[player] = payload
    task.spawn(function()
        pcall(function() self.Store:SetAsync(key, payload) end)
    end)
    return true
end

return Data
