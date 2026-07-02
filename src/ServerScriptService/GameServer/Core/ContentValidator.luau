--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Locations = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Locations"))
local HubServices = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("HubServices"))
local HubLayout = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("HubLayout"))
local Storylines = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Storylines"))
local Rooms = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Rooms"))
local Npcs = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Npcs"))
local Codex = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("Codex"))
local ResourceNodes = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("ResourceNodes"))
local TrainingRange = require(Shared:WaitForChild("Data"):WaitForChild("World"):WaitForChild("TrainingRange"))
local ClanConfig = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("ClanConfig"))
local TradeConfig = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("TradeConfig"))
local ChatChannels = require(Shared:WaitForChild("Data"):WaitForChild("Social"):WaitForChild("ChatChannels"))
local Missions = require(Shared:WaitForChild("Data"):WaitForChild("Missions"):WaitForChild("Missions"))
local Weapons = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Weapons"))
local WeaponVisuals = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("WeaponVisuals"))
local Abilities = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("Abilities"))
local AbilityHitboxes = require(Shared:WaitForChild("Data"):WaitForChild("Combat"):WaitForChild("AbilityHitboxes"))
local Frames = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Frames"))
local Mods = require(Shared:WaitForChild("Data"):WaitForChild("Progression"):WaitForChild("Mods"))
local Enemies = require(Shared:WaitForChild("Data"):WaitForChild("Enemies"):WaitForChild("Enemies"))
local Factions = require(Shared:WaitForChild("Data"):WaitForChild("Enemies"):WaitForChild("Factions"))

local NodeRules = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("World"):WaitForChild("NodeRules"))
local MissionNodes = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Missions"):WaitForChild("MissionNodes"))
local RewardTables = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Rewards"):WaitForChild("RewardTables"))
local EnemyDropTables = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Rewards"):WaitForChild("EnemyDropTables"))
local MarketplaceCatalog = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Economy"):WaitForChild("MarketplaceCatalog"))
local Recipes = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Crafting"):WaitForChild("Recipes"))
local Questlines = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Quests"):WaitForChild("Questlines"))
local NpcShops = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Npcs"):WaitForChild("NpcShops"))
local NpcBounties = require(ServerStorage:WaitForChild("ServerData"):WaitForChild("Npcs"):WaitForChild("NpcBounties"))

local ContentValidator = {}

local function addIssue(issues, systemName, id, message)
    table.insert(issues, {
        System = systemName,
        Id = id,
        Message = message,
    })
end

local function hasMaterialCost(costs)
    if typeof(costs) ~= "table" then return false end
    for _, amount in pairs(costs) do
        if tonumber(amount) and amount > 0 then return true end
    end
    return false
end

local function validateOutput(issues, systemName, id, outputType, outputId)
    if outputType == "Weapon" then
        if not Weapons.Get(outputId) then addIssue(issues, systemName, id, "unknown weapon output " .. tostring(outputId)) end
    elseif outputType == "Decoration" then
        if not Rooms.GetDecoration(outputId) then addIssue(issues, systemName, id, "unknown decoration output " .. tostring(outputId)) end
    elseif outputType == "RoomTemplate" then
        if not Rooms.GetTemplate(outputId) then addIssue(issues, systemName, id, "unknown room template output " .. tostring(outputId)) end
    elseif outputType == "Mod" then
        if not Mods.Get(outputId) then addIssue(issues, systemName, id, "unknown mod output " .. tostring(outputId)) end
    elseif outputType == "Material" or outputType == "Currency" or outputType == "Bundle" then
        if type(outputId) ~= "string" or outputId == "" then addIssue(issues, systemName, id, "material output needs OutputId") end
    else
        addIssue(issues, systemName, id, "unsupported output type " .. tostring(outputType))
    end
end

local function hasEnemyIdOrRole(enemyIdOrRole)
    if Enemies.Get(enemyIdOrRole) then return true end
    for _, def in pairs(Enemies) do
        if type(def) == "table" and def.Role == enemyIdOrRole then return true end
    end
    return false
