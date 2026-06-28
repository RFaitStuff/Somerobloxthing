--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local WallProbe = {}
WallProbe.__index = WallProbe

function WallProbe.new(controller)
    return setmetatable({ Controller = controller, LastHit = nil }, WallProbe)
end

function WallProbe:Update()
    local c = self.Controller
    c.HasWall = false
    c.WallNormal = Vector3.zero
    self.LastHit = nil
    if not c.Root then return end

    local origin = c.Root.Position + Vector3.new(0, Config.Movement.WallProbeHeight, 0)
    local forward = c:GetFlatForward()
    local right = Vector3.new(-forward.Z, 0, forward.X)
    local params = Util.MakeRaycastParams({ c.Character })

    for _, dir in ipairs({ forward, -forward, right, -right }) do
        local result = Util.Spherecast(origin, Config.Movement.WallProbeRadius, dir.Unit * Config.Movement.WallProbeDistance, params)
        if result and math.abs(result.Normal.Y) <= Config.Movement.MaxWallNormalY then
            c.HasWall = true
            c.WallNormal = result.Normal
            self.LastHit = result
            return
        end
    end
end

return WallProbe
