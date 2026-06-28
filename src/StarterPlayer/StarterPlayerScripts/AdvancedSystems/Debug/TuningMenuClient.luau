--!nonstrict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TuningMenu = {}
TuningMenu.__index = TuningMenu

local TUNABLES = {
    { Category = "Ground", Section = "Movement", Key = "WalkSpeed", Step = 1 },
    { Category = "Ground", Section = "Movement", Key = "SprintSpeed", Step = 1 },
    { Category = "Ground", Section = "Movement", Key = "GroundAcceleration", Step = 5 },
    { Category = "Ground", Section = "Movement", Key = "SprintRampAcceleration", Step = 5 },
    { Category = "Ground", Section = "Movement", Key = "GroundDeceleration", Step = 5 },
    { Category = "Ground", Section = "Movement", Key = "GroundCoastDeceleration", Step = 5 },
    { Category = "Ground", Section = "Movement", Key = "CounterMoveDeceleration", Step = 5 },
    { Category = "Ground", Section = "Movement", Key = "CrouchSpeed", Step = 1 },
    { Category = "Ground", Section = "Movement", Key = "CrouchHipHeightScale", Step = 0.02 },
    { Category = "Ground", Section = "Movement", Key = "SlideHipHeightScale", Step = 0.02 },
    { Category = "Ground", Section = "Movement", Key = "HipHeightSharpness", Step = 1 },
    { Category = "Air", Section = "Movement", Key = "AirAcceleration", Step = 2 },
    { Category = "Air", Section = "Movement", Key = "AirDrag", Step = 0.05 },
    { Category = "Air", Section = "Movement", Key = "Gravity", Step = 5 },
    { Category = "Air", Section = "Movement", Key = "RisingGravityScale", Step = 0.05 },
    { Category = "Air", Section = "Movement", Key = "FallingGravityScale", Step = 0.05 },
    { Category = "Jump", Section = "Movement", Key = "JumpVelocity", Step = 1 },
    { Category = "Jump", Section = "Movement", Key = "JumpHoldMaxTime", Step = 0.02 },
    { Category = "Jump", Section = "Movement", Key = "JumpCutMinVelocity", Step = 1 },
    { Category = "Jump", Section = "Movement", Key = "DoubleJumpVelocity", Step = 1 },
    { Category = "Jump", Section = "Movement", Key = "DoubleJumpForwardBoost", Step = 1 },
    { Category = "Slide", Section = "Movement", Key = "SlideHoldToStartTime", Step = 0.02 },
    { Category = "Slide", Section = "Movement", Key = "SlideStartSpeed", Step = 1 },
    { Category = "Slide", Section = "Movement", Key = "SlideStartBoost", Step = 1 },
    { Category = "Slide", Section = "Movement", Key = "SlideBoostCooldown", Step = 0.05 },
    { Category = "Slide", Section = "Movement", Key = "SlideFriction", Step = 2 },
    { Category = "Slide", Section = "Movement", Key = "SlideSteer", Step = 0.5 },
    { Category = "Slide", Section = "Movement", Key = "SlideForwardExitInput", Step = 0.05 },
    { Category = "Slide", Section = "Movement", Key = "SlideExitSpeed", Step = 1 },
    { Category = "Slide", Section = "Movement", Key = "SlideMaxPlanarSpeed", Step = 2 },
    { Category = "Bullet Jump", Section = "Movement", Key = "BulletJumpForwardImpulse", Step = 2 },
    { Category = "Bullet Jump", Section = "Movement", Key = "BulletJumpUpImpulse", Step = 2 },
    { Category = "Bullet Jump", Section = "Movement", Key = "BulletJumpMaxAddedPlanarSpeed", Step = 2 },
    { Category = "Bullet Jump", Section = "Movement", Key = "BulletJumpMaxAddedVerticalSpeed", Step = 2 },
    { Category = "Glide", Section = "Movement", Key = "AimGlideGravityScale", Step = 0.02 },
    { Category = "Glide", Section = "Movement", Key = "AimGlideMaxFallSpeed", Step = 1 },
    { Category = "Glide", Section = "Movement", Key = "AimGlideAirControlMultiplier", Step = 0.05 },
    { Category = "Glide", Section = "Movement", Key = "AimGlideMomentumPreserve", Step = 0.005 },
    { Category = "Glide", Section = "Movement", Key = "AimGlideMaxDuration", Step = 1 },
    { Category = "Roll", Section = "Movement", Key = "RollImpulse", Step = 2 },
    { Category = "Roll", Section = "Movement", Key = "RollModeTime", Step = 0.02 },
    { Category = "Roll", Section = "Movement", Key = "AirDodgeImpulse", Step = 2 },
    { Category = "Roll", Section = "Movement", Key = "AirDodgeUpImpulse", Step = 1 },
    { Category = "Limits", Section = "Movement", Key = "MaxPlanarSpeed", Step = 2 },
    { Category = "Limits", Section = "Movement", Key = "HardMaxPlanarSpeed", Step = 2 },
    { Category = "Limits", Section = "Movement", Key = "MaxVerticalSpeed", Step = 2 },
    { Category = "Limits", Section = "Movement", Key = "HardMaxVerticalSpeed", Step = 2 },
    { Category = "Camera", Section = "Camera", Key = "Height", Step = 0.1 },
    { Category = "Camera", Section = "Camera", Key = "ShoulderOffset", Step = 0.1 },
    { Category = "Camera", Section = "Camera", Key = "AimShoulderOffset", Step = 0.1 },
    { Category = "Camera", Section = "Camera", Key = "Distance", Step = 0.25 },
    { Category = "Camera", Section = "Camera", Key = "AimDistance", Step = 0.25 },
    { Category = "Camera", Section = "Camera", Key = "PositionSharpness", Step = 2 },
    { Category = "Camera", Section = "Camera", Key = "FocusSharpness", Step = 2 },
    { Category = "Camera", Section = "Camera", Key = "ParkourPositionSharpness", Step = 2 },
    { Category = "Camera", Section = "Camera", Key = "ParkourFocusSharpness", Step = 2 },
}

