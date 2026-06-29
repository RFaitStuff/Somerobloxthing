--!nonstrict
local Vector = {}

function Vector.Flatten(v)
    return Vector3.new(v.X, 0, v.Z)
end

function Vector.SafeUnit(v, fallback)
    if v.Magnitude < 1e-5 then
        return fallback or Vector3.zero
    end
    return v.Unit
end

function Vector.ClampMagnitude(v, maxMagnitude)
    if v.Magnitude > maxMagnitude then
        return v.Unit * maxMagnitude
    end
    return v
end

function Vector.ProjectOnPlane(v, normal)
    return v - normal * v:Dot(normal)
end

function Vector.ExpDecaySharpness(sharpness, dt)
    return 1 - math.exp(-sharpness * dt)
end



local Raycast = {}

function Raycast.MakeRaycastParams(ignoreList, collisionGroup)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {}
    params.IgnoreWater = true
    if collisionGroup then
        params.CollisionGroup = collisionGroup
    end
    return params
end

function Raycast.MakeOverlapParams(ignoreList, collisionGroup)
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList or {}
    if collisionGroup then
        params.CollisionGroup = collisionGroup
    end
    return params
end

function Raycast.Spherecast(origin, radius, direction, params)
    local ok, result = pcall(function()
        return workspace:Spherecast(origin, radius, direction, params)
    end)
    if ok then
        return result
    end
    return workspace:Raycast(origin, direction, params)
end



local Character = {}

function Character.GetCharacterParts(character)
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    return humanoid, root
end

function Character.GetAnimator(humanoid)
    if not humanoid then return nil end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    return animator
end

function Character.FindHumanoidFromPart(part)
    local node = part
    while node and node ~= workspace do
        local humanoid = node:FindFirstChildOfClass("Humanoid")
        if humanoid then
            return humanoid, node
        end
        node = node.Parent
    end
    return nil, nil
end



local Time = {}

function Time.Now()
    return os.clock()
end

function Time.ClampDt(dt)
    return math.clamp(dt or 0, 0, 1 / 20)
end



local Util = {}
for key, value in pairs(Vector) do Util[key] = value end
for key, value in pairs(Raycast) do Util[key] = value end
for key, value in pairs(Character) do Util[key] = value end
for key, value in pairs(Time) do Util[key] = value end
return Util