--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared:WaitForChild("GameData"):WaitForChild("Enemies"))
local Net = require(Shared:WaitForChild("Net"))
local UniversalAI = require(script.Parent.Parent:WaitForChild("Enemies"):WaitForChild("AI"):WaitForChild("UniversalAI"))

local EnemyService = {}
EnemyService.__index = EnemyService

function EnemyService.new(playerState, combat, rewards)
    return setmetatable({ PlayerState = playerState, Combat = combat, Rewards = rewards, Missions = nil, Folder = nil, Remote = nil, AI = UniversalAI.new(combat), Accumulator = 0, SpawnerAccumulator = 0, AIPaused = false }, EnemyService)
end

function EnemyService:Start()
    self.Remote = Net.GetRemoteEvent(Net.RemoteEvents.EnemyUpdate)
    self.Folder = workspace:FindFirstChild("TestEnemies") or Instance.new("Folder")
    self.Folder.Name = "TestEnemies"
    self.Folder.Parent = workspace
    RunService.Heartbeat:Connect(function(dt)
        self.Accumulator += dt
        if self.Accumulator < 0.2 then return end
        local step = self.Accumulator
        self.Accumulator = 0
        self:Update(step)
    end)
end

function EnemyService:SetMissionService(missions)
    self.Missions = missions
end

function EnemyService:SetAIPaused(paused)
    self.AIPaused = paused == true
    if self.Remote then
        self.Remote:FireAllClients({ Type = "AIPaused", Paused = self.AIPaused })
    end
end

function EnemyService:GetSpawnCFrame(player, offset)
    local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local base = root and root.CFrame or CFrame.new(0, 6, 0)
    return base * CFrame.new(offset or Vector3.new(0, 0, -28))
end

function EnemyService:GetSpawnCFrameFromWorld(cframe, offset)
    return cframe * CFrame.new(offset or Vector3.zero)
end

function EnemyService:ResolveDefinition(enemyIdOrRole)
    if Enemies[enemyIdOrRole] then return Enemies[enemyIdOrRole] end
    for _, def in pairs(Enemies) do
        if def.Role == enemyIdOrRole then
            return def
        end
    end
    return Enemies.Gunner
end

function EnemyService:GetFactionColor(def)
    if def.AIType == "Ranged" then
        return Color3.fromRGB(80, 155, 255)
    end
    if def.Faction == "VoidCult" then
        return def.AIType == "Ranged" and Color3.fromRGB(135, 75, 220) or Color3.fromRGB(95, 55, 150)
    end
    return def.AIType == "Ranged" and Color3.fromRGB(185, 110, 55) or Color3.fromRGB(155, 80, 45)
end

function EnemyService:AddPlaceholderGun(model, root, def)
    if (def.AIType or "Melee") ~= "Ranged" then return end
    local gun = Instance.new("Part")
    gun.Name = "EnemyGun"
    gun.Size = Vector3.new(0.45, 0.35, 2.4)
    gun.Color = Color3.fromRGB(95, 185, 255)
    gun.Material = Enum.Material.Neon
    gun.CanCollide = false
    gun.CanQuery = false
    gun.Massless = true
    gun.CFrame = root.CFrame * CFrame.new(1.35, 0.7, -1.05)
    gun.Parent = model

    local muzzle = Instance.new("Attachment")
    muzzle.Name = "Muzzle"
    muzzle.Position = Vector3.new(0, 0, -1.25)
    muzzle.Parent = gun

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = root
    weld.Part1 = gun
    weld.Parent = gun
end