local TOGGLES = {
    { Label = "Logs", Path = { "Debug", "LogsEnabled" } },
    { Label = "Hitboxes", Path = { "Debug", "HitboxVisualizerEnabled" } },
    { Label = "Movement Log", Path = { "Debug", "Channels", "Movement" } },
    { Label = "Animation Log", Path = { "Debug", "Channels", "Animation" } },
    { Label = "Network Log", Path = { "Debug", "Channels", "Network" } },
    { Label = "Combat Log", Path = { "Debug", "Channels", "Combat" } },
    { Label = "Status Log", Path = { "Debug", "Channels", "Status" } },
    { Label = "Validation Log", Path = { "Debug", "Channels", "Validation" } },
}

local SCALE_KEYS = {
    "WalkSpeed",
    "SprintSpeed",
    "GroundAcceleration",
    "GroundCoastDeceleration",
    "CounterMoveDeceleration",
    "AirAcceleration",
    "JumpVelocity",
    "DoubleJumpVelocity",
    "SlideStartSpeed",
    "SlideStartBoost",
    "SlideMaxPlanarSpeed",
    "BulletJumpForwardImpulse",
    "BulletJumpUpImpulse",
    "RollImpulse",
    "AirDodgeImpulse",
    "MaxPlanarSpeed",
    "HardMaxPlanarSpeed",
}

local function round(value)
    return math.floor(value * 100 + 0.5) / 100
end

local function fmt(value)
    return tostring(round(tonumber(value) or 0))
end

local function vectorText(v)
    if typeof(v) ~= "Vector3" then return "0, 0, 0" end
    return string.format("%.1f, %.1f, %.1f", v.X, v.Y, v.Z)
end

local function getPath(path)
    local value = Config
    for _, key in ipairs(path) do
        value = value[key]
    end
    return value
end

local function setPath(path, nextValue)
    local target = Config
    for index = 1, #path - 1 do
        target = target[path[index]]
    end
    target[path[#path]] = nextValue
end

function TuningMenu.new(state, input, camera, motor, animation)
    return setmetatable({
        State = state,
        Input = input,
        Camera = camera,
        Motor = motor,
        Animation = animation,
        Gui = nil,
        Panel = nil,
        DebugLabel = nil,
        ValueBoxes = {},
        ToggleButtons = {},
        Connections = {},
    }, TuningMenu)
end

function TuningMenu:Start()
    self:BuildGui()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.P then
            self:SetVisible(not self.Gui.Enabled)
        end
    end))
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if self.Gui and self.Gui.Enabled then
            self:UpdateDebugText()
        end
    end))
end

function TuningMenu:Destroy()
    for _, connection in ipairs(self.Connections) do connection:Disconnect() end
    table.clear(self.Connections)
    if self.Gui then self.Gui:Destroy() end
