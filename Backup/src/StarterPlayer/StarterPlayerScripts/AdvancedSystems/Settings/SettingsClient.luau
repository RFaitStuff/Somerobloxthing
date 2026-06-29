--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local SettingsClient = {}
SettingsClient.__index = SettingsClient

function SettingsClient.new(clientState, inputClient)
    return setmetatable({ State = clientState, Input = inputClient, Remote = nil }, SettingsClient)
end

function SettingsClient:Start()
    self.Remote = Net.GetRemoteFunction(Net.RemoteFunctions.Settings)
    local ok, payload = pcall(function()
        return self.Remote:InvokeServer("Load")
    end)
    if ok and typeof(payload) == "table" then
        self.State:ApplySettings(payload.Settings)
        if payload.Rebinds and self.Input then self.Input:ApplyRebinds(payload.Rebinds) end
    end
end

function SettingsClient:Save()
    if not self.Remote then return end
    pcall(function()
        self.Remote:InvokeServer("Save", {
            Settings = self.State.Settings,
            Rebinds = self.Input and self.Input:GetSerializedBindings() or {},
        })
    end)
end

return SettingsClient
