--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local AbilityHitboxResolver = {}
AbilityHitboxResolver.__index = AbilityHitboxResolver

function AbilityHitboxResolver.new()
    return setmetatable({ DebugRemote = nil }, AbilityHitboxResolver)
end

function AbilityHitboxResolver:_debug(shape)
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

local function getCharacterRoot(player)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root and root:IsA("BasePart") then
        return character, root
    end
    return character, nil
end

function AbilityHitboxResolver:_collect(parts, attackerCharacter, targets, seen, maxTargets)
    for _, part in ipairs(parts or {}) do
        local humanoid, model = Util.FindHumanoidFromPart(part)
        if humanoid and humanoid.Health > 0 and model ~= attackerCharacter and not seen[humanoid] then
            seen[humanoid] = true
            table.insert(targets, humanoid)
            if #targets >= maxTargets then break end
        end
    end
end

function AbilityHitboxResolver:_collectRadius(center, radius, params, attackerCharacter, targets, seen, maxTargets)
    self:_debug({ Shape = "Radius", Center = center, Radius = radius })
    self:_collect(workspace:GetPartBoundsInRadius(center, radius, params), attackerCharacter, targets, seen, maxTargets)
end

function AbilityHitboxResolver:_collectCapsule(startPos, endPos, radius, params, attackerCharacter, targets, seen, maxTargets)
    self:_debug({ Shape = "Capsule", Start = startPos, Finish = endPos, Radius = radius })
    local delta = endPos - startPos
    local steps = math.max(2, math.ceil(delta.Magnitude / math.max(radius * 1.25, 1)))
    for index = 0, steps do
        local center = startPos:Lerp(endPos, index / steps)
        self:_collect(workspace:GetPartBoundsInRadius(center, radius, params), attackerCharacter, targets, seen, maxTargets)
        if #targets >= maxTargets then break end
    end
end

function AbilityHitboxResolver:GetTargets(player, ability, direction, originCFrame)
    local character, root = getCharacterRoot(player)
    if not root then return {}, root end

    local hitbox = ability.Hitbox or {}
    local shape = hitbox.Shape or (ability.Block == "Projectile" and "Projectile") or (ability.Block == "Area" and "Sphere") or "Sphere"
    local maxTargets = hitbox.MaxTargets or ability.MaxTargets or 12
    local params = Util.MakeOverlapParams({ character })
    local rayParams = Util.MakeRaycastParams({ character })
    local targets = {}
    local seen = {}
    local sourceCFrame = originCFrame or root.CFrame
    direction = Util.SafeUnit(direction or sourceCFrame.LookVector, sourceCFrame.LookVector)

    if shape == "Projectile" or shape == "Raycast" then
        local origin = sourceCFrame.Position + Vector3.new(0, 2, 0)
        local range = hitbox.Range or ability.Range or math.clamp((ability.Speed or hitbox.Speed or 160) * 0.35, 24, 140)
        local radius = hitbox.Radius or ability.Radius or 1.5
        local result = radius > 0 and Util.Spherecast(origin, radius, direction * range, rayParams) or workspace:Raycast(origin, direction * range, rayParams)
        local impact = result and result.Position or origin + direction * range
        self:_collectCapsule(origin, impact, math.max(radius, 0.5), params, character, targets, seen, maxTargets)
        if result then
            local humanoid = Util.FindHumanoidFromPart(result.Instance)
            if humanoid and humanoid.Health > 0 and not seen[humanoid] then
                seen[humanoid] = true
                table.insert(targets, humanoid)
            end
        end
        self:_collectRadius(impact, hitbox.ImpactRadius or math.max(radius, 2), params, character, targets, seen, maxTargets)
        return targets, root
    end

    if shape == "Capsule" or shape == "Beam" then
        local startPos = sourceCFrame.Position + Vector3.new(0, 1.5, 0)
        local finish = startPos + direction * (hitbox.Range or ability.Range or 24)
        self:_collectCapsule(startPos, finish, hitbox.Radius or ability.Radius or 3, params, character, targets, seen, maxTargets)
        return targets, root
    end

    if shape == "WhipTrace" then
        local range = hitbox.Range or ability.Range or 24
        local radius = hitbox.Radius or ability.Radius or 3
        local segments = math.max(3, hitbox.Segments or 6)
        local arc = math.rad(hitbox.ArcDegrees or 80)
        local previous = sourceCFrame.Position + Vector3.new(0, 1.5, 0)
        for index = 1, segments do
            local alpha = index / segments
            local yaw = (alpha - 0.5) * arc
            local localFrame = sourceCFrame * CFrame.Angles(0, yaw, 0) * CFrame.new(0, 1.25, -range * (0.35 + alpha * 0.65))
            local current = localFrame.Position
            self:_collectCapsule(previous, current, radius, params, character, targets, seen, maxTargets)
            previous = current
            if #targets >= maxTargets then break end
        end
        return targets, root
    end

    if shape == "Box" then
        local size = hitbox.Size or Vector3.new(hitbox.Width or 8, hitbox.Height or 7, hitbox.Range or ability.Range or 14)
        local offset = hitbox.Offset or Vector3.new(0, 0, -size.Z * 0.5)
        local cf = sourceCFrame * CFrame.new(offset)
        self:_debug({ Shape = "Box", CFrame = cf, Size = size })
        self:_collect(workspace:GetPartBoundsInBox(cf, size, params), character, targets, seen, maxTargets)
        return targets, root
    end

    if shape == "Cone" then
        local range = hitbox.Range or ability.Range or 20
        local radius = hitbox.Radius or ability.Radius or 10
        local steps = math.max(3, hitbox.Segments or 5)
        for index = 1, steps do
            local alpha = index / steps
            local center = sourceCFrame.Position + Vector3.new(0, 1.4, 0) + direction * range * alpha
            self:_collectRadius(center, radius * alpha, params, character, targets, seen, maxTargets)
            if #targets >= maxTargets then break end
        end
        return targets, root
    end

    local center = (sourceCFrame * CFrame.new(hitbox.Offset or Vector3.new(0, 0, -(hitbox.Range or ability.Range or 10)))).Position
    local radius = hitbox.Radius or ability.Radius or 10
    self:_collectRadius(center, radius, params, character, targets, seen, maxTargets)
    return targets, root
end

return AbilityHitboxResolver