end

function ContentValidator.ValidateLocations(issues)
    for locationId, location in pairs(Locations.ById) do
        if location.Id ~= locationId then addIssue(issues, "Location", locationId, "Id does not match table key") end
        if location.Unlock and location.Unlock.StoryStepId then
            local foundStep = false
            for storyId in pairs(Storylines.ById) do
                if Storylines.GetStep(storyId, location.Unlock.StoryStepId) then foundStep = true break end
            end
            if not foundStep then addIssue(issues, "Location", locationId, "unknown unlock StoryStepId " .. tostring(location.Unlock.StoryStepId)) end
        end
        for _, node in ipairs(location.Nodes or {}) do
            if not node.Id then
                addIssue(issues, "WorldNode", locationId, "node is missing Id")
            else
                local rule = MissionNodes.GetRule(node.Id) or NodeRules[node.Id]
                if not rule then addIssue(issues, "WorldNode", node.Id, "missing server MissionNodes/NodeRules entry") end
                if node.MissionId and not Missions[node.MissionId] then addIssue(issues, "WorldNode", node.Id, "unknown node MissionId " .. tostring(node.MissionId)) end
                if rule and rule.MissionId and not Missions[rule.MissionId] then addIssue(issues, "NodeRule", node.Id, "unknown rule MissionId " .. tostring(rule.MissionId)) end
                if rule and node.MissionId and rule.MissionId ~= node.MissionId then addIssue(issues, "NodeRule", node.Id, "rule MissionId differs from public node MissionId") end
            end
        end
    end
    for nodeId in pairs(NodeRules) do
        local found = false
        for locationId in pairs(Locations.ById) do
            if Locations.GetNode(locationId, nodeId) then found = true break end
        end
        if not found then addIssue(issues, "NodeRule", nodeId, "server rule has no public location node") end
    end
end

function ContentValidator.ValidateMissions(issues)
    for missionId, mission in pairs(Missions) do
        if mission.Id ~= missionId then addIssue(issues, "Mission", missionId, "Id does not match table key") end
        if not mission.Objective then addIssue(issues, "Mission", missionId, "missing Objective") end
        if not RewardTables.Mission[missionId] then addIssue(issues, "Mission", missionId, "missing mission reward table") end
        if mission.ActivityType ~= "Debug" and not MissionNodes.GetMission(missionId) then addIssue(issues, "Mission", missionId, "missing server MissionNodes config") end
        if mission.StoryStepId then
            local found = false
            for storyId in pairs(Storylines.ById) do
                local step = Storylines.GetStep(storyId, mission.StoryStepId)
                if step then found = true break end
            end
            if not found then addIssue(issues, "Mission", missionId, "unknown StoryStepId " .. tostring(mission.StoryStepId)) end
        end
    end
end

