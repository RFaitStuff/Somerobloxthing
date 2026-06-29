--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local Orientation = {}
Orientation.__index = Orientation

function Orientation.new(controller)
    return setmetatable({ Controller = controller }, Orientation)
end

function Orientation:Update(dt)
    local c = self.Controller
    if not c.Root then return end
    local desired
    if c.Input:IsHeld("Aim") then
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
