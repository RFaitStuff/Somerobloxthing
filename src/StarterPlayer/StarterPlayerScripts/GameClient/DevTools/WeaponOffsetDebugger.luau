--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Core"):WaitForChild("Config"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local WeaponVisuals = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("WeaponVisuals"))

local Debugger = {}
Debugger.__index = Debugger

local function make(parent, className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(value)
    return math.floor(value * 1000 + 0.5) / 1000
end

local function formatVector(name, value)
    return string.format("%s = Vector3.new(%s, %s, %s)", name, tostring(round(value.X)), tostring(round(value.Y)), tostring(round(value.Z)))
end

function Debugger.new(state, animation)
    return setmetatable({
        State = state,
        Animation = animation,
        Gui = nil,
        Body = nil,
        Summary = nil,
        WeaponRemote = nil,
        Step = 0.05,
        PreviewMode = "RightHand",
        Offsets = nil,
        Connections = {},
    }, Debugger)
end

function Debugger:Start()
    if not Config.Debug or Config.Debug.Enabled ~= true then return end
    self.WeaponRemote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self.Offsets = WeaponVisuals.CopyOffsets(WeaponVisuals.Get("Rifle"))
    self:Build()
    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.F6 then
            self.Gui.Enabled = not self.Gui.Enabled
            self:Refresh()
        end
    end))
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if self.Gui and self.Gui.Enabled then
            self:RefreshSummary()
        end
    end))
end

function Debugger:Build()
    local gui = make(Players.LocalPlayer:WaitForChild("PlayerGui"), "ScreenGui", {
        Name = "WeaponOffsetDebugger",
        ResetOnSpawn = false,
        Enabled = false,
    })
    self.Gui = gui

    local panel = make(gui, "Frame", {
        Size = UDim2.fromOffset(430, 660),
        Position = UDim2.fromOffset(24, 54),
        BackgroundColor3 = Color3.fromRGB(13, 17, 22),
        BorderSizePixel = 0,
    })
    make(panel, "UICorner", { CornerRadius = UDim.new(0, 8) })

    make(panel, "TextLabel", {
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(244, 248, 252),
        Text = "Weapon Offset Debugger (F6)",
    })

    self.Summary = make(panel, "TextLabel", {
        Size = UDim2.new(1, -16, 0, 106),
        Position = UDim2.fromOffset(8, 36),
        BackgroundColor3 = Color3.fromRGB(9, 12, 17),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Color3.fromRGB(220, 230, 240),
        Text = "",
    })

    local body = make(panel, "ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -152),
        Position = UDim2.fromOffset(8, 148),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    make(body, "UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Body = body
    self:Refresh()
end

function Debugger:Button(text, callback)
    local button = make(self.Body, "TextButton", {
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundColor3 = Color3.fromRGB(38, 48, 60),
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextColor3 = Color3.fromRGB(242, 246, 250),
        Text = text,
    })
    button.MouseButton1Click:Connect(callback)
    return button
end

function Debugger:Label(text)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -8, 0, 22),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(130, 205, 255),
        Text = text,
    })
end