function ContentValidator.ValidateCombatProgression(issues)
    local validShapes = {}
    for _, shape in pairs(AbilityHitboxes.Shapes or {}) do
        validShapes[shape] = true
    end
    for abilityId, ability in pairs(Abilities.ById or {}) do
        if ability.Id ~= abilityId then addIssue(issues, "Ability", abilityId, "Id does not match table key") end
        if not tonumber(ability.Slot) or ability.Slot < 1 or ability.Slot > 4 then addIssue(issues, "Ability", abilityId, "invalid Slot") end
        if (ability.ManaCost or 0) < 0 then addIssue(issues, "Ability", abilityId, "ManaCost cannot be negative") end
        if (ability.Cooldown or 0) < 0 then addIssue(issues, "Ability", abilityId, "Cooldown cannot be negative") end
        local hitbox = ability.Hitbox
        if hitbox and not validShapes[hitbox.Shape] then
            addIssue(issues, "Ability", abilityId, "unknown hitbox shape " .. tostring(hitbox.Shape))
        end
        if hitbox and hitbox.Shape == "Field" then
            if (tonumber(hitbox.Ticks or ability.Ticks) or 0) < 1 then addIssue(issues, "Ability", abilityId, "field hitbox needs at least 1 tick") end
            if (tonumber(hitbox.Duration or ability.Duration) or 0) < 0 then addIssue(issues, "Ability", abilityId, "field duration cannot be negative") end
        end
        if hitbox and hitbox.MaxTargets and (tonumber(hitbox.MaxTargets) or 0) < 1 then
            addIssue(issues, "Ability", abilityId, "hitbox MaxTargets must be positive")
        end
    end
    for frameId, frame in pairs(Frames.ById or {}) do
        if frame.Id ~= frameId then addIssue(issues, "Frame", frameId, "Id does not match table key") end
        for slot, slotData in pairs(frame.AbilitySlots or {}) do
            if not tonumber(slot) or slot < 1 or slot > 4 then addIssue(issues, "Frame", frameId, "invalid ability slot " .. tostring(slot)) end
            for _, abilityId in ipairs(slotData.Variants or {}) do
                local ability = Abilities.Get(abilityId)
                if not ability then
                    addIssue(issues, "Frame", frameId, "unknown ability variant " .. tostring(abilityId))
                elseif ability.Slot ~= slot then
                    addIssue(issues, "Frame", frameId, "ability " .. tostring(abilityId) .. " is assigned to slot " .. tostring(slot) .. " but defines slot " .. tostring(ability.Slot))
                end
            end
        end
    end
    local validSimulations = { Hitscan = true, ProjectileRay = true, ArmedImpactRay = true, ImpactRay = true }
    local validFireModes = { Auto = true, Semi = true, Projectile = true, Beam = true }
    for weaponId, weapon in pairs(Weapons.ById or {}) do
        if weapon.Id ~= weaponId then addIssue(issues, "Weapon", weaponId, "Id does not match table key") end
        if weapon.Kind == "Ranged" then
            if not validFireModes[weapon.FireMode] then addIssue(issues, "Weapon", weaponId, "unknown FireMode " .. tostring(weapon.FireMode)) end
            if not validSimulations[weapon.Simulation] then addIssue(issues, "Weapon", weaponId, "unknown Simulation " .. tostring(weapon.Simulation)) end
            if (tonumber(weapon.Magazine) or 0) < 1 then addIssue(issues, "Weapon", weaponId, "ranged weapon needs positive Magazine") end
            if (tonumber(weapon.FireRate) or 0) <= 0 then addIssue(issues, "Weapon", weaponId, "ranged weapon needs positive FireRate") end
        elseif weapon.Kind ~= "Melee" then
            addIssue(issues, "Weapon", weaponId, "unknown Kind " .. tostring(weapon.Kind))
        end
        if weapon.Kind == "Ranged" and not WeaponVisuals.HasConfig(weaponId) then
            addIssue(issues, "WeaponVisual", weaponId, "missing visual config")
        end
    end
end

