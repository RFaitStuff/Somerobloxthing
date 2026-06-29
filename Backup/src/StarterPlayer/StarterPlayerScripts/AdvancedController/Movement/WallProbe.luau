--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local WallProbe = {}
WallProbe.__index = WallProbe

function WallProbe.new(controller)
    return setmetatable({
        Controller = controller,
        LastHit = nil,
        MemoryTime = 0,
    }, WallProbe)
end

function WallProbe:GetProbeDirections()
    local c = self.Controller
    local forward = c:GetFlatForward()
    local move = c:GetMoveDirection()
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local dirs = { forward }

    if move.Magnitude > 0.05 then
        table.insert(dirs, move.Unit)
        table.insert(dirs, Util.SafeUnit(forward + move.Unit, forward))
    end

    table.insert(dirs, right)
    table.insert(dirs, -right)
    table.insert(dirs, -forward)
    return dirs, forward
end

function WallProbe:ScoreHit(result, dir, look)
    local normal = result.Normal
    if math.abs(normal.Y) > Config.Movement.MaxWallNormalY then return nil end
    local facing = dir.Unit:Dot(-normal)
    local looking = look.Unit:Dot(-normal)
    if math.max(facing, looking) < Config.Movement.WallLookDotMin then return nil end
    return facing * 2 + looking - result.Distance * 0.03
end

function WallProbe:Update(dt)
    local c = self.Controller
    c.HasWall = false
    c.WallNormal = Vector3.zero
    c.WallTangent = Vector3.zero
    c.WallApproach = 0
    c.WallContactSide = "None"
    if not c.Root then return end

    local origin = c.Root.Position + Vector3.new(0, Config.Movement.WallProbeHeight, 0)
    local dirs, look = self:GetProbeDirections()
    local params = Util.MakeRaycastParams({ c.Character })
    local bestHit = nil
    local bestScore = -math.huge

    for _, dir in ipairs(dirs) do
        local result = Util.Spherecast(origin, Config.Movement.WallProbeRadius, dir.Unit * Config.Movement.WallProbeDistance, params)
        if result then
            local score = self:ScoreHit(result, dir, look)
            if score and score > bestScore then
                bestScore = score
                bestHit = result
            end
        end
    end

    if bestHit then
        local flatNormal = Util.SafeUnit(Vector3.new(bestHit.Normal.X, 0, bestHit.Normal.Z), Vector3.zAxis)
        local tangent = Util.SafeUnit(Vector3.new(-flatNormal.Z, 0, flatNormal.X), c:GetFlatForward())
        local right = c.Camera and c.Camera:GetRight() or Vector3.new(-c:GetFlatForward().Z, 0, c:GetFlatForward().X)
        local sideDot = right:Dot(-flatNormal)
        c.HasWall = true
        c.WallNormal = bestHit.Normal
        c.WallTangent = tangent
        c.WallApproach = math.max(0, look.Unit:Dot(-bestHit.Normal))
        c.WallContactSide = sideDot > 0.35 and "Right" or (sideDot < -0.35 and "Left" or "Front")
        self.LastHit = bestHit
        self.MemoryTime = Config.Movement.WallStickMemoryTime
        return
    end

    self.MemoryTime = math.max(0, self.MemoryTime - (dt or 0))
    if self.MemoryTime > 0 and self.LastHit then
        local flatNormal = Util.SafeUnit(Vector3.new(self.LastHit.Normal.X, 0, self.LastHit.Normal.Z), Vector3.zAxis)
        c.HasWall = true
        c.WallNormal = self.LastHit.Normal
        c.WallTangent = Util.SafeUnit(Vector3.new(-flatNormal.Z, 0, flatNormal.X), c:GetFlatForward())
        c.WallApproach = math.max(0, look.Unit:Dot(-self.LastHit.Normal))
    else
        self.LastHit = nil
    end
end

return WallProbe
