--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MoveLabel = {}
MoveLabel.__index = MoveLabel

function MoveLabel.new(state, _, __, motor)
    return setmetatable({
        State = state,
        Motor = motor,
        Gui = nil,
        Label = nil,
        Connection = nil,
    }, MoveLabel)
end

function MoveLabel:Start()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "MovementDebugLabel"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = false
    gui.Parent = playerGui
    self.Gui = gui

    local label = Instance.new("TextLabel")
    label.Name = "MoveName"
    label.Size = UDim2.fromOffset(260, 30)
    label.Position = UDim2.fromOffset(12, 8)
    label.BackgroundTransparency = 0.35
    label.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
    label.BorderSizePixel = 0
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(245, 248, 250)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 15
    label.Text = "Move: Idle"
    label.Parent = gui
    self.Label = label

    self.Connection = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function MoveLabel:Destroy()
    if self.Connection then self.Connection:Disconnect() end
    if self.Gui then self.Gui:Destroy() end
end

function MoveLabel:GetMoveName()
    local mode = self.State and self.State.Mode or "Idle"
    if mode == "Grounded" then
        local speed = self.Motor and self.Motor.Velocity and Vector3.new(self.Motor.Velocity.X, 0, self.Motor.Velocity.Z).Magnitude or 0
        return speed > 1 and "Walk" or "Idle"
    end
    if mode == "Sprinting" then return "Sprint" end
    if mode == "Crouching" then return "Crouch" end
    if mode == "Sliding" then return "Slide" end
    if mode == "BulletJumping" then return "Bullet Jump" end
    if mode == "Gliding" or mode == "AimGliding" then return "Glide" end
    if mode == "Airborne" then return "Airborne" end
    if mode == "Rolling" then return "Roll" end
    if mode == "AirDodging" then return "Air Dodge" end
    if mode == "WallLatched" then return "Wall Latch" end
    if mode == "WallHopping" then return "Wall Hop" end
    return tostring(mode)
end

function MoveLabel:Update()
    if self.Label then
        self.Label.Text = "Move: " .. self:GetMoveName()
    end
end

return MoveLabel