function ContentValidator.ValidateMissionNodes(issues)
    for nodeId, config in pairs(MissionNodes.ByNodeId) do
        if config.NodeId ~= nodeId then addIssue(issues, "MissionNode", nodeId, "NodeId does not match table key") end
        if not Missions[config.MissionId] then addIssue(issues, "MissionNode", nodeId, "unknown MissionId " .. tostring(config.MissionId)) end
        if not config.Rule then addIssue(issues, "MissionNode", nodeId, "missing Rule") end
        if not config.Mission then addIssue(issues, "MissionNode", nodeId, "missing Mission setup") end
        if not config.Reward then addIssue(issues, "MissionNode", nodeId, "missing Reward") end
        local setup = config.Mission or {}
        if (tonumber(setup.EnemyStartingLevel) or 0) < 1 then addIssue(issues, "MissionNode", nodeId, "EnemyStartingLevel must be positive") end
        if setup.BossId and not hasEnemyIdOrRole(setup.BossId) then addIssue(issues, "MissionNode", nodeId, "unknown BossId " .. tostring(setup.BossId)) end
        if setup.Drops and setup.Drops.EnemyDropTable and not EnemyDropTables[setup.Drops.EnemyDropTable] then
            addIssue(issues, "MissionNode", nodeId, "unknown EnemyDropTable " .. tostring(setup.Drops.EnemyDropTable))
        end
        for _, entry in ipairs(setup.EnemyTable or {}) do
            if type(entry.EnemyId) ~= "string" or entry.EnemyId == "" then addIssue(issues, "MissionNode", nodeId, "enemy table entry missing EnemyId") end
            if entry.EnemyId and not hasEnemyIdOrRole(entry.EnemyId) then addIssue(issues, "MissionNode", nodeId, "unknown enemy id/role " .. tostring(entry.EnemyId)) end
            if (tonumber(entry.Weight) or 0) <= 0 then addIssue(issues, "MissionNode", nodeId, "enemy table entry needs positive Weight") end
        end
    end
    for missionId in pairs(MissionNodes.ByMissionId) do
        if not Missions[missionId] then addIssue(issues, "MissionNode", missionId, "server config has no shared mission summary") end
    end
    for tableId, entries in pairs(EnemyDropTables) do
        for _, entry in ipairs(entries) do
            if type(entry.Type) ~= "string" then addIssue(issues, "EnemyDropTable", tableId, "drop entry missing Type") end
            if type(entry.Id) ~= "string" then addIssue(issues, "EnemyDropTable", tableId, "drop entry missing Id") end
            if (tonumber(entry.Chance) or -1) < 0 or (tonumber(entry.Chance) or 2) > 1 then addIssue(issues, "EnemyDropTable", tableId, "Chance must be 0..1") end
        end
    end
end

function ContentValidator.ValidateFactionsAndCodex(issues)
    for factionId, faction in pairs(Factions) do
        if faction.Id ~= factionId then addIssue(issues, "Faction", factionId, "Id does not match table key") end
        for _, enemyId in ipairs(faction.EnemyIds or {}) do
            if not Enemies.Get(enemyId) then addIssue(issues, "Faction", factionId, "unknown EnemyId " .. tostring(enemyId)) end
        end
    end
    for enemyId, enemy in pairs(Enemies) do
        if type(enemy) == "table" and enemy.Faction and not Factions[enemy.Faction] then
            addIssue(issues, "Enemy", enemyId, "unknown Faction " .. tostring(enemy.Faction))
        end
    end
    for locationId, location in pairs(Locations.ById) do
        for _, factionId in ipairs(location.Factions or {}) do
            if not Factions[factionId] then addIssue(issues, "Location", locationId, "unknown Faction " .. tostring(factionId)) end
        end
    end
    for entryId, entry in pairs(Codex.Entries) do
        if entry.Id ~= entryId then addIssue(issues, "Codex", entryId, "Id does not match table key") end
        if not Codex.Categories[entry.Category] then addIssue(issues, "Codex", entryId, "unknown Category " .. tostring(entry.Category)) end
    end
end

function ContentValidator.ValidateHubLayout(issues)
    if type(HubLayout.RootFolderName) ~= "string" or HubLayout.RootFolderName == "" then
        addIssue(issues, "HubLayout", "RootFolderName", "must be a non-empty string")
    end
    if type(HubLayout.InteractTag) ~= "string" or HubLayout.InteractTag == "" then
        addIssue(issues, "HubLayout", "InteractTag", "must be a non-empty string")
    end
    if not HubLayout.Attributes or type(HubLayout.Attributes.ServiceId) ~= "string" then
        addIssue(issues, "HubLayout", "Attributes", "ServiceId attribute name is required")
    end
    for _, serviceId in ipairs(HubServices.Order or {}) do
        if not HubLayout.GetStationSpec(serviceId) then
            addIssue(issues, "HubLayout", serviceId, "missing station spec for hub service")
        end
    end
end

