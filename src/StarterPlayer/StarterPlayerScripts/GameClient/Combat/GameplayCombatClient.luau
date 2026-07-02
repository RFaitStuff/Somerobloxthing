--!nonstrict
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))

local GameplayCombatClient = {}
GameplayCombatClient.__index = GameplayCombatClient

function GameplayCombatClient.new(state, input, camera)
    return setmetatable({
        State = state,
        Input = input,
        Camera = camera,
        WeaponRemote = nil,
        AbilityRemote = nil,
        ProfileRemote = nil,
        Connections = {},
        LastFire = 0,
    }, GameplayCombatClient)
end

function GameplayCombatClient:Start()
    self.WeaponRemote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self.AbilityRemote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityRequest)
    self.ProfileRemote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileRequest)
    table.insert(self.Connections, RunService.Heartbeat:Connect(function()
        self:Update()
    end))
end

function GameplayCombatClient:GetAimDirection()
    local camera = workspace.CurrentCamera
    return camera and camera.CFrame.LookVector or Vector3.zAxis
end

function GameplayCombatClient:GetMuzzleOrigin(direction)
    local player = game:GetService("Players").LocalPlayer
    local character = player.Character
    if character then
        local muzzle = character:FindFirstChild("Muzzle", true)
        if muzzle then
            if muzzle:IsA("Attachment") then return muzzle.WorldPosition end
            if muzzle:IsA("BasePart") then return muzzle.Position end
        end
        local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
        if torso and torso:IsA("BasePart") then
            return (torso.CFrame * CFrame.new(0.2, 0.05, -1.15)).Position
        end
        local root = character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            return (root.CFrame * CFrame.new(0.25, 1.25, -1.15)).Position
        end
    end
    local camera = workspace.CurrentCamera
    if camera then
        return camera.CFrame.Position + direction.Unit * 1.15
    end
    return Vector3.new(0, 6, 0) + direction.Unit * 1.15
end

function GameplayCombatClient:GetSpreadAimDirection()
    local base = self:GetAimDirection()
    local weapon = Weapons.Get(self.State.EquippedWeaponId)
    local spread = math.rad(weapon and weapon.Spread or 0)
    if spread <= 0 then return base end
    local yaw = (math.random() - 0.5) * spread
    local pitch = (math.random() - 0.5) * spread
    return (CFrame.lookAt(Vector3.zero, base) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

function GameplayCombatClient:CastSlot(slot)
    local profile = self.State.Profile
    local frameState = profile and profile.Frames and profile.Frames[profile.SelectedFrameId]
    local abilityId = frameState and frameState.SelectedVariants and frameState.SelectedVariants[slot]
    if not abilityId then return end
    self.AbilityRemote:FireServer({ Slot = slot, AbilityId = abilityId, Direction = self:GetAimDirection() })
end

function GameplayCombatClient:SwitchGun()
    local profile = self.State.Profile
    local equipped = profile and profile.Equipped
    if not equipped then return end
    local active = equipped.ActiveWeapon
    local nextWeapon = active == equipped.Primary and equipped.Secondary or equipped.Primary
    if nextWeapon then
        self.WeaponRemote:FireServer({ Action = "Equip", Slot = nextWeapon == equipped.Secondary and "Secondary" or "Primary", WeaponId = nextWeapon })
    end
end

function GameplayCombatClient:Update()
    if self.Input:ConsumePressed("Ability1") then self:CastSlot(1) end
    if self.Input:ConsumePressed("Ability2") then self:CastSlot(2) end
    if self.Input:ConsumePressed("Ability3") then self:CastSlot(3) end
    if self.Input:ConsumePressed("Ability4") then self:CastSlot(4) end
    if self.Input:ConsumePressed("SwitchWeapon") then self:SwitchGun() end
    local weaponId = self.State.EquippedWeaponId
    local weapon = Weapons.Get(weaponId)
    local fireMode = weapon and weapon.FireMode or "Auto"
    local pressed = self.Input:ConsumePressed("Fire")
    local wantsFire = pressed or ((fireMode == "Auto" or fireMode == "Beam") and self.Input:IsHeld("Fire"))
    if wantsFire then
        local now = os.clock()
        if weapon and now - self.LastFire < 1 / math.max(weapon.FireRate or 1, 0.1) then
            return
        end
        self.LastFire = now
        -- Send raw camera aim. Server applies weapon spread so damage is not client-authored.
        local direction = self:GetAimDirection()
        if self.Camera and self.Camera.AddRecoil then
            self.Camera:AddRecoil((weapon and weapon.Recoil) or 0)
        end
        self.WeaponRemote:FireServer({ Action = "Fire", Direction = direction, Origin = self:GetMuzzleOrigin(direction), Pressed = pressed })
    end
end

return GameplayCombatClient