function Debugger:Clear()
    for _, child in ipairs(self.Body:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

function Debugger:SendOffsets()
    self.WeaponRemote:FireServer({
        Action = "SetVisualOffsets",
        WeaponId = self.State.EquippedWeaponId or "Rifle",
        PreviewMode = self.PreviewMode,
        Offsets = self.Offsets,
    })
end

function Debugger:Nudge(key, axis, direction)
    local value = self.Offsets[key]
    local delta = self.Step * direction
    if axis == "X" then
        value = Vector3.new(value.X + delta, value.Y, value.Z)
    elseif axis == "Y" then
        value = Vector3.new(value.X, value.Y + delta, value.Z)
    else
        value = Vector3.new(value.X, value.Y, value.Z + delta)
    end
    self.Offsets[key] = value
    self:SendOffsets()
    self:Refresh()
end

function Debugger:AddAxisRows(title, posKey, rotKey)
    self:Label(title)
    for _, axis in ipairs({ "X", "Y", "Z" }) do
        self:Button(string.format("Position %s -", axis), function() self:Nudge(posKey, axis, -1) end)
        self:Button(string.format("Position %s +", axis), function() self:Nudge(posKey, axis, 1) end)
        self:Button(string.format("Rotation %s -", axis), function() self:Nudge(rotKey, axis, -1) end)
        self:Button(string.format("Rotation %s +", axis), function() self:Nudge(rotKey, axis, 1) end)
    end
end

function Debugger:CopyPrint()
    local lines = {
        formatVector("GripPositionOffset", self.Offsets.GripPositionOffset),
        formatVector("GripRotationOffset", self.Offsets.GripRotationOffset),
        formatVector("BackHolsterPositionOffset", self.Offsets.BackHolsterPositionOffset),
        formatVector("BackHolsterRotationOffset", self.Offsets.BackHolsterRotationOffset),
    }
    warn("[WeaponOffsetDebugger]\n" .. table.concat(lines, "\n"))
end

function Debugger:RefreshSummary()
    local debugState = self.Animation and self.Animation:GetDebugState() or {}
    self.Summary.Text = table.concat({
        string.format("Weapon: %s", tostring(self.State.EquippedWeaponId or "None")),
        string.format("Mode: %s | Attach: %s | Step: %.2f", tostring(debugState.Mode or "None"), self.PreviewMode, self.Step),
        string.format("Loop: %s | Action: %s | Weapon: %s", tostring(debugState.CurrentLoop), tostring(debugState.CurrentAction), tostring(debugState.CurrentWeapon)),
        formatVector("GripPositionOffset", self.Offsets.GripPositionOffset),
        formatVector("GripRotationOffset", self.Offsets.GripRotationOffset),
        formatVector("BackHolsterPositionOffset", self.Offsets.BackHolsterPositionOffset),
        formatVector("BackHolsterRotationOffset", self.Offsets.BackHolsterRotationOffset),
    }, "\n")
end

function Debugger:Refresh()
    if not self.Body then return end
    self:RefreshSummary()
    self:Clear()

    self:Label("Step Size")
    for _, step in ipairs({ 0.01, 0.05, 0.1, 0.5 }) do
        self:Button((self.Step == step and "* " or "") .. tostring(step), function()
            self.Step = step
            self:Refresh()
        end)
    end

    self:Label("Preview Attach")
    for _, mode in ipairs({ "RightHand", "BackHolster" }) do
        self:Button((self.PreviewMode == mode and "* " or "") .. mode, function()
            self.PreviewMode = mode
            self.WeaponRemote:FireServer({ Action = "VisualAttachMode", Mode = mode })
            self:Refresh()
        end)
    end

    self:AddAxisRows("Right-Hand Grip", "GripPositionOffset", "GripRotationOffset")
    self:AddAxisRows("Back Holster", "BackHolsterPositionOffset", "BackHolsterRotationOffset")

    self:Label("Actions")
    self:Button("Reset to Rifle Defaults", function()
        self.Offsets = WeaponVisuals.CopyOffsets(WeaponVisuals.Get("Rifle"))
        self:SendOffsets()
        self:Refresh()
    end)
    self:Button("Print Pasteable Offsets", function() self:CopyPrint() end)

    self:Label("Preview Animations")
    for _, label in ipairs({
        "Idle",
        "Idle_Rifle",
        "Idle_rifle_aim",
        "Sprint(remp)",
        "Jump_Start",
        "Jump_Loop",
        "Float",
        "Float_Reverse",
        "Double_Jump",
        "Crouch_Idle",
    }) do
        self:Button(label, function()
            if self.Animation and self.Animation.DebugPlayAnimation then
                self.Animation:DebugPlayAnimation(label)
            end
        end)
    end
end

return Debugger