end

function TuningMenu:SetVisible(visible)
    self.Gui.Enabled = visible == true
    if self.Gui.Enabled then
        self:RefreshAll()
        self:UpdateDebugText()
    end
end

function TuningMenu:GetValue(entry)
    return Config[entry.Section][entry.Key]
end

function TuningMenu:SetValue(entry, value)
    value = tonumber(value)
    if not value then return end
    Config[entry.Section][entry.Key] = round(value)
    self:Refresh(entry)
end

function TuningMenu:Nudge(entry, direction)
    self:SetValue(entry, (tonumber(self:GetValue(entry)) or 0) + entry.Step * direction)
end

function TuningMenu:ScaleMovement(multiplier)
    for _, key in ipairs(SCALE_KEYS) do
        local value = Config.Movement[key]
        if type(value) == "number" then
            Config.Movement[key] = round(value * multiplier)
        end
    end
    self:RefreshAll()
end

function TuningMenu:Refresh(entry)
    local box = self.ValueBoxes[entry.Section .. "." .. entry.Key]
    if box then box.Text = fmt(self:GetValue(entry)) end
end

function TuningMenu:RefreshToggle(toggle)
    local button = self.ToggleButtons[toggle.Label]
    if not button then return end
    local enabled = getPath(toggle.Path) == true
    button.Text = toggle.Label .. ": " .. (enabled and "ON" or "OFF")
    button.BackgroundColor3 = enabled and Color3.fromRGB(45, 88, 66) or Color3.fromRGB(56, 42, 46)
end

function TuningMenu:RefreshAll()
    for _, entry in ipairs(TUNABLES) do
        self:Refresh(entry)
    end
    for _, toggle in ipairs(TOGGLES) do
        self:RefreshToggle(toggle)
    end
end

function TuningMenu:MakeButton(parent, text, size)
    local button = Instance.new("TextButton")
    button.Size = size or UDim2.fromOffset(32, 26)
    button.BackgroundColor3 = Color3.fromRGB(42, 48, 56)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(235, 240, 245)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 14
    button.Text = text
    button.Parent = parent
    return button
end

function TuningMenu:AddHeader(parent, text)
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, -8, 0, 24)
    header.BackgroundTransparency = 1
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Color3.fromRGB(115, 190, 255)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 13
    header.Text = text
    header.Parent = parent
end

function TuningMenu:AddRow(parent, entry)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -170, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(225, 230, 235)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Text = entry.Key
    label.Parent = row

    local minus = self:MakeButton(row, "-", UDim2.fromOffset(28, 24))
    minus.Position = UDim2.new(1, -166, 0, 3)

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(82, 24)
    box.Position = UDim2.new(1, -134, 0, 3)
    box.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(245, 248, 250)
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Text = fmt(self:GetValue(entry))
    box.Parent = row
    self.ValueBoxes[entry.Section .. "." .. entry.Key] = box

    local plus = self:MakeButton(row, "+", UDim2.fromOffset(28, 24))
    plus.Position = UDim2.new(1, -48, 0, 3)

    minus.MouseButton1Click:Connect(function() self:Nudge(entry, -1) end)
    plus.MouseButton1Click:Connect(function() self:Nudge(entry, 1) end)
    box.FocusLost:Connect(function()
        self:SetValue(entry, box.Text)
    end)
end

