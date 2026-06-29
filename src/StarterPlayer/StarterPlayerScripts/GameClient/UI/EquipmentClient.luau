--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Core"):WaitForChild("Net"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local Mods = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mods"))
local Armor = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Armor"))

local EquipmentClient = {}
EquipmentClient.__index = EquipmentClient

function EquipmentClient.new(state, input)
    return setmetatable({
        State = state,
        Input = input,
        Gui = nil,
        Body = nil,
        Detail = nil,
        ProfileRemote = nil,
        WeaponRemote = nil,
        Connections = {},
    }, EquipmentClient)
end

local function make(parent, className, props)
    local object = Instance.new(className)
    for k, v in pairs(props or {}) do
        object[k] = v
    end
    object.Parent = parent
    return object
end

function EquipmentClient:Start()
    self.ProfileRemote = Net.GetRemoteEvent(Net.RemoteEvents.ProfileRequest)
    self.WeaponRemote = Net.GetRemoteEvent(Net.RemoteEvents.WeaponRequest)
    self:Build()
    table.insert(self.Connections, Net.GetRemoteEvent(Net.RemoteEvents.ProfileUpdate).OnClientEvent:Connect(function(payload)
        self.State:ApplyProfilePayload(payload)
        self:Refresh()
    end))
    table.insert(self.Connections, RunService.RenderStepped:Connect(function()
        if self.Input and self.Input.ConsumePressed and self.Input:ConsumePressed("EquipmentToggle") then
            self:Toggle()
        end
    end))
    self.ProfileRemote:FireServer({ Action = "RequestSnapshot" })
end

function EquipmentClient:Toggle()
    if not self.Gui then return end
    self.Gui.Enabled = not self.Gui.Enabled
    if self.Gui.Enabled then self:Refresh() end
end

