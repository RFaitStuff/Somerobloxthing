--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared:WaitForChild("GameData"):WaitForChild("Weapons"))
local Net = require(Shared:WaitForChild("Net"))
local Util = require(Shared:WaitForChild("Util"))
local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local WeaponService = {}
WeaponService.__index = WeaponService

function WeaponService.new(playerState, profiles, combat)
    return setmetatable({ PlayerState = playerState, Profiles = profiles, Combat = combat, Remote = nil }, WeaponService)
end

function WeaponService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self.Remote.OnServerEvent:Connect(function(player, payload) self:Handle(player, payload) end)
end

function WeaponService:Replicate(player, weapon, runtime)
    local remote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponUpdate)
    remote:FireClient(player, {
        WeaponId = weapon.Id,
        Ammo = runtime.Ammo,
        Magazine = weapon.Magazine or 1,
        ReloadUntil = runtime.ReloadUntil or 0,
        LastFire = runtime.LastFire or 0,
    })
end

function WeaponService:ReplicateEquipped(player)
    local profile = self.Profiles:Get(player)
    local weapon = Weapons.Get(profile.Equipped.ActiveWeapon)
    if weapon and weapon.Kind == "Ranged" then
        self:Replicate(player, weapon, self:GetRuntime(player, weapon))
    end
end

function WeaponService:GetRuntime(player, weapon)
    local state = self.PlayerState:Get(player)
    local runtime = state.WeaponRuntime[weapon.Id]
    if not runtime then
        runtime = { Ammo = weapon.Magazine or 1, LastFire = 0, ReloadUntil = 0 }
        state.WeaponRuntime[weapon.Id] = runtime
    end
    return runtime
end

function WeaponService:Reload(player, weapon, runtime)
    runtime.ReloadUntil = os.clock() + (weapon.ReloadTime or 1)
    self:Replicate(player, weapon, runtime)
    task.delay(weapon.ReloadTime or 1, function()
        runtime.Ammo = weapon.Magazine or runtime.Ammo
        runtime.ReloadUntil = 0
        self:Replicate(player, weapon, runtime)
    end)
end

function WeaponService:GetShotDirection(baseDirection, spreadDegrees)
    local spread = math.rad(spreadDegrees or 0)
    if spread <= 0 then return baseDirection end
    local yaw = (math.random() - 0.5) * spread
    local pitch = (math.random() - 0.5) * spread
    return (CFrame.lookAt(Vector3.zero, baseDirection) * CFrame.Angles(pitch, yaw, 0)).LookVector
end

function WeaponService:CollectRadiusTargets(center, radius, params)
    local targets = {}
    local parts = workspace:GetPartBoundsInRadius(center, radius, params)
    for _, part in ipairs(parts) do
        local humanoid = Util.FindHumanoidFromPart(part)
        if humanoid and humanoid.Health > 0 then
            targets[humanoid] = true
        end
    end
    return targets
end

function WeaponService:DamageTargets(player, targets, weapon)
    for humanoid in pairs(targets) do
        self.Combat:Damage(player, humanoid, { Damage = weapon.Damage or 1, Element = weapon.Element, SourceType = "Weapon" })
    end
end

function WeaponService:SendShotFeedback(player, weapon, origin, direction, hitPosition)
    Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback):FireAllClients({
        Type = "Shot",
        Player = player,
        WeaponId = weapon.Id,
        Origin = origin,
        HitPosition = hitPosition or origin + direction * (weapon.Range or 300),
        Simulation = weapon.Simulation or "Hitscan",
    })
end

function WeaponService:FireImpactRay(player, weapon, origin, direction, params)
    local result = workspace:Raycast(origin, direction * (weapon.Range or 300), params)
    local impact = result and result.Position or origin + direction * (weapon.Range or 300)
    self:SendShotFeedback(player, weapon, origin, direction, impact)
    local targets = self:CollectRadiusTargets(impact, weapon.Radius or 10, params)
    if result then
        local humanoid = Util.FindHumanoidFromPart(result.Instance)
        if humanoid and humanoid.Health > 0 then
            targets[humanoid] = true
        end
    end
    self:DamageTargets(player, targets, weapon)
end

function WeaponService:FireArmedImpactRay(player, weapon, origin, direction, params)
    local result = workspace:Raycast(origin, direction * (weapon.Range or 300), params)
    local impact = result and result.Position or origin + direction * (weapon.Range or 300)
    self:SendShotFeedback(player, weapon, origin, direction, impact)
    local traveled = (impact - origin).Magnitude
    if traveled < (weapon.ArmDistance or 0) then
        if result then
            local humanoid = Util.FindHumanoidFromPart(result.Instance)
            if humanoid and humanoid.Health > 0 then
                self:DamageTargets(player, { [humanoid] = true }, weapon)
            end
        end
        return
    end
    local targets = self:CollectRadiusTargets(impact, weapon.Radius or 10, params)
    if result then
        local humanoid = Util.FindHumanoidFromPart(result.Instance)
        if humanoid and humanoid.Health > 0 then
            targets[humanoid] = true
        end
    end
    self:DamageTargets(player, targets, weapon)
    Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback):FireAllClients({
        Type = "Explosion",
        Position = impact,
        Radius = weapon.Radius or 10,
    })