function TuningMenu:AddToggleGrid(parent)
    self:AddHeader(parent, "Debug Toggles")

    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, -8, 0, 112)
    grid.BackgroundTransparency = 1
    grid.Parent = parent

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(136, 26)
    layout.CellPadding = UDim2.fromOffset(6, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid

    for _, toggle in ipairs(TOGGLES) do
        local button = self:MakeButton(grid, toggle.Label, UDim2.fromOffset(136, 26))
        button.TextSize = 12
        self.ToggleButtons[toggle.Label] = button
        button.MouseButton1Click:Connect(function()
            setPath(toggle.Path, getPath(toggle.Path) ~= true)
            self:RefreshToggle(toggle)
        end)
        self:RefreshToggle(toggle)
    end
end

function TuningMenu:BuildGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "ControllerTuningMenu"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = playerGui
    self.Gui = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(560, 640)
    panel.Position = UDim2.fromOffset(24, 80)
    panel.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
    panel.BorderSizePixel = 0
    panel.Parent = gui
    self.Panel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -200, 0, 34)
    title.Position = UDim2.fromOffset(8, 6)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(245, 248, 250)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Text = "Controller Tuning + Debugger"
    title.Parent = panel

    local shrink = self:MakeButton(panel, "All -5%", UDim2.fromOffset(82, 26))
    shrink.Position = UDim2.new(1, -178, 0, 10)
    local grow = self:MakeButton(panel, "All +5%", UDim2.fromOffset(82, 26))
    grow.Position = UDim2.new(1, -90, 0, 10)
    shrink.MouseButton1Click:Connect(function() self:ScaleMovement(0.95) end)
    grow.MouseButton1Click:Connect(function() self:ScaleMovement(1.05) end)

    local debugLabel = Instance.new("TextLabel")
    debugLabel.Size = UDim2.new(1, -16, 0, 150)
    debugLabel.Position = UDim2.fromOffset(8, 44)
    debugLabel.BackgroundColor3 = Color3.fromRGB(12, 15, 20)
    debugLabel.BorderSizePixel = 0
    debugLabel.TextXAlignment = Enum.TextXAlignment.Left
    debugLabel.TextYAlignment = Enum.TextYAlignment.Top
    debugLabel.TextColor3 = Color3.fromRGB(220, 228, 236)
    debugLabel.Font = Enum.Font.Code
    debugLabel.TextSize = 12
    debugLabel.TextWrapped = true
    debugLabel.Text = ""
    debugLabel.Parent = panel
    self.DebugLabel = debugLabel

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -204)
    scroll.Position = UDim2.fromOffset(8, 198)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    self:AddToggleGrid(scroll)

    local lastCategory = nil
    for _, entry in ipairs(TUNABLES) do
        if entry.Category ~= lastCategory then
            self:AddHeader(scroll, entry.Category)
            lastCategory = entry.Category
        end
        self:AddRow(scroll, entry)
    end
end

function TuningMenu:UpdateDebugText()
    if not self.DebugLabel then return end

    local motor = self.Motor
    local anim = self.Animation and self.Animation:GetDebugState() or {}
    local velocity = motor and motor.Velocity or Vector3.zero
    local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
    local move = self.Input and self.Input:GetMoveVector() or Vector2.zero
    local missing = type(anim.Missing) == "string" and anim.Missing or ""
    local failed = type(anim.Failed) == "string" and anim.Failed or ""
    local held = {}
    if self.Input then
        for _, action in ipairs({ "Sprint", "Slide", "Crouch", "Aim", "Jump" }) do
            if self.Input:IsHeld(action) then table.insert(held, action) end
        end
    end

    self.DebugLabel.Text = table.concat({
        string.format("Mode: %s | State: %s | Grounded: %s | Wall: %s", tostring(motor and motor.Mode), tostring(self.State and self.State.Mode), tostring(motor and motor.IsGrounded), tostring(motor and motor.HasWall)),
        string.format("Wall: side %s | approach %.2f | normal %s", tostring(motor and motor.WallContactSide), tonumber(motor and motor.WallApproach) or 0, vectorText(motor and motor.WallNormal)),
        string.format("Speed: %.1f | Velocity: %s | MoveInput: %.2f, %.2f", speed, vectorText(velocity), move.X, move.Y),
        string.format("AirJumps: %s | Bullet: %s cd %.2f | Focus: %.1f | Glide: %.1f", tostring(motor and motor.AirJumpsRemaining), tostring(motor and motor.BulletJumpAvailable), tonumber(motor and motor.BulletJumpCooldown) or 0, tonumber(motor and motor.FocusEnergy) or 0, tonumber(motor and motor.AimGlideTimeRemaining) or 0),
        string.format("Held: %s", #held > 0 and table.concat(held, ", ") or "None"),
        string.format("Animation: mode %s | rig %s | loaded %s | fallback %s", tostring(anim.Mode), tostring(anim.RigType), tostring(anim.LoadedCount), tostring(anim.FallbackCount)),
        string.format("Anim Tracks: loop %s | action %s", tostring(anim.CurrentLoop), tostring(anim.CurrentAction)),
        string.format("Anim Source: loop %s | action %s", tostring(anim.CurrentLoopSource), tostring(anim.CurrentActionSource)),
        string.format("Last Keyframe: %s", tostring(anim.LastKeyframe or "None")),
        string.format("Anim Missing: %s", missing ~= "" and missing or "None"),
        string.format("Anim Failed: %s", failed ~= "" and failed or "None"),
    }, "\n")
end

return TuningMenu
