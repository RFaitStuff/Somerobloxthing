--!nonstrict
-- MeleeAuthority ------------------------------------------------------------
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local MeleeAuthority = {}
MeleeAuthority.__index = MeleeAuthority

function MeleeAuthority.new(playerState)
    return setmetatable({ PlayerState = playerState, Buckets = {} }, MeleeAuthority)
end

function MeleeAuthority:Validate(player, payload, attack)
    if typeof(payload) ~= "table" then return false end
    if type(payload.Variant) ~= "string" then return false end
    local now = os.clock()
    local bucket = self.Buckets[player]
    if not bucket or now - bucket.Start > 1 then
        bucket = { Start = now, Count = 0 }
        self.Buckets[player] = bucket
    end
    bucket.Count += 1
    if bucket.Count > Config.Security.MeleeRequestRatePerSecond then return false end
    local state = self.PlayerState:Get(player)
    local now = os.clock()
    local last = state.LastMelee[payload.Variant] or 0
    local minGap = math.max((attack and attack.ChainTime or 0.12) * 0.65, 0.08)
    if now - last < minGap then return false end
    state.LastMelee[payload.Variant] = now
    return true
end

-- HitboxQuery ------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local Net = require(Shared:WaitForChild("Net"))

local HitboxQuery = {}
HitboxQuery.__index = HitboxQuery

function HitboxQuery.new()
    return setmetatable({ DebugRemote = nil }, HitboxQuery)
end

function HitboxQuery:_debugShape(shape)
    if not Config.Debug or not Config.Debug.ReplicateServerHitboxes then return end
    if not self.DebugRemote then
        local ok, remote = pcall(function() return Net.GetRemoteEvent(Net.RemoteEvents.HitboxDebug) end)
        if ok then self.DebugRemote = remote end
    end
    if self.DebugRemote then
        shape.Lifetime = Config.Debug.ServerHitboxLifetime
        self.DebugRemote:FireAllClients(shape)
    end
end

function HitboxQuery:GetTargets(player, attack)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return {} end
    local ignore = { character }
    local params = Util.MakeOverlapParams(ignore)
    local parts
    if attack.Hitbox == "Radius" then
        local center = root.Position + root.CFrame.LookVector * ((attack.Radius or attack.Range or 8) * 0.35)
        local radius = attack.Radius or attack.Range or Config.Combat.DefaultMeleeRange
        self:_debugShape({ Shape = "Radius", Center = center, Radius = radius })
        parts = workspace:GetPartBoundsInRadius(center, radius, params)
    else
        local size = Vector3.new(attack.Width or 5, attack.Height or 5, attack.Range or Config.Combat.DefaultMeleeRange)
        local cf = root.CFrame * CFrame.new(0, 0, -size.Z * 0.5)
        self:_debugShape({ Shape = "Box", CFrame = cf, Size = size })
        parts = workspace:GetPartBoundsInBox(cf, size, params)
    end

    local targets = {}
    local seen = {}
    for _, part in ipairs(parts) do
        local humanoid, model = Util.FindHumanoidFromPart(part)
        if humanoid and humanoid.Health > 0 and model ~= character and not seen[humanoid] then
            seen[humanoid] = true
            table.insert(targets, humanoid)
            if #targets >= Config.Combat.MaxTargetsPerSwing then break end
        end
    end
    return targets
end

-- DamageService ------------------------------------------------------------
local Players = game:GetService("Players")

local DamageService = {}
DamageService.__index = DamageService

function DamageService.new(playerState)
    return setmetatable({ PlayerState = playerState, Status = nil, Combat = nil }, DamageService)
end

local function getPlayerFromHumanoid(humanoid)
    local character = humanoid and humanoid.Parent
    return character and Players:GetPlayerFromCharacter(character)
end

function DamageService:Apply(attacker, humanoids, attack)
    for _, humanoid in ipairs(humanoids) do
        if humanoid.Health > 0 then
            if self.Combat then
                self.Combat:Damage(attacker, humanoid, { Damage = attack.Damage or 10, Status = attack.Status, SourceType = "Melee" })
            else
                humanoid:TakeDamage(attack.Damage or 10)
                humanoid:SetAttribute("LastDamagedBy", attacker.UserId)
            end

            local targetPlayer = getPlayerFromHumanoid(humanoid)
            if targetPlayer and not self.Combat and self.Status and attack.Status then
                if attack.Status.Slow then
                    self.Status:ApplySlow(targetPlayer, attack.Name .. "Slow", attack.Status.Slow.Multiplier, attack.Status.Slow.Duration)
                end
                if attack.Status.Stagger then
                    self.Status:ApplyStagger(targetPlayer, attack.Status.Stagger.Duration)
                end
                local knockdown = attack.Status.KnockedDown or attack.Status.KnockDown
                if knockdown then
                    self.Status:ApplyKnockDown(targetPlayer, knockdown.Duration)
                end
                if attack.Status.Knockback then
                    local root = humanoid.Parent and humanoid.Parent:FindFirstChild("HumanoidRootPart")
                    local attackerRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
                    local dir = Vector3.new(0, 0, -1)
                    if root and attackerRoot then
                        local delta = root.Position - attackerRoot.Position
                        dir = Vector3.new(delta.X, 0, delta.Z)
                        dir = dir.Magnitude > 0.001 and dir.Unit or attackerRoot.CFrame.LookVector
                    end
                    local force = attack.Status.Knockback.Force or 40
                    local up = attack.Status.Knockback.Up or 0
                    self.Status:ApplyKnockback(targetPlayer, dir * force + Vector3.yAxis * up, attack.Status.Knockback.StaggerDuration)
                end
            end
        end
    end
end

-- Main ------------------------------------------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local MeleeDefs = require(Shared:WaitForChild("MeleeDefinitions"))
local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))


local Melee = {}
Melee.__index = Melee

function Melee.new(playerState)
    return setmetatable({ PlayerState = playerState, Authority = MeleeAuthority.new(playerState), Hitbox = HitboxQuery.new(), Damage = DamageService.new(playerState), Status = nil, Remote = nil, Combat = nil }, Melee)
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
end

function Melee:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Melee", "BadPayload") return end
    local state = self.PlayerState:Get(player)
    if ActionLocks.IsControlLocked(state) then ValidationAudit.Reject(player, "Melee", "ControlLocked") return end
    local attack = MeleeDefs.GetAttack(state.EquippedMeleeId, payload.Variant, payload.ComboIndex or 1)
    if not attack then ValidationAudit.Reject(player, "Melee", "InvalidAttack") return end
    if not self.Authority:Validate(player, payload, attack) then ValidationAudit.Reject(player, "Melee", "TimingOrRate") return end
    task.delay(attack.Startup or 0, function()
        local targets = self.Hitbox:GetTargets(player, attack)
        self.Damage:Apply(player, targets, attack)
    end)
end

return Melee