function EnemyService:Spawn(player, enemyIdOrRole, offset, worldCFrame)
    local def = self:ResolveDefinition(enemyIdOrRole)
    local model = Instance.new("Model")
    model.Name = def.Name
    model:SetAttribute("EnemyId", def.Id)
    model:SetAttribute("EnemyRole", def.Role)
    model:SetAttribute("AIType", def.AIType or "Melee")
    model:SetAttribute("Faction", def.Faction)
    model:SetAttribute("Health", def.Health)
    model:SetAttribute("MaxHealth", def.Health)
    model:SetAttribute("Shield", def.Shield or 0)
    model:SetAttribute("MaxShield", def.Shield or 0)
    model:SetAttribute("Damage", def.Damage or 10)
    model:SetAttribute("AttackRange", def.Range or 8)
    model:SetAttribute("Accuracy", def.Accuracy or 0.7)
    model:SetAttribute("BurstCount", def.BurstCount or 1)
    model:SetAttribute("BurstInterval", def.BurstInterval or 0.08)
    model:SetAttribute("WeaponVisual", def.WeaponVisual or "")
    model:SetAttribute("AggroRange", def.AggroRange or 150)
    model:SetAttribute("PreferredRange", def.PreferredRange or 0)
    model:SetAttribute("RetreatRange", def.RetreatRange or 0)
    model:SetAttribute("FireRate", def.FireRate or 1)
    model:SetAttribute("Element", def.Element or "Kinetic")
    if def.StatusId then
        model:SetAttribute("StatusId", def.StatusId)
        model:SetAttribute("StatusChance", def.StatusChance or 1)
        model:SetAttribute("StatusDuration", def.StatusDuration or 1)
    end
    model:SetAttribute("LastAttack", 0)

    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(3, 5, 2)
    root.Color = self:GetFactionColor(def)
    root.Material = Enum.Material.SmoothPlastic
    root.CFrame = worldCFrame and self:GetSpawnCFrameFromWorld(worldCFrame, offset) or self:GetSpawnCFrame(player, offset)
    root.Parent = model
    self:AddPlaceholderGun(model, root, def)

    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = def.Health
    humanoid.Health = def.Health
    humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    humanoid.WalkSpeed = def.MoveSpeed or 10
    humanoid.Parent = model
    humanoid:SetAttribute("Armor", def.Armor or 0)
    humanoid:SetAttribute("MaxShield", def.Shield or 0)
    humanoid:SetAttribute("Shield", def.Shield or 0)

    model.PrimaryPart = root
    model.Parent = self.Folder

    humanoid.Died:Connect(function()
        local userId = humanoid:GetAttribute("LastDamagedBy")
        local source = humanoid:GetAttribute("LastDamageSource") or "Unknown"
        local attacker = userId and game:GetService("Players"):GetPlayerByUserId(userId)
        if attacker and self.Rewards then
            self.Rewards:AwardEnemyKill(attacker, def.Role, def.Id, source)
            if self.Missions then
                self.Missions:RecordEnemyKill(attacker, def.Role, def.Id)
            end
        end
        task.delay(2, function() if model then model:Destroy() end end)
    end)

    if self.Remote then self.Remote:FireAllClients({ Type = "Spawned", Role = def.Role, Name = def.Name }) end
    return model
end

function EnemyService:SpawnAtCFrame(enemyIdOrRole, cframe)
    return self:Spawn(nil, enemyIdOrRole, Vector3.zero, cframe)
end

function EnemyService:SpawnWave(player, role, count)
    for index = 1, count or 5 do
        self:Spawn(player, role, Vector3.new((index - 3) * 6, 0, -28 - index * 2))
    end
end

function EnemyService:Clear()
    if self.Folder then self.Folder:ClearAllChildren() end
end

function EnemyService:UpdateSpawners()
    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("BasePart") and instance:GetAttribute("EnemySpawner") == true then
            local spawnerId = instance:GetAttribute("SpawnerId")
            if not spawnerId then
                spawnerId = HttpService:GenerateGUID(false)
                instance:SetAttribute("SpawnerId", spawnerId)
            end
            local maxAlive = tonumber(instance:GetAttribute("MaxAlive")) or 4
            local alive = 0
            if self.Folder then
                for _, enemy in ipairs(self.Folder:GetChildren()) do
                    if enemy:GetAttribute("SpawnerId") == spawnerId then
                        alive += 1
                    end
                end
            end
            if alive < maxAlive then
                local interval = tonumber(instance:GetAttribute("SpawnInterval")) or 6
                local last = tonumber(instance:GetAttribute("LastSpawn")) or 0
                if os.clock() - last >= interval then
                    instance:SetAttribute("LastSpawn", os.clock())
                    local radius = tonumber(instance:GetAttribute("SpawnRadius")) or 4
                    local offset = Vector3.new((math.random() - 0.5) * radius * 2, 3, (math.random() - 0.5) * radius * 2)
                    local enemy = self:SpawnAtCFrame(instance:GetAttribute("EnemyId") or "Raider", instance.CFrame * CFrame.new(offset))
                    if enemy then enemy:SetAttribute("SpawnerId", spawnerId) end
                end
            end
        end
    end
end

function EnemyService:Update(dt)
    if not self.Folder then return end
    self.SpawnerAccumulator += dt
    if self.SpawnerAccumulator >= 1 then
        self.SpawnerAccumulator = 0
        self:UpdateSpawners()
    end
    if self.AIPaused then return end
    for _, model in ipairs(self.Folder:GetChildren()) do
        self.AI:Update(model, dt)
    end
end

return EnemyService