function ContentValidator.ValidateStorylines(issues)
    for storyId, story in pairs(Storylines.ById) do
        if story.Id ~= storyId then addIssue(issues, "Story", storyId, "Id does not match table key") end
        local seenSteps = {}
        for _, step in ipairs(story.Steps or {}) do
            if not step.Id then
                addIssue(issues, "Story", storyId, "step is missing Id")
            elseif seenSteps[step.Id] then
                addIssue(issues, "Story", step.Id, "duplicate step Id in " .. tostring(storyId))
            else
                seenSteps[step.Id] = true
            end
            if step.MissionId and not Missions[step.MissionId] then addIssue(issues, "Story", step.Id or storyId, "unknown MissionId " .. tostring(step.MissionId)) end
            if step.NodeId then
                local found = false
                for locationId in pairs(Locations.ById) do
                    if Locations.GetNode(locationId, step.NodeId) then found = true break end
                end
                if not found then addIssue(issues, "Story", step.Id or storyId, "unknown NodeId " .. tostring(step.NodeId)) end
            end
            if step.Kind == "TalkToNpc" and not Npcs.Get(step.NpcId) then addIssue(issues, "Story", step.Id or storyId, "unknown NPC " .. tostring(step.NpcId)) end
        end
    end
end

function ContentValidator.ValidateRecipes(issues)
    for recipeId, recipe in pairs(Recipes) do
        if recipe.Id ~= recipeId then addIssue(issues, "Recipe", recipeId, "Id does not match table key") end
        if not hasMaterialCost(recipe.Costs) then addIssue(issues, "Recipe", recipeId, "recipe has no positive material cost") end
        validateOutput(issues, "Recipe", recipeId, recipe.OutputType, recipe.OutputId)
    end
end

function ContentValidator.ValidateMarketplace(issues)
    for listingId, listing in pairs(MarketplaceCatalog.Catalog) do
        if listing.Id ~= listingId then addIssue(issues, "Marketplace", listingId, "Id does not match table key") end
        if typeof(listing.Cost) ~= "table" then
            addIssue(issues, "Marketplace", listingId, "listing has no currency cost")
        else
            for currencyId, amount in pairs(listing.Cost) do
                if not MarketplaceCatalog.Currencies[currencyId] then addIssue(issues, "Marketplace", listingId, "unknown currency " .. tostring(currencyId)) end
                if not tonumber(amount) or amount < 0 then addIssue(issues, "Marketplace", listingId, "invalid currency amount for " .. tostring(currencyId)) end
            end
        end
        validateOutput(issues, "Marketplace", listingId, listing.OutputType, listing.OutputId)
    end
    for _, listingId in ipairs(MarketplaceCatalog.FeaturedOrder or {}) do
        if not MarketplaceCatalog.Catalog[listingId] then addIssue(issues, "Marketplace", listingId, "featured listing does not exist") end
    end
end

function ContentValidator.ValidateNpcs(issues)
    for npcId, npc in pairs(Npcs.ById) do
        if npc.Id ~= npcId then addIssue(issues, "Npc", npcId, "Id does not match table key") end
        for _, action in ipairs(npc.Actions or {}) do
            if action.Kind == "HubPanel" and not HubServices.Get(action.ServiceId) then
                addIssue(issues, "Npc", npcId, "action references unknown hub service " .. tostring(action.ServiceId))
            elseif action.Kind ~= "HubPanel" and action.Kind ~= "EnterRoom" and action.Kind ~= "EnterTraining" and action.Kind ~= "StartNextStory" and action.Kind ~= "OpenShop" and action.Kind ~= "OpenBounties" then
                addIssue(issues, "Npc", npcId, "unsupported action kind " .. tostring(action.Kind))
            end
        end
    end
    for _, npcId in ipairs(Npcs.DevOrder or {}) do
        if not Npcs.Get(npcId) then addIssue(issues, "Npc", npcId, "DevOrder references missing NPC") end
    end
end

