--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local WallProbe = {}
WallProbe.__index = WallProbe

function WallProbe.new(controller)
    return setmetatable({
        Controller = controller,
        LastHit = nil,
        MemoryTime = 0,
        ContactAge = 0,
    }, WallProbe)
end

function WallProbe:GetProbeDirections()
    local c = self.Controller
    local forward = c:GetFlatForward()
    local move = c:GetMoveDirection()
    local right = c.Camera and c.Camera:GetRight() or Vector3.new(-forward.Z, 0, forward.X)
    right = Util.SafeUnit(Vector3.new(right.X, 0, right.Z), Vector3.new(-forward.Z, 0, forward.X))

    local dirs = { forward, right, -right, -forward }
    if move.Magnitude > 0.05 then
        table.insert(dirs, 1, move.Unit)
        table.insert(dirs, Util.SafeUnit(forward + move.Unit, forward))
    end
    return dirs, forward, move
end

function WallProbe:IsValidWall(normal)
    return math.abs(normal.Y) <= Config.Movement.MaxWallNormalY
end

function WallProbe:ScoreContact(result, dir, look, move)
    if not self:IsValidWall(result.Normal) then return nil end
    local normal = result.Normal
    local facing = dir.Unit:Dot(-normal)
    local looking = look.Unit:Dot(-normal)
    local moving = move.Magnitude > 0.05 and move.Unit:Dot(-normal) or 0

    -- Contact is intentionally more forgiving than latch aiming. This lets players jump back to
    -- a wall and start chaining even if the camera is not perfectly centered on the wall yet.
    local bestApproach = math.max(facing, moving, looking * 0.65)
    if bestApproach < (Config.Movement.WallContactDotMin or -0.12) then return nil end
    return bestApproach * 2 + looking * 0.65 + moving - result.Distance * 0.035
end

function WallProbe:ApplyHit(hit, look, dt)
    local c = self.Controller
    local flatNormal = Util.SafeUnit(Vector3.new(hit.Normal.X, 0, hit.Normal.Z), Vector3.zAxis)
    local tangent = Util.SafeUnit(Vector3.new(-flatNormal.Z, 0, flatNormal.X), c:GetFlatForward())
    local right = c.Camera and c.Camera:GetRight() or Vector3.new(-c:GetFlatForward().Z, 0, c:GetFlatForward().X)
    local sideDot = right:Dot(-flatNormal)
    local approach = math.max(0, look.Unit:Dot(-hit.Normal))

    c.HasWall = true
    c.HasWallContact = true
    c.HasWallAim = approach >= (Config.Movement.WallAimDotMin or Config.Movement.WallLookDotMin or 0.18)
    c.WallNormal = hit.Normal
    c.WallTangent = tangent
    c.WallApproach = approach
    c.WallContactSide = sideDot > 0.35 and "Right" or (sideDot < -0.35 and "Left" or "Front")
    c.LastWallNormal = hit.Normal
    c.LastWallNormalTimer = Config.Movement.WallRecontactAssistTime or 0.38

    self.ContactAge += dt or 0
    c.WallContactAge = self.ContactAge
    self.LastHit = hit
    self.MemoryTime = Config.Movement.WallStickMemoryTime
end

function WallProbe:Update(dt)
    local c = self.Controller
    c.HasWall = false
    c.HasWallContact = false
    c.HasWallAim = false
    c.WallNormal = Vector3.zero
    c.WallTangent = Vector3.zero
    c.WallApproach = 0
    c.WallContactSide = "None"
    if not c.Root then return end

    local dirs, look, move = self:GetProbeDirections()
    local params = Util.MakeRaycastParams({ c.Character })
    local heights = Config.Movement.WallContactProbeHeights or { Config.Movement.WallProbeHeight }
    local bestHit = nil
    local bestScore = -math.huge

    for _, height in ipairs(heights) do
        local origin = c.Root.Position + Vector3.new(0, height, 0)
        for _, dir in ipairs(dirs) do
            if dir.Magnitude > 0.05 then
                local result = Util.Spherecast(origin, Config.Movement.WallProbeRadius, dir.Unit * Config.Movement.WallProbeDistance, params)
                if result then
                    local score = self:ScoreContact(result, dir, look, move)
                    if score and score > bestScore then
                        bestScore = score
                        bestHit = result
                    end
                end
            end
        end
    end

    if bestHit then
        self:ApplyHit(bestHit, look, dt)
        return
    end

    self.ContactAge = 0
    c.WallContactAge = 0
    self.MemoryTime = math.max(0, self.MemoryTime - (dt or 0))
    if self.MemoryTime > 0 and self.LastHit and self:IsValidWall(self.LastHit.Normal) then
        -- Memory keeps latch/hop transitions forgiving, but not aim-qualified unless the camera is still facing the wall.
        self:ApplyHit(self.LastHit, look, 0)
        c.HasWallAim = c.WallApproach >= (Config.Movement.WallAimDotMin or 0.18)
    else
        self.LastHit = nil
    end
end

return WallProbe
