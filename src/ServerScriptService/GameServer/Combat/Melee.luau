--!nonstrict
-- Server-authoritative melee service.
-- Client predicts animation/movement only; server resolves timing, hitboxes, and damage.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))
local MeleeDefs = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Melee"))

local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

-- Authority ------------------------------------------------------------
local MeleeAuthority = {}
MeleeAuthority.__index = MeleeAuthority

function MeleeAuthority.new(playerState)
    return setmetatable({ PlayerState = playerState, Buckets = {} }, MeleeAuthority)
end

function MeleeAuthority:Validate(player, payload, attack)
    if typeof(payload) ~= "table" then return false, "BadPayload" end
    if not attack then return false, "InvalidAttack" end

    local variant = MeleeDefs.NormalizeVariant(payload.Variant)
    if type(variant) ~= "string" or not MeleeDefs.IsValidVariant(self.PlayerState:Get(player).EquippedMeleeId, variant) then
        return false, "InvalidVariant"
    end

    local now = os.clock()
    local bucket = self.Buckets[player]
    if not bucket or now - bucket.Start > 1 then
        bucket = { Start = now, Count = 0 }
        self.Buckets[player] = bucket
    end
    bucket.Count += 1
    if bucket.Count > (Config.Security.MeleeRequestRatePerSecond or 12) then
        return false, "RateLimit"
    end

    local state = self.PlayerState:Get(player)
    state.MeleeRuntime = state.MeleeRuntime or { NextAllowed = 0, LastVariant = nil, LastComboIndex = 0 }
    local runtime = state.MeleeRuntime

    if now < (runtime.NextAllowed or 0) then
        return false, "TooSoon"
    end

    -- Allow fast combo chaining, but prevent the same swing from being spammed every frame.
    local minimumGap = math.max((attack.Startup or 0) + (attack.Active or 0) * 0.35, 0.055)
    runtime.NextAllowed = now + minimumGap
    runtime.LastVariant = variant
    runtime.LastComboIndex = tonumber(payload.ComboIndex) or 1
    runtime.LastAttackStarted = now
    return true
end

-- Hitbox query ------------------------------------------------------------
local HitboxQuery = {}
HitboxQuery.__index = HitboxQuery

function HitboxQuery.new()
    return setmetatable({ DebugRemote = nil }, HitboxQuery)
end

function HitboxQuery:_debugShape(shape)
    if not Config.Debug or not Config.Debug.ReplicateServerHitboxes then return end
    if not self.DebugRemote then
        local ok, remote = pcall(function()
            return Net.GetRemoteEvent(Net.RemoteEvents.HitboxDebug)
        end)
        if ok then self.DebugRemote = remote end
    end
    if self.DebugRemote then
        shape.Lifetime = Config.Debug.ServerHitboxLifetime
        self.DebugRemote:FireAllClients(shape)
    end
end