function ContentValidator.ValidateQuestsAndNpcs(issues)
    local supportedQuestSteps = {
        TalkToNpc = true,
        CompleteNode = true,
        CraftOrOwn = true,
        OwnItem = true,
        GatherResource = true,
        DefeatEnemy = true,
        VisitLocation = true,
        UnlockGate = true,
        CompleteBounty = true,
    }
    local supportedBountyObjectives = {
        CompleteNode = true,
        DefeatEnemy = true,
        GatherResource = true,
        VisitLocation = true,
        UnlockGate = true,
    }
    for questId, quest in pairs(Questlines.ById) do
        if quest.Id ~= questId then addIssue(issues, "Quest", questId, "Id does not match table key") end
        for _, step in ipairs(quest.Steps or {}) do
            if not supportedQuestSteps[step.Type] then addIssue(issues, "Quest", questId, "unsupported step type " .. tostring(step.Type)) end
            if step.Type == "TalkToNpc" and not Npcs.Get(step.NpcId) then addIssue(issues, "Quest", questId, "unknown NPC " .. tostring(step.NpcId)) end
            if step.Type == "CompleteNode" and not MissionNodes.GetNode(step.NodeId) then addIssue(issues, "Quest", questId, "unknown node " .. tostring(step.NodeId)) end
            if step.Type == "VisitLocation" and not Locations.Get(step.LocationId) then addIssue(issues, "Quest", questId, "unknown location " .. tostring(step.LocationId)) end
            if (step.Type == "CraftOrOwn" or step.Type == "OwnItem") and not step.OutputType and not step.ItemType then addIssue(issues, "Quest", questId, "own/craft step needs OutputType or ItemType") end
            if step.Type == "GatherResource" and not step.MaterialId then addIssue(issues, "Quest", questId, "gather step should declare MaterialId") end
            if step.Type == "UnlockGate" and (type(step.GateId) ~= "string" or step.GateId == "") then addIssue(issues, "Quest", questId, "unlock gate step needs GateId") end
        end
    end
    for npcId, shop in pairs(NpcShops.ByNpcId) do
        if not Npcs.Get(npcId) then addIssue(issues, "NpcShop", npcId, "shop references unknown NPC") end
        for listingId, listing in pairs(shop.Listings or {}) do
            validateOutput(issues, "NpcShop", listingId, listing.OutputType, listing.OutputId)
        end
    end
    for npcId, board in pairs(NpcBounties.ByNpcId) do
        if not Npcs.Get(npcId) then addIssue(issues, "NpcBounty", npcId, "bounties reference unknown NPC") end
        for bountyId, bounty in pairs(board.Bounties or {}) do
            local objective = bounty.Objective or {}
            if not supportedBountyObjectives[objective.Type] then
                addIssue(issues, "NpcBounty", bountyId, "unsupported objective type " .. tostring(objective.Type))
            end
            if objective.Type == "CompleteNode" and not MissionNodes.GetNode(objective.NodeId) then addIssue(issues, "NpcBounty", bountyId, "unknown node " .. tostring(objective.NodeId)) end
            if objective.Type == "VisitLocation" and objective.LocationId and not Locations.Get(objective.LocationId) then addIssue(issues, "NpcBounty", bountyId, "unknown location " .. tostring(objective.LocationId)) end
            if objective.Type == "GatherResource" and not objective.MaterialId then addIssue(issues, "NpcBounty", bountyId, "gather objective should declare MaterialId") end
            if objective.Type == "GatherResource" and objective.LocationId and not Locations.Get(objective.LocationId) then addIssue(issues, "NpcBounty", bountyId, "unknown location " .. tostring(objective.LocationId)) end
            if objective.Type == "DefeatEnemy" and objective.EnemyId and not Enemies.Get(objective.EnemyId) then addIssue(issues, "NpcBounty", bountyId, "unknown enemy " .. tostring(objective.EnemyId)) end
            if objective.Type == "DefeatEnemy" and objective.EnemyRole and not hasEnemyIdOrRole(objective.EnemyRole) then addIssue(issues, "NpcBounty", bountyId, "unknown enemy role " .. tostring(objective.EnemyRole)) end
            if objective.Type == "DefeatEnemy" and objective.Faction and not Factions[objective.Faction] then addIssue(issues, "NpcBounty", bountyId, "unknown faction " .. tostring(objective.Faction)) end
            if objective.Type == "UnlockGate" and (type(objective.GateId) ~= "string" or objective.GateId == "") then addIssue(issues, "NpcBounty", bountyId, "unlock gate objective needs GateId") end
        end
    end
