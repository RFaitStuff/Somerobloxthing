--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local WeaponVisuals = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("WeaponVisuals"))
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Util = require(Shared:WaitForChild("Core"):WaitForChild("Util"))
local ActionLocks = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ActionLocks"))
local ValidationAudit = require(script.Parent.Parent:WaitForChild("Core"):WaitForChild("ValidationAudit"))

local WeaponService = {}
WeaponService.__index = WeaponService

function WeaponService.new(playerState, profiles, combat)
    return setmetatable({
        PlayerState = playerState,
        Profiles = profiles,
        Combat = combat,
        Remote = nil,
        VisualOverrides = {},
    }, WeaponService)
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
        self:EquipWeapon(player, weapon.Id)
        self:Replicate(player, weapon, self:GetRuntime(player, weapon))
    end
end

function WeaponService:ResolvePath(path)
    local current = game
    for index, name in ipairs(path or {}) do
        if index == 1 then
            local ok, service = pcall(function()
                return game:GetService(name)
            end)
            current = ok and service or current:FindFirstChild(name)
        else
            current = current and current:FindFirstChild(name)
        end
        if not current then return nil end
    end
    return current
end

function WeaponService:GetVisualOverride(player, weaponId)
    local playerOverrides = self.VisualOverrides[player]
    return playerOverrides and playerOverrides[weaponId] or nil
end

function WeaponService:GetVisualConfig(player, weaponId)
    local base = WeaponVisuals.Get(weaponId)
    if not base then return nil end
    local config = table.clone(base)
    local override = self:GetVisualOverride(player, weaponId)
    if override then
        for key, value in pairs(override) do
            config[key] = value
        end
    end
    return config
end

function WeaponService:GetCharacterWeapon(character)
    local model = character and character:FindFirstChild("EquippedWeaponVisual")
    if model and model:IsA("Model") then return model end
    return nil
end

