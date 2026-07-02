--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Modes = require(Shared:WaitForChild("Core"):WaitForChild("MovementModes"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local Orientation = {}
Orientation.__index = Orientation

function Orientation.new(controller)
    return setmetatable({ Controller = controller }, Orientation)
end

function Orientation:Update(dt)
    local c = self.Controller
    if not c.Root then return end
    local desired
    if c.ForceFacingTimer and c.ForceFacingTimer > 0 and c.ForceFacingDirection then
        desired = c.ForceFacingDirection
    elseif c.Mode == Modes.AimGliding then
        local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        local aim = Util.SafeUnit(Vector3.new(c:GetAimDirection().X, 0, c:GetAimDirection().Z), c:GetFlatForward())
        if planar.Magnitude > 2 then
            local travel = planar.Unit
            local dot = math.clamp(travel:Dot(aim), -1, 1)
            local reverseBlend = math.clamp((1 - dot) * 0.5, 0, 1)
            desired = Util.SafeUnit(travel:Lerp(aim, reverseBlend), aim)
        else
            desired = aim
        end
    elseif c.Input:IsHeld("Aim") then
        desired = c:GetFlatForward()
    else
        local planar = Vector3.new(c.Velocity.X, 0, c.Velocity.Z)
        if planar.Magnitude > 2 then desired = planar.Unit end
    end
    if not desired or desired.Magnitude < 0.05 then return end
    local current = Util.SafeUnit(Vector3.new(c.Root.CFrame.LookVector.X, 0, c.Root.CFrame.LookVector.Z), desired)
    local mixed = Util.SafeUnit(current:Lerp(desired, Util.ExpDecaySharpness(Config.Movement.OrientationSharpness, dt)), desired)
    c.Root.CFrame = CFrame.lookAt(c.Root.Position, c.Root.Position + mixed)
end

return Orientation