local function rootInfo(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return character, root
    end
    return character, nil
end

local function getTargetRoot(humanoid)
    local model = humanoid and humanoid.Parent
    local root = model and model:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then return root end
    return nil
end

function HitboxQuery:_collect(parts, attackerCharacter, root, attack, targets, seen)
    local maxTargets = attack.MaxTargets or Config.Combat.MaxTargetsPerSwing or 8
    for _, part in ipairs(parts or {}) do
        local humanoid, model = Util.FindHumanoidFromPart(part)
        if humanoid and humanoid.Health > 0 and model ~= attackerCharacter and not seen[humanoid] then
            local targetRoot = getTargetRoot(humanoid)
            if targetRoot and root then
                local delta = targetRoot.Position - root.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                if flat.Magnitude > 0.001 then
                    local dot = root.CFrame.LookVector:Dot(flat.Unit)
                    if dot < (attack.MinFacingDot or -0.25) then
                        continue
                    end
                end
            end
            seen[humanoid] = true
            table.insert(targets, humanoid)
            if #targets >= maxTargets then break end
        end
    end
end

function HitboxQuery:GetTargets(player, attack, alreadyHit)
    local character, root = rootInfo(player)
    if not root then return {} end

    local ignore = { character }
    local params = Util.MakeOverlapParams(ignore)
    local targets = {}
    local seen = alreadyHit or {}
    local shape = attack.Shape or attack.Hitbox or "Box"

    if shape == "Radius" then
        local center = (root.CFrame * CFrame.new(attack.Offset or Vector3.new(0, 0, -(attack.Radius or 8) * 0.25))).Position
        local radius = attack.Radius or attack.Range or Config.Combat.DefaultMeleeRange
        self:_debugShape({ Shape = "Radius", Center = center, Radius = radius, AttackId = attack.Id })
        self:_collect(workspace:GetPartBoundsInRadius(center, radius, params), character, root, attack, targets, seen)
        return targets
    end

    if shape == "Capsule" then
        local startPos = (root.CFrame * CFrame.new(attack.StartOffset or Vector3.new(0, 0, -2))).Position
        local endPos = (root.CFrame * CFrame.new(attack.EndOffset or Vector3.new(0, 0, -(attack.Range or 8)))).Position
        local radius = attack.Radius or math.max((attack.Width or 4) * 0.5, 1)
        self:_debugShape({ Shape = "Capsule", Start = startPos, Finish = endPos, Center = (startPos + endPos) * 0.5, Radius = radius, HalfHeight = math.max((endPos - startPos).Magnitude * 0.5, 0.1), AttackId = attack.Id })

        local delta = endPos - startPos
        local steps = math.max(2, math.ceil(delta.Magnitude / math.max(radius * 1.25, 1)))
        for i = 0, steps do
            local alpha = i / steps
            local center = startPos:Lerp(endPos, alpha)
            self:_collect(workspace:GetPartBoundsInRadius(center, radius, params), character, root, attack, targets, seen)
            if #targets >= (attack.MaxTargets or Config.Combat.MaxTargetsPerSwing or 8) then break end
        end
        return targets
    end

    local size = Vector3.new(attack.Width or 5, attack.Height or 5, attack.Range or Config.Combat.DefaultMeleeRange)
    local offset = attack.Offset or Vector3.new(0, 0, -size.Z * 0.5)
    local cf = root.CFrame * CFrame.new(offset)
    self:_debugShape({ Shape = "Box", CFrame = cf, Size = size, AttackId = attack.Id })
    self:_collect(workspace:GetPartBoundsInBox(cf, size, params), character, root, attack, targets, seen)
    return targets
end

-- Damage ------------------------------------------------------------
local DamageService = {}
DamageService.__index = DamageService

function DamageService.new()
    return setmetatable({ Status = nil, Combat = nil }, DamageService)
end

function DamageService:Apply(attacker, humanoids, attack)
    for _, humanoid in ipairs(humanoids) do
        if humanoid.Health > 0 then
            if self.Combat then
                self.Combat:Damage(attacker, humanoid, {
                    Damage = attack.Damage or 10,
                    Status = attack.Status,
                    SourceType = "Melee",
                    AttackId = attack.Id,
                })
            else
                humanoid:TakeDamage(attack.Damage or 10)
                humanoid:SetAttribute("LastDamagedBy", attacker.UserId)
                humanoid:SetAttribute("LastDamageSource", "Melee")
            end
        end
    end
end

-- Main service ------------------------------------------------------------
local Melee = {}
Melee.__index = Melee

function Melee.new(playerState)
    return setmetatable({
        PlayerState = playerState,
        Authority = MeleeAuthority.new(playerState),
        Hitbox = HitboxQuery.new(),
        Damage = DamageService.new(),
        Status = nil,
        Remote = nil,
        Combat = nil,
        ActiveSwings = {},
    }, Melee)
end

function Melee:Start(statuses, combat)
    self.Status = statuses
    self.Combat = combat
    self.Damage.Status = statuses
    self.Damage.Combat = combat
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.MeleeRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload)
        self:Handle(player, payload)
    end)
    Players.PlayerRemoving:Connect(function(player)
        self.ActiveSwings[player] = nil
    end)
end

function Melee:_runActiveWindow(player, attack)
    local hitOnce = {}
    local active = math.max(attack.Active or 0.1, 0.03)
    local step = math.clamp(Config.Combat.MeleeHitboxStep or 0.045, 0.025, 0.08)
    local samples = math.max(1, math.ceil(active / step))

    for _ = 1, samples do
        local targets = self.Hitbox:GetTargets(player, attack, hitOnce)
        if #targets > 0 then
            self.Damage:Apply(player, targets, attack)
            if not attack.MultiHit then
                for _, humanoid in ipairs(targets) do
                    hitOnce[humanoid] = true
                end
            end
        end
        if samples > 1 then task.wait(active / samples) end
    end
end

function Melee:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Melee", "BadPayload") return end
    local state = self.PlayerState:Get(player)

    if payload.Action == "Block" then
        if ActionLocks.IsControlLocked(state) and payload.IsBlocking == true then
            ValidationAudit.Reject(player, "Melee", "BlockControlLocked")
            return
        end
        state.IsMeleeBlocking = payload.IsBlocking == true
        state.BlockChangedAt = os.clock()
        return
    end

    if ActionLocks.IsControlLocked(state) then ValidationAudit.Reject(player, "Melee", "ControlLocked") return end

    local variant = MeleeDefs.NormalizeVariant(payload.Variant)
    local comboIndex = math.clamp(math.floor(tonumber(payload.ComboIndex) or 1), 1, 12)
    local attack = MeleeDefs.GetAttack(state.EquippedMeleeId, variant, comboIndex)
    if not attack then ValidationAudit.Reject(player, "Melee", "InvalidAttack") return end

    local ok, reason = self.Authority:Validate(player, { Variant = variant, ComboIndex = comboIndex }, attack)
    if not ok then ValidationAudit.Reject(player, "Melee", reason or "Rejected") return end

    task.delay(attack.Startup or 0, function()
        -- If character died/despawned during startup, do nothing.
        local character, root = rootInfo(player)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health <= 0 then return end
        self:_runActiveWindow(player, attack)
    end)
end

return Melee