end

function ContentValidator.ValidateRooms(issues)
    for templateId, template in pairs(Rooms.Templates) do
        if template.Id ~= templateId then addIssue(issues, "RoomTemplate", templateId, "Id does not match table key") end
        if not template.Bounds or typeof(template.Bounds) ~= "Vector3" then addIssue(issues, "RoomTemplate", templateId, "template needs Vector3 Bounds") end
        local unlock = template.Unlock or {}
        if unlock.Type == "Mastery" and (tonumber(unlock.Rank) or -1) < 0 then
            addIssue(issues, "RoomTemplate", templateId, "Mastery unlock needs non-negative Rank")
        end
        if unlock.Type ~= nil and unlock.Type ~= "Default" and unlock.Type ~= "Mastery" then
            addIssue(issues, "RoomTemplate", templateId, "unknown Unlock.Type " .. tostring(unlock.Type))
        end
        if template.Costs and not hasMaterialCost(template.Costs) and unlock.Type ~= "Default" then
            addIssue(issues, "RoomTemplate", templateId, "non-default room template has no positive material cost")
        end
    end
    for decorationId, decoration in pairs(Rooms.Decorations) do
        if decoration.Id ~= decorationId then addIssue(issues, "Decoration", decorationId, "Id does not match table key") end
        if not decoration.Size or typeof(decoration.Size) ~= "Vector3" then addIssue(issues, "Decoration", decorationId, "decoration needs Vector3 Size") end
    end
end

function ContentValidator.ValidateResourceNodes(issues)
    for resourceId, def in pairs(ResourceNodes.ById) do
        if def.Id ~= resourceId then addIssue(issues, "ResourceNode", resourceId, "Id does not match table key") end
        if type(def.MaterialId) ~= "string" or def.MaterialId == "" then addIssue(issues, "ResourceNode", resourceId, "missing MaterialId") end
        if (tonumber(def.AmountMin) or 0) < 1 then addIssue(issues, "ResourceNode", resourceId, "AmountMin must be positive") end
        if (tonumber(def.AmountMax) or 0) < (tonumber(def.AmountMin) or 0) then addIssue(issues, "ResourceNode", resourceId, "AmountMax must be >= AmountMin") end
        for locationId in pairs(def.Locations or {}) do
            if not Locations.Get(locationId) then addIssue(issues, "ResourceNode", resourceId, "unknown location " .. tostring(locationId)) end
        end
    end
    for locationId, resourceIds in pairs(ResourceNodes.DevByLocation or {}) do
        if not Locations.Get(locationId) then addIssue(issues, "ResourceNode", locationId, "DevByLocation references unknown location") end
        for _, resourceId in ipairs(resourceIds) do
            if not ResourceNodes.Get(resourceId) then
                addIssue(issues, "ResourceNode", locationId, "DevByLocation references missing resource " .. tostring(resourceId))
            elseif not ResourceNodes.CanSpawnInLocation(resourceId, locationId) then
                addIssue(issues, "ResourceNode", resourceId, "DevByLocation uses resource in unsupported location " .. tostring(locationId))
            end
        end
    end
end

function ContentValidator.ValidateTrainingRange(issues)
    for targetId, def in pairs(TrainingRange.Targets) do
        if def.Id ~= targetId then addIssue(issues, "TrainingTarget", targetId, "Id does not match table key") end
        if (tonumber(def.Health) or 0) < 1 then addIssue(issues, "TrainingTarget", targetId, "Health must be positive") end
        if (tonumber(def.Shield) or 0) < 0 then addIssue(issues, "TrainingTarget", targetId, "Shield cannot be negative") end
        if (tonumber(def.Armor) or 0) < 0 then addIssue(issues, "TrainingTarget", targetId, "Armor cannot be negative") end
        if def.Size and typeof(def.Size) ~= "Vector3" then addIssue(issues, "TrainingTarget", targetId, "Size must be Vector3") end
        if def.Position and typeof(def.Position) ~= "Vector3" then addIssue(issues, "TrainingTarget", targetId, "Position must be Vector3") end
    end
    for _, targetId in ipairs(TrainingRange.Order or {}) do
        if not TrainingRange.Get(targetId) then addIssue(issues, "TrainingTarget", targetId, "Order references missing target") end
    end