function EquipmentClient:Build()
    local gui = make(Players.LocalPlayer:WaitForChild("PlayerGui"), "ScreenGui", {
        Name = "EquipmentMenu",
        ResetOnSpawn = false,
        Enabled = false,
    })
    self.Gui = gui

    local panel = make(gui, "Frame", {
        Name = "Panel",
        Size = UDim2.fromOffset(820, 580),
        Position = UDim2.new(0.5, -410, 0.5, -290),
        BackgroundColor3 = Color3.fromRGB(12, 15, 20),
        BorderSizePixel = 0,
    })
    make(panel, "UICorner", { CornerRadius = UDim.new(0, 10) })

    make(panel, "TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -32, 0, 42),
        Position = UDim2.fromOffset(16, 8),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(245, 248, 255),
        Text = "Equipment",
    })
    make(panel, "TextLabel", {
        Name = "Hint",
        Size = UDim2.new(1, -32, 0, 24),
        Position = UDim2.fromOffset(16, 42),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(155, 170, 188),
        Text = "Press I to toggle. Hover cards for details. Buttons equip/select or debug-upgrade while systems are still being built.",
    })

    local body = make(panel, "ScrollingFrame", {
        Name = "Body",
        Size = UDim2.new(1, -280, 1, -82),
        Position = UDim2.fromOffset(16, 72),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 6,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    make(body, "UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    self.Body = body

    local detail = make(panel, "TextLabel", {
        Name = "Detail",
        Size = UDim2.fromOffset(240, 470),
        Position = UDim2.new(1, -256, 0, 72),
        BackgroundColor3 = Color3.fromRGB(17, 22, 30),
        BorderSizePixel = 0,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextColor3 = Color3.fromRGB(222, 232, 242),
        Text = "Hover something for details.",
    })
    make(detail, "UICorner", { CornerRadius = UDim.new(0, 8) })
    make(detail, "UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
    self.Detail = detail
end

function EquipmentClient:Clear()
    for _, child in ipairs(self.Body:GetChildren()) do
        if not child:IsA("UIListLayout") then child:Destroy() end
    end
end

function EquipmentClient:Section(title)
    make(self.Body, "TextLabel", {
        Size = UDim2.new(1, -8, 0, 24),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(120, 195, 255),
        Text = title,
    })
end

function EquipmentClient:Card(title, subtitle, detailText, actions)
    local card = make(self.Body, "Frame", {
        Size = UDim2.new(1, -8, 0, 64 + (#(actions or {}) > 0 and 34 or 0)),
        BackgroundColor3 = Color3.fromRGB(24, 29, 37),
        BorderSizePixel = 0,
    })
    make(card, "UICorner", { CornerRadius = UDim.new(0, 8) })
    make(card, "TextLabel", {
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.fromOffset(8, 6),
        BackgroundTransparency = 1,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(240, 244, 248),
        Text = title,
    })
    make(card, "TextLabel", {
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.fromOffset(8, 30),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = Color3.fromRGB(170, 184, 200),
        Text = subtitle or "",
    })
    card.MouseEnter:Connect(function()
        self.Detail.Text = detailText or title
    end)
    local x = 8
    for _, action in ipairs(actions or {}) do
        local button = make(card, "TextButton", {
            Size = UDim2.fromOffset(112, 26),
            Position = UDim2.fromOffset(x, 62),
            BackgroundColor3 = Color3.fromRGB(48, 68, 94),
            BorderSizePixel = 0,
            Font = Enum.Font.GothamMedium,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(245, 248, 255),
            Text = action.Text,
        })
        make(button, "UICorner", { CornerRadius = UDim.new(0, 6) })
        button.MouseButton1Click:Connect(action.Callback)
        x += 118
    end
end

function EquipmentClient:Refresh()
    if not self.Body then return end
    self:Clear()
    local profile = self.State.Profile
    if not profile then
        self:Section("Loading")
        return
    end

    local selectedFrameId = profile.SelectedFrameId
    local frameState = profile.Frames and profile.Frames[selectedFrameId] or {}
    local frame = Frames.Get(selectedFrameId)
    self:Section("Frame")
    self:Card(
        frame and frame.DisplayName or tostring(selectedFrameId),
        string.format("Level %s | Mastery %s | Mod capacity grows every level", tostring(frameState.Level or 1), tostring(profile.MasteryRank or 0)),
        string.format("Frame: %s\nRole: %s\nPassive: %s\nCE: %s", selectedFrameId, frame and frame.Role or "", frame and frame.Passive or "", game:GetService("HttpService"):JSONEncode(frameState.CE or {})),
        {
            { Text = "+500 XP", Callback = function() self.ProfileRemote:FireServer({ Action = "GrantFrameXP", Amount = 500 }) end },
            { Text = "Set L30", Callback = function() self.ProfileRemote:FireServer({ Action = "SetFrameLevel", Level = 30 }) end },
            { Text = "+Mastery", Callback = function() self.ProfileRemote:FireServer({ Action = "GrantMasteryXP", Amount = 1000 }) end },
        }
    )

    self:Section("Unlocked Frames")
    for frameId, unlocked in pairs(profile.UnlockedFrames or {}) do
        local def = Frames.Get(frameId)
        if unlocked and def then
            self:Card(def.DisplayName, def.Role, def.Passive, {
                { Text = frameId == selectedFrameId and "Selected" or "Select", Callback = function() self.ProfileRemote:FireServer({ Action = "SelectFrame", FrameId = frameId }) end },
            })
        end
    end

    self:Section("Weapons")
    local equipped = profile.Equipped or {}
    for weaponId, ownedState in pairs(profile.Weapons or {}) do
        local def = Weapons.Get(weaponId)
        if def then
            local isMelee = def.Kind == "Melee"
            local active = (not isMelee and equipped.ActiveWeapon == weaponId) or (isMelee and equipped.Melee == weaponId)
            local actions = {
                { Text = "+500 XP", Callback = function() self.ProfileRemote:FireServer({ Action = "GrantWeaponXP", WeaponId = weaponId, Amount = 500 }) end },
                { Text = "Set L30", Callback = function() self.ProfileRemote:FireServer({ Action = "SetWeaponLevel", WeaponId = weaponId, Level = 30 }) end },
            }
            if isMelee then
                table.insert(actions, 1, { Text = equipped.Melee == weaponId and "Melee Set" or "Equip Melee", Callback = function() self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Melee", WeaponId = weaponId }) end })
            else
                table.insert(actions, 1, { Text = equipped.Primary == weaponId and "Primary Set" or "Set Primary", Callback = function() self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Primary", WeaponId = weaponId }) end })
                table.insert(actions, 2, { Text = equipped.Secondary == weaponId and "Secondary Set" or "Set Secondary", Callback = function() self.WeaponRemote:FireServer({ Action = "Equip", Slot = "Secondary", WeaponId = weaponId }) end })
            end
            self:Card(
                string.format("%s%s", active and "* " or "", def.Name or weaponId),
                string.format("%s | Level %s | XP %s", def.Kind or "Weapon", tostring(ownedState.Level or 1), tostring(ownedState.XP or 0)),
                string.format("Id: %s\nKind: %s\nClass: %s\nDamage: %s\nFireRate: %s\nMagazine: %s\nElement: %s\nSimulation: %s\nMeleeDef: %s", weaponId, def.Kind or "", def.Class or "", tostring(def.Damage or "-"), tostring(def.FireRate or "-"), tostring(def.Magazine or "-"), tostring(def.Element or "-"), tostring(def.Simulation or "-"), tostring(def.MeleeDefinition or "-")),
                actions
            )
        end
    end


    self:Section("Armor")
    local equippedArmor = profile.EquippedArmor or {}
    for itemUid, item in pairs(profile.Inventory and profile.Inventory.Armor or {}) do
        local def = Armor.Get(item.ArmorId)
        if def then
            local equipped = equippedArmor[def.Slot] == itemUid
            local effective = Armor.ComputeEffectiveStats(item.ArmorId, item, frameState.Level or 1)
            local statLines = {}
            for stat, value in pairs(effective) do
                table.insert(statLines, string.format("%s: %.2f", stat, value))
            end
            table.sort(statLines)
            self:Card(
                string.format("%s%s", equipped and "* " or "", def.Name or item.ArmorId),
                string.format("%s | %s | Upgrade %s/%s", def.Slot or "Armor", item.Rarity or def.MinRarity or "Common", tostring(item.Upgrade or 0), tostring(def.UpgradeSteps or 0)),
                string.format("Item: %s\nArmorId: %s\nSlot: %s\nRarity Range: %s-%s\nEffective Stats at frame L%s:\n%s\nPerks: %s", itemUid, item.ArmorId, def.Slot or "", def.MinRarity or "", def.MaxRarity or "", tostring(frameState.Level or 1), table.concat(statLines, "\n"), table.concat(def.Perks or {}, " | ")),
                {
                    { Text = equipped and "Equipped" or "Equip", Callback = function() self.ProfileRemote:FireServer({ Action = "EquipArmor", ItemUid = itemUid }) end },
                    { Text = "Upgrade", Callback = function() self.ProfileRemote:FireServer({ Action = "UpgradeArmor", ItemUid = itemUid }) end },
                }
            )
        end
    end

    self:Section("Ability Variants")
    if frame then
        for slot, slotData in pairs(frame.AbilitySlots or {}) do
            for _, abilityId in ipairs(slotData.Variants or {}) do
                local ability = Abilities.Get(abilityId)
                local selected = frameState.SelectedVariants and frameState.SelectedVariants[slot] == abilityId
                self:Card(
                    string.format("Slot %d: %s%s", slot, selected and "* " or "", ability and ability.Name or abilityId),
                    string.format("Unlock L%s | %s | Cost %s | CD %s", tostring(slotData.UnlockLevel or 1), ability and ability.Element or "", tostring(ability and ability.ManaCost or "-"), tostring(ability and ability.Cooldown or "-")),
                    string.format("Id: %s\nBlock: %s\nDamage: %s\nRadius: %s\nStatus: %s", abilityId, ability and ability.Block or "", tostring(ability and ability.Damage or "-"), tostring(ability and ability.Radius or "-"), ability and game:GetService("HttpService"):JSONEncode(ability.Status or {}) or "{}"),
                    {
                        { Text = selected and "Selected" or "Select", Callback = function() self.ProfileRemote:FireServer({ Action = "SelectAbility", Slot = slot, AbilityId = abilityId }) end },
                    }
                )
            end
        end
    end

    self:Section("Mods")
    local equippedMods = profile.EquippedMods or {}
    for modId, owned in pairs(profile.Inventory and profile.Inventory.Mods or {}) do
        local mod = Mods.Get(modId)
        if mod then
            local group = mod.Slot or "Frame"
            local isEquipped = false
            for _, equippedModId in ipairs(equippedMods[group] or {}) do
                if equippedModId == modId then isEquipped = true break end
            end
            self:Card(
                string.format("%s%s", isEquipped and "* " or "", mod.Name),
                string.format("%s | Rank %s/%s", group, tostring(owned.Rank or 0), tostring(mod.MaxRank or 0)),
                string.format("Id: %s\nGroup: %s\nStat: %s\nPer Rank: %s\nEquipped: %s", modId, group, tostring(mod.Stat), tostring(mod.PerRank), tostring(isEquipped)),
                {
                    { Text = isEquipped and "Unequip" or "Equip", Callback = function() self.ProfileRemote:FireServer({ Action = isEquipped and "UnequipMod" or "EquipMod", Group = group, ModId = modId }) end },
                }
            )
        end
    end
end

return EquipmentClient
