--!nonstrict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local Melee = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Melee"))
local Enemies = require(Shared:WaitForChild("Data"):WaitForChild("Enemies"):WaitForChild("Enemies"))
local Missions = require(Shared:WaitForChild("Data"):WaitForChild("Missions"):WaitForChild("Missions"))
local Mods = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mods"))
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))

local TestUI = {}
TestUI.__index = TestUI

function TestUI.new(state, input, camera)
    return setmetatable({
        State = state,
        Input = input,
        Camera = camera,
        Gui = nil,
        Body = nil,
        Summary = nil,
        Connections = {},
        ProfileRequestRemote = nil,
        ProfileUpdateRemote = nil,
        AbilityRemote = nil,
        WeaponRemote = nil,
        EnemyRemote = nil,
        MissionRemote = nil,
        WorldRemote = nil,
        TuningRemote = nil,
        SelectedFrameId = "EmberVanguard",
        SelectedWeaponId = "Rifle",
        SelectedMeleeId = "Skana",
        SelectedEnemyId = "Raider",
        SelectedMeleeVariant = "Light",
        Collapsed = {},
        EnemyAIPaused = false,
    }, TestUI)
end

function TestUI:MakeButton(parent, text, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -8, 0, 28)
    button.BackgroundColor3 = Color3.fromRGB(38, 45, 55)
    button.BorderSizePixel = 0
    button.TextColor3 = Color3.fromRGB(240, 245, 250)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 12
    button.Text = text
    button.Parent = parent
    button.MouseButton1Click:Connect(callback)
    return button
end

function TestUI:AddTextLine(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 22)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(205, 214, 226)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Text = text
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = parent
    return label
end