end

function ContentValidator.ValidateSocial(issues)
    if not ClanConfig.Ranks.Founder or not ClanConfig.Ranks.Member then
        addIssue(issues, "Clan", "Ranks", "clan ranks need at least Founder and Member")
    end
    if (ClanConfig.MaxMembers or 0) < 1 then
        addIssue(issues, "Clan", "MaxMembers", "MaxMembers must be positive")
    end
    for _, itemType in ipairs({ "Material", "Decoration", "Mod", "Armor", "Attachment", "Dallions" }) do
        if not TradeConfig.AllowedItemTypes[itemType] then
            addIssue(issues, "Trade", "AllowedItemTypes", "trade scaffold expects " .. itemType .. " support")
        end
    end
    if not TradeConfig.AllowedPriceCurrencies.Coins or not TradeConfig.AllowedPriceCurrencies.Dallions then
        addIssue(issues, "Trade", "AllowedPriceCurrencies", "trade scaffold expects Coins and Dallions pricing")
    end
    if (TradeConfig.MaxListingsPerPlayer or 0) < 1 then
        addIssue(issues, "Trade", "MaxListingsPerPlayer", "MaxListingsPerPlayer must be positive")
    end
    local aliases = {}
    local validScopes = { Server = true, Location = true, Party = true, Clan = true, Room = true, Direct = true, System = true }
    for channelId, channel in pairs(ChatChannels.ById) do
        if channel.Id ~= channelId then addIssue(issues, "ChatChannel", channelId, "Id does not match table key") end
        if not validScopes[channel.Scope] then addIssue(issues, "ChatChannel", channelId, "unknown Scope " .. tostring(channel.Scope)) end
        if channel.Alias then
            local alias = string.lower(channel.Alias)
            if aliases[alias] then
                addIssue(issues, "ChatChannel", channelId, "duplicate Alias " .. tostring(channel.Alias))
            end
            aliases[alias] = true
        end
    end
    for _, channelId in ipairs(ChatChannels.Order or {}) do
        if not ChatChannels.Get(channelId) then
            addIssue(issues, "ChatChannel", channelId, "Order references missing channel")
        end
    end
end

function ContentValidator.Run()
    local issues = {}
    ContentValidator.ValidateLocations(issues)
    ContentValidator.ValidateMissions(issues)
    ContentValidator.ValidateCombatProgression(issues)
    ContentValidator.ValidateMissionNodes(issues)
    ContentValidator.ValidateHubLayout(issues)
    ContentValidator.ValidateFactionsAndCodex(issues)
    ContentValidator.ValidateStorylines(issues)
    ContentValidator.ValidateRecipes(issues)
    ContentValidator.ValidateMarketplace(issues)
    ContentValidator.ValidateQuestsAndNpcs(issues)
    ContentValidator.ValidateNpcs(issues)
    ContentValidator.ValidateRooms(issues)
    ContentValidator.ValidateResourceNodes(issues)
    ContentValidator.ValidateTrainingRange(issues)
    ContentValidator.ValidateSocial(issues)
    return issues
end

function ContentValidator.WarnIssues(issues)
    if #issues == 0 then
        print("[ContentValidator] content cross-reference check passed")
        return
    end
    warn(string.format("[ContentValidator] found %d content issue(s)", #issues))
    for _, issue in ipairs(issues) do
        warn(string.format("[ContentValidator][%s:%s] %s", tostring(issue.System), tostring(issue.Id), tostring(issue.Message)))
    end
end

return ContentValidator
