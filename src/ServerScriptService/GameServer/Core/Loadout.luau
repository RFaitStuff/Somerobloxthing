--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))

local Inventory = {}
Inventory.__index = Inventory

function Inventory.new(playerState)
    return setmetatable({ PlayerState = playerState, StateRemote = nil }, Inventory)
end

function Inventory:Start()
    self.StateRemote = Net.GetRemoteEvent(Net.RemoteEvents.StateUpdate)
end

function Inventory:EquipWeapon(player, weaponId)
    local def = Weapons.Get(weaponId)
    if not def then return false end
    local state = self.PlayerState:Get(player)
    state.EquippedWeaponId = weaponId
    state.CanAimGlide = Weapons.CanAimGlide(weaponId)
    if def.MeleeDefinition then state.EquippedMeleeId = def.MeleeDefinition end
    self:Replicate(player)
    return true
end

function Inventory:Replicate(player)
    if not self.StateRemote then return end
    local state = self.PlayerState:Get(player)
    self.StateRemote:FireClient(player, {
        EquippedWeaponId = state.EquippedWeaponId,
        EquippedMeleeId = state.EquippedMeleeId,
        CanAimGlide = state.CanAimGlide,
    })
end

return Inventory
