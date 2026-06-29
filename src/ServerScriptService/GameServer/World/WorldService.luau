--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local NodeRules = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("World"):WaitForChild("NodeRules"))

local WorldService = {}
WorldService.__index = WorldService

function WorldService.new(playerState, missions)
    return setmetatable({ PlayerState = playerState, Missions = missions, Remote = nil }, WorldService)
end

function WorldService:Start()
    if Net.RemoteEvents.WorldRequest then
        self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.WorldRequest)
        self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
    end
end

function WorldService:GetNode(locationId, nodeId)
    local publicNode = Locations.GetNode(locationId, nodeId)
    local rule = NodeRules[nodeId]
    if not publicNode or not rule then return nil end
    return publicNode, rule
end

function WorldService:Handle(player, payload)
    if typeof(payload) ~= "table" then return end
    if payload.Action == "ActivateNode" then
        local node, rule = self:GetNode(payload.LocationId or "Earth", payload.NodeId)
        if not node or not rule then return end
        if rule.InstanceMode == "PublicZone" then
            self.Missions:StartMission(player, rule.MissionId)
        else
            -- Placeholder: later this routes through matchmaking/TeleportService/reserved servers.
            self.Missions:StartMission(player, rule.MissionId)
        end
    elseif payload.Action == "RequestLocations" and Net.RemoteEvents.WorldUpdate then
        Net.GetRemoteEvent(Net.RemoteEvents.WorldUpdate):FireClient(player, { Locations = Locations.ById })
    end
end

return WorldService
