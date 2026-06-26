--!nonstrict
local Players = game:GetService("Players")

local PlayerState = {}
PlayerState.__index = PlayerState

function PlayerState.new()
    local self = setmetatable({ States = {} }, PlayerState)
    Players.PlayerRemoving:Connect(function(player) self.States[player] = nil end)
    return self
end

function PlayerState:Get(player)
    local state = self.States[player]
    if not state then
        state = {
            EquippedWeaponId = "Rifle",
            EquippedMeleeId = "Skana",
            CanAimGlide = true,
            LastActions = {},
            LastPosition = nil,
            LastPositionTime = os.clock(),
            LastCorrection = 0,
            StatusEffects = {},
            StatusTrustUntil = 0,
        }
        self.States[player] = state
    end
    return state
end

return PlayerState