end

function WeaponService:FireHitscan(player, weapon, origin, direction, params)
    local count = weapon.Pellets or 1
    local hitHumanoids = {}
    for _ = 1, count do
        local dir = self:GetShotDirection(direction, weapon.Spread or 0)
        local result = workspace:Raycast(origin, dir * (weapon.Range or 300), params)
        self:SendShotFeedback(player, weapon, origin, dir, result and result.Position or nil)
        if result then
            local humanoid = Util.FindHumanoidFromPart(result.Instance)
            if humanoid and humanoid.Health > 0 then
                hitHumanoids[humanoid] = true
            end
        end
    end
    self:DamageTargets(player, hitHumanoids, weapon)
end

function WeaponService:Fire(player, weapon, runtime, payload)
    if ActionLocks.IsControlLocked(self.PlayerState:Get(player)) then ValidationAudit.Reject(player, "Weapon", "ControlLocked") return end
    local now = os.clock()
    if runtime.ReloadUntil > now then ValidationAudit.Reject(player, "Weapon", "Reloading") return end
    if now - runtime.LastFire < 1 / math.max(weapon.FireRate or 1, 0.1) then ValidationAudit.Reject(player, "Weapon", "FireRate") return end
    if runtime.Ammo <= 0 then self:Reload(player, weapon, runtime) return end
    runtime.LastFire = now
    runtime.Ammo -= 1
    self:Replicate(player, weapon, runtime)

    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then ValidationAudit.Reject(player, "Weapon", "NoCharacterRoot") return end
    local direction = root.CFrame.LookVector
    if typeof(payload.Direction) == "Vector3" and payload.Direction.Magnitude > 0.01 then
        direction = payload.Direction.Unit
    end
    local origin = self:GetMuzzleOrigin(character, direction, payload.Origin)
    local params = Util.MakeRaycastParams({ character })
    if weapon.Simulation == "ArmedImpactRay" then
        self:FireArmedImpactRay(player, weapon, origin, direction, params)
    elseif weapon.Simulation == "ImpactRay" then
        self:FireImpactRay(player, weapon, origin, direction, params)
    else
        self:FireHitscan(player, weapon, origin, direction, params)
    end
end

function WeaponService:GetMuzzleOrigin(character, direction, clientOrigin)
    local serverOrigin
    if character then
        local muzzle = character:FindFirstChild("Muzzle", true)
        if muzzle then
            if muzzle:IsA("Attachment") then serverOrigin = muzzle.WorldPosition end
            if muzzle:IsA("BasePart") then serverOrigin = muzzle.Position end
        end
        if not serverOrigin then
            local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
            if torso and torso:IsA("BasePart") then
                serverOrigin = (torso.CFrame * CFrame.new(0.2, 0.05, -1.15)).Position
            end
        end
        if not serverOrigin then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root and root:IsA("BasePart") then
                serverOrigin = (root.CFrame * CFrame.new(0.25, 1.25, -1.15)).Position
            end
        end
    end
    serverOrigin = serverOrigin or direction * 1.15
    if typeof(clientOrigin) == "Vector3" and (clientOrigin - serverOrigin).Magnitude <= 5 then
        return clientOrigin
    end
    return serverOrigin
end

function WeaponService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Weapon", "BadPayload") return end
    local profile = self.Profiles:Get(player)
    if payload.Action == "Equip" then
        if ActionLocks.IsControlLocked(self.PlayerState:Get(player)) then ValidationAudit.Reject(player, "Weapon", "ControlLocked") return end
        if self.Profiles:EquipWeapon(player, payload.Slot or "Primary", payload.WeaponId) then
            local equipped = Weapons.Get(payload.WeaponId)
            if equipped and equipped.Kind == "Ranged" then
                self:Replicate(player, equipped, self:GetRuntime(player, equipped))
            end
        else
            ValidationAudit.Reject(player, "Weapon", "InvalidEquip")
        end
        return
    end
    local weapon = Weapons.Get(profile.Equipped.ActiveWeapon)
    if not weapon or weapon.Kind ~= "Ranged" then ValidationAudit.Reject(player, "Weapon", "NoRangedWeapon") return end
    local runtime = self:GetRuntime(player, weapon)
    if payload.Action == "Reload" then
        if ActionLocks.IsControlLocked(self.PlayerState:Get(player)) then ValidationAudit.Reject(player, "Weapon", "ControlLocked") return end
        self:Reload(player, weapon, runtime)
    elseif payload.Action == "Fire" then
        self:Fire(player, weapon, runtime, payload)
    else
        ValidationAudit.Reject(player, "Weapon", "UnknownAction")
    end
end

return WeaponService
