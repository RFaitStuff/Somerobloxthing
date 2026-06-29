--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Net"))

local MeleeAI = require(script.Parent:WaitForChild("MeleeAI"))
local RangedAI = require(script.Parent:WaitForChild("RangedAI"))

local UniversalAI = {}
UniversalAI.__index = UniversalAI

local BEHAVIORS = {
    Melee = MeleeAI,
    Ranged = RangedAI,
}

function UniversalAI.new(combat)
    return setmetatable({ Combat = combat }, UniversalAI)
end

function UniversalAI:GetParts(model)
    if not model then return nil, nil end
    return model:FindFirstChildOfClass("Humanoid"), model:FindFirstChild("HumanoidRootPart")
end

function UniversalAI:GetNearestPlayer(position, aggroRange)
    local nearestPlayer = nil
    local nearestRoot = nil
    local nearestDistance = math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if humanoid and root and humanoid.Health > 0 then
            local distance = (root.Position - position).Magnitude
            if distance < nearestDistance and distance <= (aggroRange or math.huge) then
                nearestDistance = distance
                nearestPlayer = player
                nearestRoot = root
            end
        end
    end
    return nearestPlayer, nearestRoot, nearestDistance
end

function UniversalAI:CanAttack(model)
    local now = os.clock()
    local fireRate = model:GetAttribute("FireRate") or 1
    local lastAttack = model:GetAttribute("LastAttack") or 0
    return now - lastAttack >= 1 / math.max(0.1, fireRate)
end

function UniversalAI:MarkAttack(model)
    model:SetAttribute("LastAttack", os.clock())
end

function UniversalAI:DamageTarget(model, targetPlayer, multiplier)
    local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetHumanoid or not self.Combat then return end
    self.Combat:Damage(nil, targetHumanoid, {
        Damage = (model:GetAttribute("Damage") or 10) * (multiplier or 1),
        SourceType = "Enemy",
        Element = model:GetAttribute("Element") or "Kinetic",
        Status = model:GetAttribute("StatusId") and {
            [model:GetAttribute("StatusId")] = {
                Chance = model:GetAttribute("StatusChance") or 1,
                Duration = model:GetAttribute("StatusDuration") or nil,
            },
        } or nil,
    })
end

function UniversalAI:GetMuzzleOrigin(model, targetPosition)
    local muzzle = model:FindFirstChild("Muzzle", true)
    if muzzle then
        if muzzle:IsA("Attachment") then return muzzle.WorldPosition end
        if muzzle:IsA("BasePart") then return muzzle.Position end
    end
    local _, root = self:GetParts(model)
    if not root then return targetPosition end
    local dir = targetPosition - root.Position
    dir = Vector3.new(dir.X, 0, dir.Z)
    dir = dir.Magnitude > 0.01 and dir.Unit or root.CFrame.LookVector
    return root.Position + Vector3.new(0, 1.8, 0) + dir * 1.35
end

function UniversalAI:GetAccurateDirection(model, origin, targetPosition)
    local desired = targetPosition - origin
    if desired.Magnitude <= 0.01 then return Vector3.zAxis end
    local accuracy = math.clamp(model:GetAttribute("Accuracy") or 0.7, 0, 1)
    local spread = math.rad((1 - accuracy) * 12)
    local yaw = (math.random() - 0.5) * spread
    local pitch = (math.random() - 0.5) * spread
    return (CFrame.lookAt(Vector3.zero, desired.Unit) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

function UniversalAI:ShootTarget(model, targetPlayer, multiplier)
    local targetRoot = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local targetHumanoid = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    if not targetRoot or not targetHumanoid then return end
    local origin = self:GetMuzzleOrigin(model, targetRoot.Position)
    local direction = self:GetAccurateDirection(model, origin, targetRoot.Position + Vector3.new(0, 1.4, 0))
    local range = model:GetAttribute("AttackRange") or 90
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { model }
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, direction * range, params)
    local hitPosition = result and result.Position or origin + direction * range
    Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback):FireAllClients({
        Type = "Shot",
        Origin = origin,
        HitPosition = hitPosition,
        Enemy = model,
        WeaponId = model:GetAttribute("WeaponVisual") or "EnemyGun",
    })
    local nearMissRadius = model:GetAttribute("HitRadius") or 2.2
    local closest = origin + direction * math.clamp((targetRoot.Position - origin):Dot(direction), 0, range)
    local closeEnough = (closest - (targetRoot.Position + Vector3.new(0, 1.2, 0))).Magnitude <= nearMissRadius
    if (result and result.Instance:IsDescendantOf(targetPlayer.Character)) or (not result and closeEnough) or closeEnough then
        self.Combat:Damage(nil, targetHumanoid, {
            Damage = (model:GetAttribute("Damage") or 10) * (multiplier or 1),
            SourceType = "EnemyGun",
            Element = model:GetAttribute("Element") or "Kinetic",
            Status = model:GetAttribute("StatusId") and {
                [model:GetAttribute("StatusId")] = {
                    Chance = model:GetAttribute("StatusChance") or 1,
                    Duration = model:GetAttribute("StatusDuration") or nil,
                },
            } or nil,
        })
    end
end

function UniversalAI:HasLineOfSight(model, targetRoot)
    local _, root = self:GetParts(model)
    if not root or not targetRoot then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { model }
    params.IgnoreWater = true
    local origin = root.Position + Vector3.new(0, 2, 0)
    local result = workspace:Raycast(origin, targetRoot.Position - origin, params)
    return result == nil or result.Instance:IsDescendantOf(targetRoot.Parent)
end

function UniversalAI:Update(model, dt)
    local humanoid, root = self:GetParts(model)
    if not humanoid or not root or humanoid.Health <= 0 then return end
    local targetPlayer, targetRoot, distance = self:GetNearestPlayer(root.Position, model:GetAttribute("AggroRange") or 160)
    if not targetPlayer or not targetRoot then
        humanoid:MoveTo(root.Position)
        return
    end
    model:SetAttribute("TargetUserId", targetPlayer.UserId)
    local behavior = BEHAVIORS[model:GetAttribute("AIType") or "Melee"] or MeleeAI
    behavior.Step(self, model, humanoid, root, targetPlayer, targetRoot, distance, dt)
end

return UniversalAI
