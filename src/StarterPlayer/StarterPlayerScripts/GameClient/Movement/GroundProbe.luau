--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))

local GroundProbe = {}
GroundProbe.__index = GroundProbe

function GroundProbe.new(controller)
    return setmetatable({ Controller = controller, LastHit = nil }, GroundProbe)
end

function GroundProbe:Update()
    local c = self.Controller
    if not c.Root then
        c.IsGrounded = false
        return
    end

    local params = Util.MakeRaycastParams({ c.Character })
    local root = c.Root
    local hipHeight = c.Humanoid and c.Humanoid.HipHeight or 2
    local distance = hipHeight + root.Size.Y * 0.5 + Config.Movement.GroundProbeExtra
    local radius = Config.Movement.GroundProbeRadius or math.max(0.45, math.min(root.Size.X, root.Size.Z) * 0.45)
    local origin = root.Position + Vector3.new(0, 0.25, 0)

    local result = Util.Spherecast(origin, radius, Vector3.new(0, -distance, 0), params)
    if not result then
        result = workspace:Raycast(origin, Vector3.new(0, -distance, 0), params)
    end

    self.LastHit = result
    c.IsGrounded = result ~= nil and result.Normal.Y >= Config.Movement.GroundNormalMinY and c.Velocity.Y <= 6
    c.GroundNormal = result and result.Normal or Vector3.yAxis
end

return GroundProbe
