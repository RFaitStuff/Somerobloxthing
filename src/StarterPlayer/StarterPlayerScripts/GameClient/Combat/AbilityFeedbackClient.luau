--!nonstrict
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Net"))

local AbilityFeedback = {}
AbilityFeedback.__index = AbilityFeedback

local ELEMENT_COLORS = {
    Fire = Color3.fromRGB(255, 118, 54),
    Light = Color3.fromRGB(255, 241, 159),
    Air = Color3.fromRGB(148, 226, 255),
    Lightning = Color3.fromRGB(142, 180, 255),
    Dark = Color3.fromRGB(178, 116, 255),
    Earth = Color3.fromRGB(178, 130, 86),
}

function AbilityFeedback.new()
    return setmetatable({ Folder = nil }, AbilityFeedback)
end

function AbilityFeedback:GetFolder()
    if self.Folder and self.Folder.Parent then return self.Folder end
    local folder = workspace:FindFirstChild("AbilityFeedback")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "AbilityFeedback"
        folder.Parent = workspace
    end
    self.Folder = folder
    return folder
end

function AbilityFeedback:GetColor(payload)
    return ELEMENT_COLORS[payload.Element] or Color3.fromRGB(160, 220, 255)
end

function AbilityFeedback:Part(name, color, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Color = color
    part.Transparency = transparency or 0.35
    part.Parent = self:GetFolder()
    return part
end

function AbilityFeedback:PlaySound(payload, parent)
    local soundId = payload.SFX and (payload.SFX[payload.Type] or payload.SFX.Cast)
    if type(soundId) ~= "string" or soundId == "" or not parent then return end
    local sound = Instance.new("Sound")
    sound.Name = "AbilitySFX"
    sound.SoundId = soundId
    sound.Volume = 0.45
    sound.RollOffMaxDistance = 90
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 4)
end

function AbilityFeedback:Burst(payload, radius, lifetime)
    if typeof(payload.CastPosition) ~= "Vector3" then return end
    local part = self:Part("Ability" .. tostring(payload.Type or "Burst"), self:GetColor(payload), 0.42)
    part.Shape = Enum.PartType.Ball
    part.Size = Vector3.new(radius, radius, radius)
    part.CFrame = CFrame.new(payload.CastPosition)
    self:PlaySound(payload, part)
    Debris:AddItem(part, lifetime or 0.2)
end

function AbilityFeedback:Line(payload, length, lifetime)
    if typeof(payload.CastPosition) ~= "Vector3" or typeof(payload.Direction) ~= "Vector3" then return end
    local direction = payload.Direction.Magnitude > 0.01 and payload.Direction.Unit or Vector3.new(0, 0, -1)
    local part = self:Part("AbilityLine", self:GetColor(payload), 0.28)
    part.Size = Vector3.new(0.16, 0.16, length)
    part.CFrame = CFrame.lookAt(payload.CastPosition + direction * length * 0.5, payload.CastPosition + direction * length)
    Debris:AddItem(part, lifetime or 0.12)
end

function AbilityFeedback:Field(payload)
    if typeof(payload.CastPosition) ~= "Vector3" then return end
    local radius = math.max(4, tonumber(payload.Radius) or 14)
    local part = self:Part("AbilityFieldTick", self:GetColor(payload), 0.62)
    part.Shape = Enum.PartType.Cylinder
    part.Size = Vector3.new(0.16, radius * 2, radius * 2)
    part.CFrame = CFrame.new(payload.CastPosition + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
    Debris:AddItem(part, 0.2)
end

function AbilityFeedback:Handle(payload)
    if typeof(payload) ~= "table" or payload.Type == "Cooldown" then return end
    if payload.Type == "Cast" then
        self:Burst(payload, 2.4, 0.16)
        if payload.Block == "Beam" or payload.Block == "Whip" or payload.Block == "Projectile" then
            self:Line(payload, payload.Block == "Beam" and 80 or 28, 0.1)
        end
    elseif payload.Type == "Impact" then
        self:Burst(payload, 3 + math.min(10, tonumber(payload.TargetCount) or 0), 0.18)
    elseif payload.Type == "FieldTick" then
        self:Field(payload)
    elseif payload.Type == "FieldExpire" then
        self:Burst(payload, 5.5, 0.2)
    end
end

function AbilityFeedback:Start()
    Net.GetRemoteEvent(Net.RemoteEvents.AbilityUpdate).OnClientEvent:Connect(function(payload)
        self:Handle(payload)
    end)
end

return AbilityFeedback
