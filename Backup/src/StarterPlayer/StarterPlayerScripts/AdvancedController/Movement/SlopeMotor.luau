--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local SlopeMotor = {}
SlopeMotor.__index = SlopeMotor

function SlopeMotor.new(controller)
    return setmetatable({ Controller = controller, LastDownhill = Vector3.zero, DownhillStrength = 0 }, SlopeMotor)
end

function SlopeMotor:GetGroundTangentDirection(direction)
    local c = self.Controller
    if not c.IsGrounded or not c.GroundNormal or c.GroundNormal.Y >= 0.999 then return direction end
    local projected = Util.ProjectOnPlane(direction, c.GroundNormal)
    return Util.SafeUnit(Vector3.new(projected.X, 0, projected.Z), direction)
end

function SlopeMotor:GetDownhillAcceleration()
    local c = self.Controller
    local normal = c.GroundNormal or Vector3.yAxis
    if not c.IsGrounded or normal.Y >= Config.Movement.SlideDownhillNormalYThreshold then
        self.DownhillStrength = 0
        self.LastDownhill = Vector3.zero
        return Vector3.zero
    end

    local tangentGravity = Util.ProjectOnPlane(Vector3.new(0, Config.Movement.Gravity, 0), normal)
    local downhill = Vector3.new(tangentGravity.X, 0, tangentGravity.Z)
    self.LastDownhill = downhill
    self.DownhillStrength = math.clamp((1 - normal.Y) / (1 - Config.Movement.GroundNormalMinY), 0, 1)
    return downhill
end

function SlopeMotor:ApplySlideSlope(planar, dt)
    local downhill = self:GetDownhillAcceleration()
    if downhill.Magnitude <= 0.001 then return planar end
    local accel = downhill * Config.Movement.SlideSlopeGravityMultiplier
    if planar.Magnitude > 0.001 and planar.Unit:Dot(downhill.Unit) > 0 then
        accel += downhill.Unit * Config.Movement.SlideDownhillExtraAcceleration * self.DownhillStrength
    end
    return planar + accel * dt
end

function SlopeMotor:GetUphillFriction(planar)
    local downhill = self.LastDownhill
    if planar.Magnitude <= 0.001 or downhill.Magnitude <= 0.001 then return 0 end
    return Config.Movement.SlideUphillFriction * math.max(0, -planar.Unit:Dot(downhill.Unit)) * self.DownhillStrength
end

function SlopeMotor:ApplyGroundSlopeAssist(planar, dt)
    local downhill = self:GetDownhillAcceleration()
    if downhill.Magnitude <= 0.001 or planar.Magnitude <= 0.001 then return planar end
    local dot = planar.Unit:Dot(downhill.Unit)
    if dot < 0 then
        return self:MoveToward(planar, Vector3.zero, Config.Movement.SlopeUphillSlowMultiplier * math.abs(dot) * downhill.Magnitude * dt)
    elseif dot > 0 then
        return planar + downhill.Unit * Config.Movement.SlopeDownhillAcceleration * dot * self.DownhillStrength * dt
    end
    return planar
end

function SlopeMotor:MoveToward(current, target, maxDelta)
    local delta = target - current
    if delta.Magnitude <= maxDelta or delta.Magnitude < 1e-5 then return target end
    return current + delta.Unit * maxDelta
end

return SlopeMotor
