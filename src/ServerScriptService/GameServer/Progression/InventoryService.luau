--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local InventoryService = {}
InventoryService.__index = InventoryService

function InventoryService.new(profiles, frames)
    return setmetatable({ Profiles = profiles, Frames = frames, Remote = nil }, InventoryService)
end

function InventoryService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.InventoryRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
end

function InventoryService:Replicate(player)
    Net.GetRemoteEvent(Net.RemoteEvents.InventoryUpdate):FireClient(player, self.Profiles:GetInventorySnapshot(player))
end

function InventoryService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Inventory", "BadPayload") return end
    if payload.Action == "RequestSnapshot" then
        self:Replicate(player)
    elseif payload.Action == "EquipMod" then
        if self.Profiles:EquipMod(player, payload.Group, payload.ModId) then
            if self.Frames then self.Frames:Refresh(player) end
            self:Replicate(player)
        else
            ValidationAudit.Reject(player, "Inventory", "InvalidModEquip")
        end
    elseif payload.Action == "UnequipMod" then
        if self.Profiles:UnequipMod(player, payload.Group, payload.ModId) then
            if self.Frames then self.Frames:Refresh(player) end
            self:Replicate(player)
        else
            ValidationAudit.Reject(player, "Inventory", "InvalidModUnequip")
        end
    elseif payload.Action == "EquipArmor" then
        if self.Profiles:EquipArmor(player, payload.ItemUid) then
            if self.Frames then self.Frames:Refresh(player) end
            self:Replicate(player)
        else
            ValidationAudit.Reject(player, "Inventory", "InvalidArmorEquip")
        end
    else
        ValidationAudit.Reject(player, "Inventory", "UnknownAction")
    end
end

return InventoryService
