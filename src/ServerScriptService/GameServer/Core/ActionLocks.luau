--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StatusTypes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Statuses"))

local ActionLocks = {}

local HARD_LOCKS = {
    [StatusTypes.Stagger] = true,
    [StatusTypes.KnockedDown] = true,
    KnockDown = true,
}

function ActionLocks.IsControlLocked(state)
    if not state then return true end
    local now = os.clock()
    if (state.StatusTrustUntil or 0) > now then
        return true
    end
    for _, effect in pairs(state.StatusEffects or {}) do
        if HARD_LOCKS[effect.Type] and (effect.EndTime or 0) > now then
            return true
        end
    end
    return false
end

return ActionLocks
