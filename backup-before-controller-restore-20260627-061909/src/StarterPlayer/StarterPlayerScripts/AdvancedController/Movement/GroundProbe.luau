--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

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
    local distance = (c.Humanoid and c.Humanoid.HipHeight or 2) + c.Root.Size.Y * 0.5 + Config.Movement.GroundProbeExtra
    local result = workspace:Raycast(c.Root.Position, Vector3.new(0, -distance, 0), params)
    self.LastHit = result
    c.IsGrounded = result ~= nil and result.Normal.Y >= Config.Movement.GroundNormalMinY and c.Velocity.Y <= 12
    c.GroundNormal = result and result.Normal or Vector3.yAxis
end

return GroundProbe
