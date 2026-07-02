--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Mastery = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mastery"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local MasteryService = {}
MasteryService.__index = MasteryService

function MasteryService.new(profiles)
    return setmetatable({ Profiles = profiles, Remote = nil }, MasteryService)
end

function MasteryService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MasteryRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function MasteryService:GetSnapshot(player)
    local profile = self.Profiles:Get(player)
    return Mastery.GetSummary(profile)
end

function MasteryService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.MasteryUpdate):FireClient(player, self:GetSnapshot(player))
end

function MasteryService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Mastery", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    else
        ValidationAudit.Reject(player, "Mastery", "UnknownAction")
    end
end

return MasteryService
