--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))

local ValidationAudit = {
    Remote = nil,
    Counts = {},
}

function ValidationAudit.Init()
    ValidationAudit.Remote = Net.GetRemoteEvent(Net.RemoteEvents.ValidationUpdate)
end

function ValidationAudit.Reject(player, systemName, reason)
    if not player then return end
    local key = tostring(systemName) .. ":" .. tostring(reason)
    ValidationAudit.Counts[key] = (ValidationAudit.Counts[key] or 0) + 1
    if ValidationAudit.Remote then
        ValidationAudit.Remote:FireClient(player, {
            Type = "Rejected",
            System = systemName,
            Reason = reason,
            Count = ValidationAudit.Counts[key],
        })
    end
end

return ValidationAudit