function WeaponService:PrepareWeaponModel(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("BasePart") then
            descendant.Anchored = false
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.Massless = true
        end
    end
end

function WeaponService:CreateFallbackWeaponModel(weaponName)
    local model = Instance.new("Model")
    model.Name = tostring(weaponName or "FallbackWeapon")

    local handle = Instance.new("Part")
    handle.Name = "HandleRight"
    handle.Size = Vector3.new(0.45, 0.55, 3.2)
    handle.Color = Color3.fromRGB(70, 82, 96)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.Massless = true
    handle.Parent = model
    model.PrimaryPart = handle

    local muzzle = Instance.new("Attachment")
    muzzle.Name = "Muzzle"
    muzzle.Position = Vector3.new(0, 0, -1.7)
    muzzle.Parent = handle

    local left = Instance.new("Attachment")
    left.Name = "HandleLeft"
    left.Position = Vector3.new(0, 0, -0.7)
    left.Parent = handle

    local aim = Instance.new("Attachment")
    aim.Name = "AimPart"
    aim.Position = Vector3.new(0, 0.18, -0.8)
    aim.Parent = handle

    return model
end

function WeaponService:ClearWeaponMotor(model)
    if not model then return end
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("Motor6D") and descendant.Name == "ControllerWeaponMotor" then
            descendant:Destroy()
        end
    end
end

function WeaponService:GetRightHand(character)
    return character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
end

function WeaponService:GetBackHolsterPart(character)
    return character and (character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart"))
end

function WeaponService:AttachWeaponToRightHand(character, weaponModel, config)
    if not character or not weaponModel or not config then return false end
    local hand = self:GetRightHand(character)
    local handle = weaponModel:FindFirstChild(config.MainHandle or "HandleRight", true)
    if not hand or not handle or not hand:IsA("BasePart") or not handle:IsA("BasePart") then
        return false
    end

    self:ClearWeaponMotor(weaponModel)
    local motor = Instance.new("Motor6D")
    motor.Name = "ControllerWeaponMotor"
    motor.Part0 = hand
    motor.Part1 = handle
    motor.C0 = WeaponVisuals.GetGripCFrame(config)
    motor.C1 = CFrame.identity
    motor.Parent = hand
    weaponModel:SetAttribute("AttachMode", "RightHand")
    return true
end

function WeaponService:AttachWeaponToBackHolster(character, weaponModel, config)
    if not character or not weaponModel or not config then return false end
    local torso = self:GetBackHolsterPart(character)
    local handle = weaponModel:FindFirstChild(config.MainHandle or "HandleRight", true)
    if not torso or not handle or not torso:IsA("BasePart") or not handle:IsA("BasePart") then
        return false
    end

    self:ClearWeaponMotor(weaponModel)
    local motor = Instance.new("Motor6D")
    motor.Name = "ControllerWeaponMotor"
    motor.Part0 = torso
    motor.Part1 = handle
    motor.C0 = WeaponVisuals.GetBackHolsterCFrame(config)
    motor.C1 = CFrame.identity
    motor.Parent = torso
    weaponModel:SetAttribute("AttachMode", "BackHolster")
    return true
end

function WeaponService:EquipWeapon(player, weaponName)
    local character = player.Character
    if not character then return false end
    local config = self:GetVisualConfig(player, weaponName)
    if not config then return false end

    local existing = self:GetCharacterWeapon(character)
    if existing then existing:Destroy() end

    local source = self:ResolvePath(config.ModelPath)
    if not source then
        warn(string.format("[WeaponService] Missing weapon model for %s; using generated rifle fallback", tostring(weaponName)))
    end

    local clone = source and source:Clone() or self:CreateFallbackWeaponModel(weaponName)
    clone.Name = "EquippedWeaponVisual"
    clone:SetAttribute("WeaponName", weaponName)
    clone:SetAttribute("VisualConfigName", config.WeaponName or weaponName)
    clone.Parent = character
    self:PrepareWeaponModel(clone)
    return self:AttachWeaponToRightHand(character, clone, config)
end

function WeaponService:UnequipWeapon(player)
    local character = player.Character
    local existing = self:GetCharacterWeapon(character)
    if existing then existing:Destroy() end
end

function WeaponService:SetAttachMode(player, mode)
    local character = player.Character
    local model = self:GetCharacterWeapon(character)
    if not model then return false end
    local weaponId = model:GetAttribute("WeaponName") or self.PlayerState:Get(player).EquippedWeaponId or "Rifle"
    local config = self:GetVisualConfig(player, weaponId)
    if mode == "BackHolster" then
        return self:AttachWeaponToBackHolster(character, model, config)
    end
    return self:AttachWeaponToRightHand(character, model, config)
end

function WeaponService:SetVisualOffsets(player, weaponId, offsets, previewMode)
    if typeof(offsets) ~= "table" then return false end
    weaponId = weaponId or self.PlayerState:Get(player).EquippedWeaponId or "Rifle"
    self.VisualOverrides[player] = self.VisualOverrides[player] or {}
    local current = self.VisualOverrides[player][weaponId] or {}
    for _, key in ipairs({ "GripPositionOffset", "GripRotationOffset", "BackHolsterPositionOffset", "BackHolsterRotationOffset" }) do
        if typeof(offsets[key]) == "Vector3" then
            current[key] = offsets[key]
        end
    end
    self.VisualOverrides[player][weaponId] = current
    return self:SetAttachMode(player, previewMode or (player.Character and self:GetCharacterWeapon(player.Character) and self:GetCharacterWeapon(player.Character):GetAttribute("AttachMode")) or "RightHand")
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
    if runtime.ReloadUntil and runtime.ReloadUntil > os.clock() then return end
    if (runtime.Ammo or 0) >= (weapon.Magazine or 1) then
        self:Replicate(player, weapon, runtime)
        return
    end
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
    if typeof(params) ~= "OverlapParams" then
        params = Util.MakeOverlapParams({})
    end
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
        FireMode = weapon.FireMode,
        Element = weapon.Element,
        Origin = origin,
        HitPosition = hitPosition or origin + direction * (weapon.Range or 300),
        Simulation = weapon.Simulation or "Hitscan",
        BeamWidth = weapon.BeamWidth,
        ProjectileColor = weapon.ProjectileColor,
    })
end

function WeaponService:FireImpactRay(player, weapon, origin, direction, params, overlapParams)
    local result = workspace:Raycast(origin, direction * (weapon.Range or 300), params)
    local impact = result and result.Position or origin + direction * (weapon.Range or 300)
    self:SendShotFeedback(player, weapon, origin, direction, impact)
    local targets = self:CollectRadiusTargets(impact, weapon.Radius or 10, overlapParams)
    if result then
        local humanoid = Util.FindHumanoidFromPart(result.Instance)
        if humanoid and humanoid.Health > 0 then
            targets[humanoid] = true
        end
    end
    self:DamageTargets(player, targets, weapon)
    if (weapon.Radius or 0) > 0 then
        Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback):FireAllClients({
            Type = "Explosion",
            Position = impact,
            Radius = weapon.Radius or 10,
            Element = weapon.Element,
            WeaponId = weapon.Id,
        })
    end
end

function WeaponService:FireArmedImpactRay(player, weapon, origin, direction, params, overlapParams)
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
    local targets = self:CollectRadiusTargets(impact, weapon.Radius or 10, overlapParams)
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
        Element = weapon.Element,
        WeaponId = weapon.Id,
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