function TestUI:Header(parent, text)
    local label = Instance.new("TextButton")
    label.Size = UDim2.new(1, -8, 0, 24)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(120, 195, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Text = (self.Collapsed[text] and "[+] " or "[-] ") .. text
    label.Parent = parent
    label.MouseButton1Click:Connect(function()
        self.Collapsed[text] = not self.Collapsed[text]
        self:Refresh()
    end)
    return label
end

function TestUI:IsOpen(sectionName)
    self:Header(self.Body, sectionName)
    return self.Collapsed[sectionName] ~= true
end

function TestUI:Start()
    self.ProfileRequestRemote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileRequest)
    self.ProfileUpdateRemote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileUpdate)
    self.AbilityRemote = Net.GetRemoteEvent(Net.RemoteEvents.AbilityRequest)
    self.WeaponRemote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self.EnemyRemote = Net.GetRemoteEvent(Net.RemoteEvents.EnemyRequest)
    self.MissionRemote = Net.GetRemoteEvent(Net.RemoteEvents.MissionRequest)
    self.WorldRemote = Net.GetRemoteEvent(Net.RemoteEvents.WorldRequest)
    self.TuningRemote = Net.GetRemoteEvent(Net.RemoteEvents.TuningRequest)
    self:BuildGui()

    table.insert(self.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.G then
            self.Gui.Enabled = not self.Gui.Enabled
            self:Refresh()
        end
    end))

    table.insert(self.Connections, self.ProfileUpdateRemote.OnClientEvent:Connect(function(payload)
        self.State:ApplyProfilePayload(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.RewardUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyReward(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.MissionUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyMission(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.WorldUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyWorld(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.WeaponUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyWeaponRuntime(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.AbilityUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyAbilityRuntime(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.ValidationUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyValidation(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.TuningUpdate).OnClientEvent:Connect(function(payload)
        self:ApplyTuningPayload(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.EnemyUpdate).OnClientEvent:Connect(function(payload)
        if typeof(payload) == "table" and payload.Type == "AIPaused" then
            self.EnemyAIPaused = payload.Paused == true
            self:Refresh()
        end
    end))

    self.ProfileRequestRemote:FireServer({ Action = "RequestSnapshot" })
    self.WorldRemote:FireServer({ Action = "RequestLocations" })
end

function TestUI:BuildGui()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "GameSystemsTestMenu"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = playerGui
    self.Gui = gui

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(620, 680)
    panel.Position = UDim2.fromOffset(610, 60)
    panel.BackgroundColor3 = Color3.fromRGB(16, 20, 26)
    panel.BorderSizePixel = 0
    panel.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -16, 0, 32)
    title.Position = UDim2.fromOffset(8, 6)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(248, 250, 252)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Text = "Game Systems Test Menu (G)"
    title.Parent = panel

    local summary = Instance.new("TextLabel")
    summary.Size = UDim2.new(1, -16, 0, 154)
    summary.Position = UDim2.fromOffset(8, 40)
    summary.BackgroundColor3 = Color3.fromRGB(10, 13, 18)
    summary.BorderSizePixel = 0
    summary.TextXAlignment = Enum.TextXAlignment.Left
    summary.TextYAlignment = Enum.TextYAlignment.Top
    summary.TextColor3 = Color3.fromRGB(220, 230, 238)
    summary.Font = Enum.Font.Code
    summary.TextSize = 12
    summary.TextWrapped = true
    summary.Parent = panel
    self.Summary = summary

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -16, 1, -204)
    scroll.Position = UDim2.fromOffset(8, 198)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 6
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.CanvasSize = UDim2.fromOffset(0, 0)
    scroll.Parent = panel
    self.Body = scroll

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = scroll

    self:Refresh()
end

function TestUI:ClearBody()
    for _, child in ipairs(self.Body:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

function TestUI:GetSelectedFrameState()
    local profile = self.State.Profile
    if not profile then return nil end
    return profile.Frames[profile.SelectedFrameId]
end

function TestUI:FormatMap(map, emptyText)
    local parts = {}
    for key, value in pairs(map or {}) do
        table.insert(parts, tostring(key) .. ":" .. tostring(math.floor(value)))
    end
    table.sort(parts)
    if #parts == 0 then return emptyText or "None" end
    return table.concat(parts, " ")
end

function TestUI:ApplyTuningPayload(payload)
    if typeof(payload) ~= "table" then return end
    local value = tonumber(payload.Value)
    if not value then return end
    if payload.TargetType == "FrameStat" then
        local frame = Frames.Get(payload.Id)
        if frame and frame.BaseStats then frame.BaseStats[payload.Key] = value end
    elseif payload.TargetType == "Weapon" then
        local weapon = Weapons.Get(payload.Id)
        if weapon then weapon[payload.Key] = value end
    elseif payload.TargetType == "Enemy" then
        local enemy = Enemies[payload.Id]
        if enemy then enemy[payload.Key] = value end
    elseif payload.TargetType == "MeleeAttack" then
        local attack = Melee.GetAttack(payload.Id, payload.Variant, tonumber(payload.ComboIndex) or 1)
        if attack then attack[payload.Key] = value end
    end
end

function TestUI:SendTuning(targetType, id, key, value, extra)
    local payload = extra or {}
    payload.TargetType = targetType
    payload.Id = id
    payload.Key = key
    payload.Value = tonumber(value)
    if not payload.Value then return end
    self:ApplyTuningPayload(payload)
    self.TuningRemote:FireServer(payload)
    self:Refresh()
end

function TestUI:AddNumberRow(parent, labelText, value, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -8, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -178, 1, 0)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(220, 228, 236)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Text = labelText
    label.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.fromOffset(82, 24)
    box.Position = UDim2.new(1, -134, 0, 3)
    box.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
    box.BorderSizePixel = 0
    box.TextColor3 = Color3.fromRGB(245, 248, 250)
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Text = tostring(math.floor((tonumber(value) or 0) * 100 + 0.5) / 100)
    box.Parent = row

    local apply = self:MakeButton(row, "Set", function()
        callback(box.Text)
    end)
    apply.Size = UDim2.fromOffset(44, 24)
    apply.Position = UDim2.new(1, -48, 0, 3)
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then callback(box.Text) end
    end)
end

function TestUI:AddSelectButtons(parent, title, options, selected, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -8, 0, 20)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(180, 210, 235)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.Text = title .. ": " .. tostring(selected)
    label.Parent = parent
    for _, id in ipairs(options) do
        self:MakeButton(parent, (id == selected and "* " or "") .. id, function()
            callback(id)
            self:Refresh()
        end)
    end
end

function TestUI:SortedKeys(map)
    local keys = {}
    for key in pairs(map) do table.insert(keys, key) end
    table.sort(keys)
    return keys
end

function TestUI:RefreshSummary()
    local profile = self.State.Profile
    local stats = self.State.Stats or {}
    local res = self.State.Resources or {}
    local frameState = self:GetSelectedFrameState() or {}
    local frameDef = profile and Frames.Get(profile.SelectedFrameId)
    local mission = self.State.Mission
    local matchmaking = self.State.Matchmaking
    local weaponId = profile and profile.Equipped.ActiveWeapon or "None"
    local weaponRuntime = self.State.WeaponRuntime[weaponId] or {}
    local weaponState = profile and profile.Weapons and profile.Weapons[weaponId] or {}
    local materials = profile and profile.Inventory and profile.Inventory.Materials or {}
    local cooldownCount = 0
    local now = os.clock()
    for _, runtime in pairs((self.State.AbilityRuntime and self.State.AbilityRuntime.Cooldowns) or {}) do
        if (runtime.CooldownEnds or 0) > now then cooldownCount += 1 end
    end
    self.Summary.Text = table.concat({
        string.format("Frame: %s L%s | %s", profile and profile.SelectedFrameId or "None", tostring(frameState.Level or 1), frameDef and frameDef.Role or "No role"),
        string.format("Mastery: %s XP %s | CE %s", tostring(profile and profile.MasteryRank or 0), tostring(profile and profile.MasteryXP or 0), self:FormatMap(frameState.CE, "None")),
        string.format("Health %.0f/%.0f | Shield %.0f/%.0f | Mana %.0f/%.0f", res.Health or 0, stats.Health or 0, res.Shield or 0, stats.Shield or 0, res.Mana or 0, stats.Mana or 0),
        string.format("Weapon: %s L%s XP %s Ammo %s/%s | Cooldowns: %d", weaponId, weaponState.Level or "-", weaponState.XP or "-", weaponRuntime.Ammo or "-", weaponRuntime.Magazine or "-", cooldownCount),
        string.format("Mission: %s %s/%s", mission and mission.DisplayName or "None", mission and mission.Progress or 0, mission and mission.Target or 0),
        string.format("Power: %s | Queue: %s %s", tostring(self.State.Power or 0), matchmaking and matchmaking.Status or "None", matchmaking and (matchmaking.NodeName or matchmaking.NodeId or "") or ""),
        string.format("Materials: %s", self:FormatMap(materials, "None")),
        string.format("Last reward: %s", self.State.LastReward and self.State.LastReward.Type or "None"),
        string.format("Last reject: %s", self.State.Validation and (tostring(self.State.Validation.System) .. "/" .. tostring(self.State.Validation.Reason) .. " x" .. tostring(self.State.Validation.Count or 1)) or "None"),
    }, "\n")
end

function TestUI:Refresh()
    if not self.Body then return end
    self:RefreshSummary()
    self:ClearBody()

    local profile = self.State.Profile
    if self:IsOpen("Runtime Tuning") then
        self:AddSelectButtons(self.Body, "Frame", self:SortedKeys(Frames.ById), self.SelectedFrameId, function(id) self.SelectedFrameId = id end)
        local frame = Frames.Get(self.SelectedFrameId)
        for _, key in ipairs({ "Health", "Shield", "Armor", "Mana", "ManaRegen", "ShieldRegen", "Speed" }) do
            self:AddNumberRow(self.Body, "Frame " .. key, frame and frame.BaseStats and frame.BaseStats[key], function(value)
                self:SendTuning("FrameStat", self.SelectedFrameId, key, value)
            end)
        end

        self:AddSelectButtons(self.Body, "Gun", self:SortedKeys(Weapons.ById), self.SelectedWeaponId, function(id) self.SelectedWeaponId = id end)
        local weapon = Weapons.Get(self.SelectedWeaponId)
        for _, key in ipairs({ "Damage", "FireRate", "Magazine", "ReloadTime", "Range", "Spread", "Pellets", "Radius" }) do
            if weapon and weapon[key] ~= nil then
                self:AddNumberRow(self.Body, "Gun " .. key, weapon[key], function(value)
                    self:SendTuning("Weapon", self.SelectedWeaponId, key, value)
                end)
            end
        end

        self:AddSelectButtons(self.Body, "Melee", self:SortedKeys(Melee.ById), self.SelectedMeleeId, function(id) self.SelectedMeleeId = id end)
        self:AddSelectButtons(self.Body, "Melee Attack", { "Light", "Forward", "Heavy", "Air", "Slide", "Slam" }, self.SelectedMeleeVariant, function(id) self.SelectedMeleeVariant = id end)
        local attack = Melee.GetAttack(self.SelectedMeleeId, self.SelectedMeleeVariant, 1)
        for _, key in ipairs({ "Damage", "Startup", "Active", "Recovery", "Range", "Width", "Radius", "Impulse" }) do
            if attack and attack[key] ~= nil then
                self:AddNumberRow(self.Body, "Melee " .. key, attack[key], function(value)
                    self:SendTuning("MeleeAttack", self.SelectedMeleeId, key, value, { Variant = self.SelectedMeleeVariant, ComboIndex = 1 })
                end)
            end
        end

        self:AddSelectButtons(self.Body, "Enemy", Enemies.ListIds and Enemies.ListIds() or self:SortedKeys(Enemies), self.SelectedEnemyId, function(id) self.SelectedEnemyId = id end)
        local enemy = Enemies[self.SelectedEnemyId]
        for _, key in ipairs({ "Health", "Shield", "Armor", "Damage", "Range", "AggroRange", "PreferredRange", "RetreatRange", "FireRate", "MoveSpeed" }) do
            if enemy and enemy[key] ~= nil then
                self:AddNumberRow(self.Body, "Enemy " .. key, enemy[key], function(value)
                    self:SendTuning("Enemy", self.SelectedEnemyId, key, value)
                end)
            end
        end
    end

    if self:IsOpen("Frames") then
        for frameId, frame in pairs(Frames.ById) do
            local unlocked = profile and profile.UnlockedFrames and profile.UnlockedFrames[frameId] == true
            if unlocked then
                self:MakeButton(self.Body, "Select " .. frame.DisplayName, function()
                    self.ProfileRequestRemote:FireServer({ Action = "SelectFrame", FrameId = frameId })
                end)
            else
                self:MakeButton(self.Body, "Unlock " .. frame.DisplayName, function()
                    self.ProfileRequestRemote:FireServer({ Action = "UnlockFrame", FrameId = frameId })
                end)
            end
        end
    end

    if self:IsOpen("Abilities") then
        local selectedFrame = profile and Frames.Get(profile.SelectedFrameId)
        if selectedFrame then
            for slot, slotData in pairs(selectedFrame.AbilitySlots) do
                for _, abilityId in ipairs(slotData.Variants) do
                    local ability = Abilities.Get(abilityId)
                    self:MakeButton(self.Body, string.format("Slot %d: %s", slot, ability and ability.Name or abilityId), function()
                        self.ProfileRequestRemote:FireServer({ Action = "SelectAbility", Slot = slot, AbilityId = abilityId })
                        local camera = workspace.CurrentCamera
                        self.AbilityRemote:FireServer({ Slot = slot, AbilityId = abilityId, Direction = camera and camera.CFrame.LookVector or Vector3.zAxis })
                    end)
                end
            end
        end
        local events = (self.State.AbilityRuntime and self.State.AbilityRuntime.Events) or {}
        if #events > 0 then
            self:AddTextLine(self.Body, "Recent Ability Events")
            for index = math.max(1, #events - 5), #events do
                local event = events[index]
                self:AddTextLine(self.Body, string.format("%s %s targets=%s tick=%s/%s", tostring(event.AbilityId), tostring(event.Type), tostring(event.TargetCount or "-"), tostring(event.Tick or "-"), tostring(event.Ticks or "-")))
            end
        end
    end

    if self:IsOpen("Weapons") then
        for weaponId, weapon in pairs(Weapons.ById) do
            if weapon.Kind == "Ranged" then
                self:MakeButton(self.Body, "Equip Active " .. weapon.Name, function()
                    self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Active", WeaponId = weaponId })
                end)
            elseif weapon.Kind == "Melee" then
                self:MakeButton(self.Body, "Equip Melee " .. weapon.Name, function()
                    self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Melee", WeaponId = weaponId })
                end)
            end
        end
        self:MakeButton(self.Body, "Fire Active Weapon", function()
            local camera = workspace.CurrentCamera
            self.WeaponRemote:FireServer({ Action = "Fire", Direction = camera and camera.CFrame.LookVector or Vector3.zAxis })
        end)
        self:MakeButton(self.Body, "Reload Active Weapon", function()
            self.WeaponRemote:FireServer({ Action = "Reload" })
        end)
    end

    if self:IsOpen("Enemies") then
        self:MakeButton(self.Body, self.EnemyAIPaused and "Resume Enemy AI" or "Pause Enemy AI", function()
            self.EnemyAIPaused = not self.EnemyAIPaused
            self.EnemyRemote:FireServer({ Action = "SetAIPaused", Paused = self.EnemyAIPaused })
            self:Refresh()
        end)
        local enemyIds = Enemies.ListIds and Enemies.ListIds() or self:SortedKeys(Enemies)
        for _, enemyId in ipairs(enemyIds) do
            self:MakeButton(self.Body, "Spawn " .. enemyId, function()
                self.EnemyRemote:FireServer({ Action = "Spawn", Role = enemyId })
            end)
        end
        self:MakeButton(self.Body, "Spawn Gunner Wave", function()
            self.EnemyRemote:FireServer({ Action = "Wave", Role = "Gunner", Count = 5 })
        end)
        self:MakeButton(self.Body, "Clear Enemies", function()
            self.EnemyRemote:FireServer({ Action = "Clear" })
        end)
    end

    if self:IsOpen("World Nodes") then
        self:MakeButton(self.Body, "Refresh World State", function()
            self.WorldRemote:FireServer({ Action = "RequestLocations" })
        end)
        self:MakeButton(self.Body, "Cancel Matchmaking", function()
            self.WorldRemote:FireServer({ Action = "CancelMatchmaking" })
        end)
        for locationId, location in pairs(Locations.ById) do
            for _, node in ipairs(location.Nodes or {}) do
                local label = string.format("%s / %s [%s P%s]", location.DisplayName or locationId, node.DisplayName or node.Id, node.NodeType or "Node", tostring(node.RecommendedPower or 0))
                self:MakeButton(self.Body, "Solo " .. label, function()
                    self.WorldRemote:FireServer({ Action = "StartSolo", LocationId = locationId, NodeId = node.Id })
                end)
                if node.Matchmaking ~= "Solo" and node.NodeType ~= "PublicEvent" then
                    self:MakeButton(self.Body, "Queue " .. label, function()
                        self.WorldRemote:FireServer({ Action = "QueueNode", LocationId = locationId, NodeId = node.Id })
                    end)
                end
                if node.NodeType == "PublicEvent" then
                    self:MakeButton(self.Body, "Start Public " .. label, function()
                        self.WorldRemote:FireServer({ Action = "ActivateNode", LocationId = locationId, NodeId = node.Id })
                    end)
                end
            end
        end
    end

    if self:IsOpen("Missions") then
        for missionId, mission in pairs(Missions) do
            self:MakeButton(self.Body, "Start " .. mission.DisplayName, function()
                self.MissionRemote:FireServer({ Action = "Start", MissionId = missionId })
            end)
        end
        self:MakeButton(self.Body, "Complete Active Mission", function()
            self.MissionRemote:FireServer({ Action = "Complete" })
        end)
    end

    if self:IsOpen("Progression") then
        self:MakeButton(self.Body, "Grant Selected Frame 500 XP", function()
            self.ProfileRequestRemote:FireServer({ Action = "GrantFrameXP", Amount = 500 })
        end)
        self:MakeButton(self.Body, "Grant Selected Frame 2500 XP", function()
            self.ProfileRequestRemote:FireServer({ Action = "GrantFrameXP", Amount = 2500 })
        end)
        self:MakeButton(self.Body, "Grant Active Weapon 500 XP", function()
            local profile = self.State.Profile
            self.ProfileRequestRemote:FireServer({ Action = "GrantWeaponXP", WeaponId = profile and profile.Equipped and profile.Equipped.ActiveWeapon, Amount = 500 })
        end)
        self:MakeButton(self.Body, "Grant Mastery 1000 XP", function()
            self.ProfileRequestRemote:FireServer({ Action = "GrantMasteryXP", Amount = 1000 })
        end)
        self:MakeButton(self.Body, "Set Frame Level 30", function()
            self.ProfileRequestRemote:FireServer({ Action = "SetFrameLevel", Level = 30 })
        end)
    end

    if self:IsOpen("Mods") then
        local mods = profile and profile.Inventory and profile.Inventory.Mods or {}
        local equipped = profile and profile.EquippedMods or {}
        for modId, mod in pairs(Mods.ById) do
            local owned = mods[modId]
            local rank = owned and owned.Rank or 0
            local isEquipped = false
            for _, equippedId in ipairs(equipped[mod.Slot] or {}) do
                if equippedId == modId then isEquipped = true end
            end
            self:MakeButton(self.Body, string.format("%s [%s] R%d/%d %s", mod.Name, mod.Slot, rank, mod.MaxRank, isEquipped and "equipped" or ""), function() end)
        end
    end

    if self:IsOpen("Validation") then
        self:MakeButton(self.Body, "Send Invalid Ability", function()
            self.AbilityRemote:FireServer({ Slot = 99, AbilityId = "NotReal" })
        end)
        self:MakeButton(self.Body, "Send Invalid Weapon", function()
            self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Primary", WeaponId = "NotReal" })
        end)
        self:MakeButton(self.Body, "Send Invalid Mission Complete", function()
            self.MissionRemote:FireServer({ Action = "Complete" })
        end)
    end
end

return TestUI
