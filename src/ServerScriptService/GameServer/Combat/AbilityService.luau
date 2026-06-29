--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local Blocks = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("AbilityBlocks"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))
local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local AbilityService = {}
AbilityService.__index = AbilityService

function AbilityService.new(playerState, profiles, resources, combat)
    return setmetatable({ PlayerState = playerState, Profiles = profiles, Resources = resources, Combat = combat, Remote = nil }, AbilityService)
end

function AbilityService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
end

function AbilityService:Replicate(player, ability, cooldownEnds)
    local remote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityUpdate)
    remote:FireClient(player, {
        AbilityId = ability.Id,
        CooldownEnds = cooldownEnds,
        Cooldown = ability.Cooldown or 1,
        ManaCost = ability.ManaCost or 0,
    })
end

function AbilityService:CanCast(player, slot, abilityId)
    local profile = self.Profiles:Get(player)
    local frameState = profile.Frames[profile.SelectedFrameId]
    local frame = Frames.Get(profile.SelectedFrameId)
    local slotData = frame and frame.AbilitySlots[slot]
    if not slotData or not frameState then ValidationAudit.Reject(player, "Ability", "InvalidSlot") return false end
    if frameState.Level < slotData.UnlockLevel then ValidationAudit.Reject(player, "Ability", "SlotLocked") return false end
    local selected = frameState.SelectedVariants[slot]
    if abilityId and selected ~= abilityId then ValidationAudit.Reject(player, "Ability", "VariantNotSelected") return false end
    local ability = Abilities.Get(selected)
    if not ability then ValidationAudit.Reject(player, "Ability", "MissingDefinition") return false end
    local state = self.PlayerState:Get(player)
    if ActionLocks.IsControlLocked(state) then ValidationAudit.Reject(player, "Ability", "ControlLocked") return false end
    local now = os.clock()
    if (state.AbilityCooldowns[ability.Id] or 0) > now then ValidationAudit.Reject(player, "Ability", "Cooldown") return false end
    if not self.Resources:SpendMana(player, ability.ManaCost or 0) then ValidationAudit.Reject(player, "Ability", "NoMana") return false end
    local cooldownEnds = now + (ability.Cooldown or 1)
    state.AbilityCooldowns[ability.Id] = cooldownEnds
    self:Replicate(player, ability, cooldownEnds)
    return true, ability
end

function AbilityService:GetTargets(player, radius, range)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local center = root.Position + root.CFrame.LookVector * (range or 16)
    local params = Util.MakeOverlapParams({ player.Character })
    local parts = workspace:GetPartBoundsInRadius(center, radius or 10, params)
    local out, seen = {}, {}
    for _, part in ipairs(parts) do
        local humanoid = part.Parent and part.Parent:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and not seen[humanoid] then
            seen[humanoid] = true
            table.insert(out, humanoid)
        end
    end
    return out
end

function AbilityService:GetAimDirection(player, payload, root)
    if typeof(payload.Direction) == "Vector3" and payload.Direction.Magnitude > 0.01 then
        return payload.Direction.Unit
    end
    return root.CFrame.LookVector
end

function AbilityService:GetProjectileTargets(player, ability, payload, root)
    local origin = root.Position + Vector3.new(0, 2, 0)
    local direction = self:GetAimDirection(player, payload, root)
    local range = ability.Range or math.clamp((ability.Speed or 160) * 0.35, 24, 120)
    local radius = ability.Radius or 2
    local params = Util.MakeRaycastParams({ player.Character })
    local result = Util.Spherecast(origin, radius, direction * range, params)
    local impact = result and result.Position or origin + direction * range
    local overlapParams = Util.MakeOverlapParams({ player.Character })
    local parts = workspace:GetPartBoundsInRadius(impact, math.max(radius, 2), overlapParams)
    local out, seen = {}, {}
    if result then
        local humanoid = Util.FindHumanoidFromPart(result.Instance)
        if humanoid and humanoid.Health > 0 then
            seen[humanoid] = true
            table.insert(out, humanoid)
        end
    end
    for _, part in ipairs(parts) do
        local humanoid = Util.FindHumanoidFromPart(part)
        if humanoid and humanoid.Health > 0 and not seen[humanoid] then
            seen[humanoid] = true
            table.insert(out, humanoid)
        end
    end
    return out
end

function AbilityService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Ability", "BadPayload") return end
    local slot = tonumber(payload.Slot)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then ValidationAudit.Reject(player, "Ability", "NoCharacterRoot") return end
    local ok, ability = self:CanCast(player, slot, payload.AbilityId)
    if not ok then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")

    if ability.Block == Blocks.Heal then
        self.Combat:Heal(player, ability.Heal or 0)
        if ability.Buff and ability.Buff.Shield then self.Combat:AddShield(player, ability.Buff.Shield) end
        if ability.Buff and ability.Buff.Mana then self.Combat:AddMana(player, ability.Buff.Mana) end
        if ability.Status and humanoid then self.Combat:ApplyStatus(player, player, humanoid, ability.Status) end
        return
    end
    if ability.Block == Blocks.Buff then
        if ability.Buff and ability.Buff.Shield then self.Combat:AddShield(player, ability.Buff.Shield) end
        if ability.Buff and ability.Buff.Mana then self.Combat:AddMana(player, ability.Buff.Mana) end
        if ability.Status and humanoid then self.Combat:ApplyStatus(player, player, humanoid, ability.Status) end
        return
    end
    if ability.Block == Blocks.Dash then
        root.AssemblyLinearVelocity += root.CFrame.LookVector * (ability.Range or 24)
    end

    local targets
    if ability.Block == Blocks.Projectile then
        targets = self:GetProjectileTargets(player, ability, payload, root)
    else
        targets = self:GetTargets(player, ability.Radius or 8, ability.Block == Blocks.Projectile and 24 or 12)
    end
    for _, humanoid in ipairs(targets) do
        self.Combat:Damage(player, humanoid, { Damage = ability.Damage or 0, Element = ability.Element, Status = ability.Status, SourceType = "Ability" })
        if ability.Heal then self.Combat:Heal(player, ability.Heal) end
    end
end

return AbilityService
