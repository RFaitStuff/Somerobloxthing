--!nonstrict
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local Modes = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("MovementModes"))

local HumanoidAdapter = {}
HumanoidAdapter.__index = HumanoidAdapter

function HumanoidAdapter.new(controller)
    return setmetatable({ Controller = controller, DefaultHipHeight = nil }, HumanoidAdapter)
end

function HumanoidAdapter:ApplyCustomMovementSettings()
    local humanoid = self.Controller.Humanoid
    if not humanoid then return end
    self.DefaultHipHeight = humanoid.HipHeight
    humanoid.WalkSpeed = 0
    humanoid.JumpPower = 0
    humanoid.JumpHeight = 0
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
end

function HumanoidAdapter:Update(dt)
    local controller = self.Controller
    local humanoid = controller.Humanoid
    if not humanoid or not self.DefaultHipHeight then return end

    local target = self.DefaultHipHeight
    if controller.Mode == Modes.Sliding or controller.Mode == Modes.KnockedDown then
        target = self.DefaultHipHeight * Config.Movement.SlideHipHeightScale
    elseif controller.Input:IsHeld("Crouch") or controller.Mode == Modes.Crouching then
        target = self.DefaultHipHeight * Config.Movement.CrouchHipHeightScale
    end
    local sharpness = Config.Movement.HipHeightSharpness or 12
    humanoid.HipHeight += (target - humanoid.HipHeight) * (1 - math.exp(-sharpness * dt))
    humanoid.AutoRotate = false
    humanoid.PlatformStand = false
    humanoid:Move(Vector3.zero, false)
end

return HumanoidAdapter
