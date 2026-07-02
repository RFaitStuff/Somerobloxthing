--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local Blocks = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("AbilityBlocks"))
local AbilityHitboxResolver = require(script.Parent:WaitForChild("AbilityHitboxResolver"))
local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local AbilityService = {}
AbilityService.__index = AbilityService

function AbilityService.new(playerState, profiles, resources, combat)
    return setmetatable({ PlayerState = playerState, Profiles = profiles, Resources = resources, Combat = combat, Hitboxes = AbilityHitboxResolver.new(), Remote = nil }, AbilityService)
end

function AbilityService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
end

function AbilityService:Replicate(player, ability, cooldownEnds)
    local remote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityUpdate)
    remote:FireClient(player, {
        Type = "Cooldown",
        AbilityId = ability.Id,
        CooldownEnds = cooldownEnds,
        Cooldown = ability.Cooldown or 1,
        ManaCost = ability.ManaCost or 0,
    })
end

function AbilityService:EmitAbilityEvent(player, ability, eventType, extra)
    local payload = {
        Type = eventType,
        AbilityId = ability.Id,
        Slot = ability.Slot,
        Block = ability.Block,
        Element = ability.Element,
        Animation = ability.Animation,
        Markers = ability.Markers,
        VFX = ability.VFX,
        SFX = ability.SFX,
        ServerTime = os.clock(),
    }
    for key, value in pairs(extra or {}) do
        payload[key] = value
    end
    Net.GetRemoteEvent(Net.RemoteEvents.AbilityUpdate):FireAllClients(payload)
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
    if state.SafeZone and not state.TrainingRange then ValidationAudit.Reject(player, "Ability", "SafeZone") return false end
    if ActionLocks.IsControlLocked(state) then ValidationAudit.Reject(player, "Ability", "ControlLocked") return false end
    local now = os.clock()
    if (state.AbilityCooldowns[ability.Id] or 0) > now then ValidationAudit.Reject(player, "Ability", "Cooldown") return false end
    if not self.Resources:SpendMana(player, ability.ManaCost or 0) then ValidationAudit.Reject(player, "Ability", "NoMana") return false end
    local cooldownEnds = now + (ability.Cooldown or 1)
    state.AbilityCooldowns[ability.Id] = cooldownEnds
    self:Replicate(player, ability, cooldownEnds)
    return true, ability
end

function AbilityService:GetAimDirection(player, payload, root)
    if typeof(payload.Direction) == "Vector3" and payload.Direction.Magnitude > 0.01 then
        return payload.Direction.Unit
    end
    return root.CFrame.LookVector
end

function AbilityService:ApplySelfEffects(player, humanoid, ability)
    if ability.Heal then self.Combat:Heal(player, ability.Heal) end
    if ability.Buff and ability.Buff.Shield then self.Combat:AddShield(player, ability.Buff.Shield) end
    if ability.Buff and ability.Buff.Mana then self.Combat:AddMana(player, ability.Buff.Mana) end
    if ability.Status and humanoid then self.Combat:ApplyStatus(player, player, humanoid, ability.Status) end
end

function AbilityService:DamageTargets(player, targets, ability)
    if (ability.Damage or 0) <= 0 and ability.Hostile ~= true then return end
    for _, humanoid in ipairs(targets or {}) do
        self.Combat:Damage(player, humanoid, {
            Damage = ability.Damage or 0,
            Element = ability.Element,
            Status = ability.Status,
            SourceType = "Ability",
            AbilityId = ability.Id,
        })
        if ability.HealOnHit then self.Combat:Heal(player, ability.HealOnHit) end
    end
end

function AbilityService:RunField(player, ability, direction, castCFrame, humanoid)
    local hitbox = ability.Hitbox or {}
    local ticks = math.max(1, math.floor(tonumber(hitbox.Ticks or ability.Ticks) or 1))
    local duration = math.max(0, tonumber(ability.Duration or hitbox.Duration) or 0)
    local interval = ticks > 1 and duration / (ticks - 1) or 0

    task.spawn(function()
        for tickIndex = 1, ticks do
            if not player.Parent then return end
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            if tickIndex > 1 or ability.ApplyFieldSelfEachTick == true then
                self:ApplySelfEffects(player, humanoid, ability)
            end
            local targets = self.Hitboxes:GetTargets(player, ability, direction, castCFrame)
            self:DamageTargets(player, targets, ability)
            self:EmitAbilityEvent(player, ability, "FieldTick", {
                CastPosition = castCFrame.Position,
                Direction = direction,
                Tick = tickIndex,
                Ticks = ticks,
                TargetCount = #targets,
                Radius = hitbox.Radius or ability.Radius,
                Duration = duration,
            })
            if tickIndex < ticks and interval > 0 then
                task.wait(interval)
            end
        end
        self:EmitAbilityEvent(player, ability, "FieldExpire", {
            CastPosition = castCFrame.Position,
            Direction = direction,
            Ticks = ticks,
            Duration = duration,
        })
    end)
end

function AbilityService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Ability", "BadPayload") return end
    local slot = tonumber(payload.Slot)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then ValidationAudit.Reject(player, "Ability", "NoCharacterRoot") return end
    local ok, ability = self:CanCast(player, slot, payload.AbilityId)
    if not ok then return end
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    self:EmitAbilityEvent(player, ability, "Cast", {
        CastPosition = root.Position,
        Direction = self:GetAimDirection(player, payload, root),
    })

    if ability.Block == Blocks.Heal or ability.Block == Blocks.Buff then
        self:ApplySelfEffects(player, humanoid, ability)
        self:EmitAbilityEvent(player, ability, "Impact", {
            CastPosition = root.Position,
            TargetCount = 1,
            Friendly = true,
        })
        return
    end

    local direction = self:GetAimDirection(player, payload, root)
    if ability.Block == Blocks.Dash then
        root.AssemblyLinearVelocity += direction * (ability.Range or 24)
    end
    if ability.Block == Blocks.Field then
        self:ApplySelfEffects(player, humanoid, ability)
        self:RunField(player, ability, direction, root.CFrame, humanoid)
        return
    end

    local targets = self.Hitboxes:GetTargets(player, ability, direction)
    self:DamageTargets(player, targets, ability)
    self:EmitAbilityEvent(player, ability, "Impact", {
        CastPosition = root.Position,
        Direction = direction,
        TargetCount = #targets,
    })
end

return AbilityService