function WeaponService:FireProjectileRay(player, weapon, origin, direction, params, overlapParams)
    local speed = math.max(weapon.ProjectileSpeed or 140, 20)
    local range = weapon.Range or 300
    local radius = weapon.HitRadius or weapon.ProjectileRadius or 0.6
    local traveled = 0
    local position = origin
    local alive = true
    task.spawn(function()
        local lastStep = os.clock()
        while alive and traveled < range do
            local now = os.clock()
            local dt = math.clamp(now - lastStep, 1 / 120, 1 / 20)
            lastStep = now
            local stepDistance = math.min(speed * dt, range - traveled)
            local delta = direction * stepDistance
            local result = radius > 0 and Util.Spherecast(position, radius, delta, params) or workspace:Raycast(position, delta, params)
            local hitPosition = result and result.Position or position + delta
            if result then
                self:SendShotFeedback(player, weapon, origin, direction, hitPosition)
                local targets = self:CollectRadiusTargets(hitPosition, weapon.Radius or radius or 2, overlapParams)
                local humanoid = Util.FindHumanoidFromPart(result.Instance)
                if humanoid and humanoid.Health > 0 then targets[humanoid] = true end
                self:DamageTargets(player, targets, weapon)
                if (weapon.Radius or 0) > 0 then
                    Net.GetRemoteEvent(Net.RemoteEvents.CombatFeedback):FireAllClients({ Type = "Explosion", Position = hitPosition, Radius = weapon.Radius, Element = weapon.Element, WeaponId = weapon.Id })
                end
                return
            end
            position = hitPosition
            traveled += stepDistance
            task.wait()
        end
        self:SendShotFeedback(player, weapon, origin, direction, position)
    end)
end

function WeaponService:Fire(player, weapon, runtime, payload)
    local playerState = self.PlayerState:Get(player)
    if playerState.SafeZone and not playerState.TrainingRange then ValidationAudit.Reject(player, "Weapon", "SafeZone") return end
    if ActionLocks.IsControlLocked(playerState) then ValidationAudit.Reject(player, "Weapon", "ControlLocked") return end
    local now = os.clock()
    if runtime.ReloadUntil > now then ValidationAudit.Reject(player, "Weapon", "Reloading") return end
    if now - runtime.LastFire < 1 / math.max(weapon.FireRate or 1, 0.1) then ValidationAudit.Reject(player, "Weapon", "FireRate") return end
    if weapon.FireMode == "Semi" or weapon.FireMode == "Projectile" then
        if payload.Pressed ~= true then ValidationAudit.Reject(player, "Weapon", "RequiresPress") return end
    end
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
    local origin = self:GetMuzzleOrigin(character, direction, payload.Origin, weapon)
    if not origin then ValidationAudit.Reject(player, "Weapon", "NoMuzzleOrigin") return end
    local params = Util.MakeRaycastParams({ character })
    local overlapParams = Util.MakeOverlapParams({ character })
    local projectileDirection = self:GetShotDirection(direction, weapon.Spread or 0)
    if weapon.Simulation == "ProjectileRay" then
        self:FireProjectileRay(player, weapon, origin, projectileDirection, params, overlapParams)
    elseif weapon.Simulation == "ArmedImpactRay" then
        self:FireArmedImpactRay(player, weapon, origin, projectileDirection, params, overlapParams)
    elseif weapon.Simulation == "ImpactRay" then
        self:FireImpactRay(player, weapon, origin, projectileDirection, params, overlapParams)
    else
        self:FireHitscan(player, weapon, origin, direction, params)
    end
end

function WeaponService:GetMuzzleOrigin(character, direction, clientOrigin, weapon)
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
                local offset = weapon and weapon.MuzzleOffset or Vector3.new(0.25, 1.25, -1.15)
                serverOrigin = (root.CFrame * CFrame.new(offset)).Position
            end
        end
    end
    if not serverOrigin then return nil end
    if typeof(clientOrigin) == "Vector3" and (clientOrigin - serverOrigin).Magnitude <= 5 then
        return clientOrigin
    end
    return serverOrigin
end

function WeaponService:Handle(player, payload)
    if typeof(payload) ~= "table" then ValidationAudit.Reject(player, "Weapon", "BadPayload") return end
    local profile = self.Profiles:Get(player)
    if payload.Action == "VisualAttachMode" then
        local mode = payload.Mode == "BackHolster" and "BackHolster" or "RightHand"
        if not self:SetAttachMode(player, mode) then
            ValidationAudit.Reject(player, "Weapon", "InvalidVisualAttach")
        end
        return
    elseif payload.Action == "SetVisualOffsets" then
        if not self:SetVisualOffsets(player, payload.WeaponId, payload.Offsets, payload.PreviewMode) then
            ValidationAudit.Reject(player, "Weapon", "InvalidVisualOffsets")
        end
        return
    end
    if payload.Action == "Equip" then
        if ActionLocks.IsControlLocked(self.PlayerState:Get(player)) then ValidationAudit.Reject(player, "Weapon", "ControlLocked") return end
        if self.Profiles:EquipWeapon(player, payload.Slot or "Primary", payload.WeaponId) then
            local equipped = Weapons.Get(payload.WeaponId)
            if equipped and equipped.Kind == "Ranged" then
                self:EquipWeapon(player, equipped.Id)
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
