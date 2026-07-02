# Content Authoring

Use this when adding gameplay content. The rule of thumb is simple: public display data goes in `ReplicatedStorage`, authority/cost/drop/spawn data goes in `ServerStorage`.

## Jump To

[Missions](#missions) |
[Abilities And Hitboxes](#abilities-and-hitboxes) |
[Weapons And Visuals](#weapons-and-visuals) |
[Locations And Nodes](#locations-and-nodes) |
[Mission Rewards And Drops](#mission-rewards-and-drops) |
[Enemies And Factions](#enemies-and-factions) |
[Crafting](#crafting) |
[Item Tags And Trading](#item-tags-and-trading) |
[Marketplace](#marketplace) |
[NPC Shops And Bounties](#npc-shops-and-bounties) |
[Quests And Story](#quests-and-story) |
[Rooms](#rooms) |
[Hub Interactions](#hub-interactions) |
[Resources](#resources) |
[Training](#training) |
[Codex](#codex) |
[Validation](#validation)

## Main Data Files

| Content | File/Folder |
| --- | --- |
| Locations and public nodes | `src/ReplicatedStorage/Shared/Data/World/Locations.luau` |
| Public mission summaries | `src/ReplicatedStorage/Shared/Data/Missions/Missions.luau` |
| Server mission node configs | `src/ServerStorage/ServerData/Missions/MissionNodes/<Planet>/<NodeId>.luau` |
| Ability definitions | `src/ReplicatedStorage/Shared/Data/Combat/Abilities.luau` |
| Ability hitbox presets | `src/ReplicatedStorage/Shared/Data/Combat/AbilityHitboxes.luau` |
| Frame/Vestige ability slots | `src/ReplicatedStorage/Shared/Data/Progression/Frames.luau` |
| Weapon definitions | `src/ReplicatedStorage/Shared/Data/Combat/Weapons.luau` |
| Weapon visual configs | `src/ReplicatedStorage/Shared/Data/Combat/WeaponVisuals.luau` |
| Enemy drop tables | `src/ServerStorage/ServerData/Rewards/EnemyDropTables.luau` |
| Mission reward fallback | `src/ServerStorage/ServerData/Rewards/RewardTables.luau` |
| Enemy public data | `src/ReplicatedStorage/Shared/Data/Enemies/Enemies.luau` |
| Enemy server stats | `src/ServerStorage/ServerData/Enemies/EnemyStats.luau` |
| Factions | `src/ReplicatedStorage/Shared/Data/Enemies/Factions.luau` |
| Crafting recipes | `src/ServerStorage/ServerData/Crafting/RecipeBook/<Category>.luau` |
| Marketplace listings | `src/ServerStorage/ServerData/Economy/MarketplaceCatalog/<Category>.luau` |
| Item type tags/trade rules | `src/ReplicatedStorage/Shared/Data/Economy/ItemTags.luau` |
| NPC definitions | `src/ReplicatedStorage/Shared/Data/World/Npcs.luau` |
| NPC shops | `src/ServerStorage/ServerData/Npcs/NpcShops` |
| NPC bounties | `src/ServerStorage/ServerData/Npcs/NpcBounties` |
| Quest chains | `src/ServerStorage/ServerData/Quests/Questlines` |
| Story arcs | `src/ReplicatedStorage/Shared/Data/World/Storylines.luau` |
| Rooms/decorations | `src/ReplicatedStorage/Shared/Data/World/Rooms.luau` |
| Resource nodes | `src/ReplicatedStorage/Shared/Data/World/ResourceNodes.luau` |
| Training targets | `src/ReplicatedStorage/Shared/Data/World/TrainingRange.luau` |
| Codex entries | `src/ReplicatedStorage/Shared/Data/World/Codex.luau` |

## Missions

Missions are individual activities. A mission can be a story instance, exterminate, survival, defense, public event, boss, salvage, training room, or future objective type.

To add a mission:

1. Add a public mission summary in `Missions.luau`.
2. Add a public node under a location in `Locations.luau`.
3. Add a server node config in `ServerStorage/ServerData/Missions/MissionNodes/<Planet>/<NodeId>.luau`.
4. Register that file in `MissionNodes/init.luau`.
5. Add an enemy drop table if needed.
6. Run Rojo validation and check ContentValidator warnings in Studio.

Keep heavy per-node data in the server node file, not in `Missions.luau`.

Mission runtime now flows through `ServerScriptService/GameServer/Missions/MissionObjectiveRuntime.luau`.

Supported runtime objective families:

- `Kill` / `Exterminate`: count enemy kills until target.
- `Boss` / `Assassination`: spawn and count the configured boss.
- `Wave` / `Defense` / `PublicEvent`: spawn a wave and count kills toward the target.
- `Timer` / `Survival` / `Salvage`: progress by elapsed mission time, with extraction-ready state available for later.

Node configs can tune `TargetCount`, `Duration`, `SpawnCount`, `WaveSize`, `MaxWaves`, `BossId`, `EnemyTable`, `EnemyStartingLevel`, `Drops`, and `Setup`.

## Abilities And Hitboxes

Abilities are shared data so the client can display names, slots, cooldowns, and selected variants. The server still owns actual hit resolution.

To add an ability:

1. Add or reuse a hitbox preset in `AbilityHitboxes.luau`.
2. Add the ability in `Abilities.luau`.
3. Assign it to a frame slot in `Frames.luau`.
4. Add animation marker and VFX/SFX ids when real assets exist.
5. Run Rojo validation and check ContentValidator warnings in Studio.

Current hitbox families:

- `Projectile`
- `Raycast`
- `Sphere`
- `Box`
- `Cone`
- `Capsule`
- `Beam`
- `Field`
- `WhipTrace`

The temporary resolver applies most casts immediately. `Field` abilities now anchor at the cast position and tick server-side using `Duration` plus `Ticks`, so support zones and hazards can linger while still using authoritative hit checks. Production abilities should move spawn/damage timing to animation markers such as `AbilityRelease`, `MeleeActive`, and `MeleeRecover`.

`AbilityService` emits lifecycle payloads on `AbilityUpdate` for temporary UI and future VFX/SFX clients:

- `Cooldown`: private cooldown update for the casting player.
- `Cast`: replicated cast start with ability id, block, element, animation, markers, VFX/SFX metadata, cast position, and direction.
- `Impact`: replicated immediate result with target count.
- `FieldTick`: replicated each field pulse with tick index, total ticks, radius, duration, and target count.
- `FieldExpire`: replicated when a field finishes.

`StarterPlayerScripts/GameClient/Combat/AbilityFeedbackClient.luau` consumes those events and renders placeholder client VFX. Replace that module's neon burst/line/field previews with real particles, beams, sounds, and animation-bound effects when assets are ready.

## Weapons And Visuals

Weapon behavior lives in `Weapons.luau`; visual attachment data lives in `WeaponVisuals.luau`.

Supported ranged fire modes:

- `Auto`: fires while held.
- `Beam`: fires while held.
- `Semi`: fires once per press.
- `Projectile`: fires once per press.

Supported server simulations:

- `Hitscan`
- `ProjectileRay`
- `ArmedImpactRay`
- `ImpactRay`

Every ranged weapon should have a visual config. If the configured model is missing in Studio, `WeaponService` generates a simple rifle-shaped fallback model so equip/switch testing still works.

Weapon fire replicates temporary combat feedback:

- `Shot`: includes `WeaponId`, `FireMode`, `Simulation`, `Element`, `Origin`, `HitPosition`, optional `BeamWidth`, and optional `ProjectileColor`.
- `Explosion`: emitted by radius impact/projectile simulations and includes `WeaponId`, `Element`, `Position`, and `Radius`.

`CombatFeedbackClient` uses those fields for placeholder tracers, beam width, element colors, and explosion previews. Replace those previews with real muzzle flashes, projectiles, beam objects, impact particles, and audio later.

Temporary UI can equip any owned ranged weapon into the active ranged slot and any owned melee weapon into the melee slot. Final UI should expose primary/secondary/melee loadout slots separately.

## Locations And Nodes

Locations are public world destinations such as Moon, Earth, Atlas Shard, and Mars.

Node fields commonly include:

- `Id`
- `DisplayName`
- `MissionId`
- `NodeType`
- `RecommendedPower`
- `Matchmaking`
- `Visibility`

Visibility can hide future content from the mission board until story/location requirements are met.

Server node configs own:

- Access mode.
- Instance mode.
- Min/recommended power.
- Unlock rules.
- Enemy table.
- Enemy starting level.
- Drop table id.
- Mission setup hints.
- Rewards.

## Mission Rewards And Drops

Mission rewards should live in the node config when possible. `RewardTables.luau` is still present as a fallback.

Enemy drops live in `EnemyDropTables.luau` and are referenced by:

```lua
Drops = {
    EnemyDropTable = "EarthLow",
}
```

Use drop tables for ammo, health orbs, and material rolls.

## Enemies And Factions

Add enemy data in two places:

- Client-visible summary/stats: `ReplicatedStorage/Shared/Data/Enemies/Enemies.luau`
- Server authority stats: `ServerStorage/ServerData/Enemies/EnemyStats.luau`

Faction identity lives in `Factions.luau`. CE/enemy knowledge faction bias lives in:

- Shared display: `ReplicatedStorage/Shared/Data/Enemies/CE.luau`
- Server authority: `ServerStorage/ServerData/Enemies/CERewards.luau`

Every enemy faction referenced by locations or enemies should exist in `Factions.luau`.

## Crafting

Add recipes under `ServerStorage/ServerData/Crafting/RecipeBook/<Category>.luau`.

Supported output types currently include:

- `Weapon`
- `Material`
- `Decoration`
- `RoomTemplate`
- `Mod`
- `Currency`
- `Bundle`

Recipes can use material costs, timers, mastery rank gates, and mastery gate ids.

## Item Tags And Trading

Item tag data lives in `ReplicatedStorage/Shared/Data/Economy/ItemTags.luau`.

Use item tags for:

- Whether an item type is stackable.
- Whether an item type is tradeable.
- Whether a specific mod, armor piece, or attachment overrides type defaults.
- Future tags such as rarity, account-bound, quest item, premium, cosmetic, or market-restricted.

Current tradeable item types are:

- `Material`
- `Decoration`
- `Mod`
- `Armor`
- `Attachment`
- `Dallions`

`Armor` and `Attachment` are unique item types. Trade listings should use the item uid as `ItemId`; the service escrows the full item state and restores that same state to the buyer, seller, or canceling seller.

Attachment inventory currently supports unique ownership, crafting/grant output, profile persistence, and trading. Attachment equip slots are still future work and should be added once weapon/armor socket rules are defined.

Use `Coins` for normal currency costs. Legacy `Credits` payloads are still accepted by profile/trade code only for compatibility.

## Marketplace

Marketplace listings live under `ServerStorage/ServerData/Economy/MarketplaceCatalog/<Category>.luau`.

Use the marketplace for:

- Dallion purchases.
- Cosmetics.
- Room decorations.
- Convenience bundles.
- Placeholder Robux direct-purchase metadata.

Keep player trading separate from marketplace. Player trading belongs in `TradeService`.

## NPC Shops And Bounties

NPC definitions are public and live in `Npcs.luau`.

NPC shop data is server-owned and can define:

- Costs.
- Outputs.
- Daily stock.
- Rotations.
- Reset timers.

NPC bounties are repeatable or rotating tasks. Story quest chains should not live in bounty data.

Current bounty runtime supports these objective types:

- `CompleteNode`
- `DefeatEnemy`
- `GatherResource`
- `VisitLocation`
- `UnlockGate`

When an accepted bounty completes, rewards are paid immediately and `QuestService:RecordBountyComplete` is fired for story quests that wait on a bounty.

Bounty event hooks currently fire from:

- Mission completion for `CompleteNode`.
- Mission enemy kills for `DefeatEnemy`, including optional enemy id, role, or faction matching.
- Resource node gathers for `GatherResource`.
- World node activation for `VisitLocation`.
- Prologue mission completion for `UnlockGate` routes such as `EarthGate`, `MarsGate`, and `AtlasShardGate`.

Future physical gate interactables should also call `RecordGateUnlock` when they unlock non-story routes.

Bounty rewards currently support:

- `Coins`
- `Credits` as a legacy compatibility alias
- `Dallions`
- `Materials`

## Quests And Story

Quests are story chains. Missions are individual activities.

Quest data lives in `ServerStorage/ServerData/Quests/Questlines`.

Supported scaffold step types:

- `TalkToNpc`
- `CompleteNode`
- `CraftOrOwn`
- `OwnItem`
- `GatherResource`
- `DefeatEnemy`
- `VisitLocation`
- `UnlockGate`
- `CompleteBounty`

Storyline data lives in `Storylines.luau`. Story steps can be `CompleteNode`, `VisitLocation`, or `TalkToNpc`.

Quest progress hooks currently fire from:

- NPC interaction for `TalkToNpc`.
- Mission completion for `CompleteNode`.
- Mission enemy kills for `DefeatEnemy`.
- Resource node gathers for `GatherResource`.
- World node activation for `VisitLocation`.
- NPC bounty completion for `CompleteBounty`.
- Prologue mission completion for `UnlockGate`.
- Quest snapshot/evaluate calls for `CraftOrOwn` and `OwnItem`.

Future physical gate interactables should call `QuestService:RecordGateUnlock` for non-story gates.

## Rooms

Room templates and decorations live in `Rooms.luau`.

Room templates can define:

- `Tier`
- `SlotLimit`
- `Unlock`
- `Costs`
- `Bounds`

Optional real room models go under `ServerStorage.ServerAssets.Rooms` with the same name as the template id.

Optional real decoration models go under `ServerStorage.ServerAssets.Decorations` with the same name as the decoration id.

Include a `RoomSpawn` part in real room models when you want a custom entry point.

## Hub Interactions

Hub stations:

- Put a `BasePart` under `Workspace.Hub`.
- Set `HubServiceId`.
- Tag it `HubInteract`.

NPCs:

- Put a `BasePart` under `Workspace.Hub`.
- Set `NpcId`.
- Tag it `NpcInteract`.

Shared station metadata lives in `HubLayout.luau`; service definitions live in `HubServices.luau`.

## Resources

Resource node definitions live in `ResourceNodes.luau`.

To add a gatherable part in Studio:

- Set `ResourceId`.
- Set `LocationId`.
- Tag it `ResourceNode`.

The service adds prompts, validates location, grants material server-side, and applies cooldowns.

## Training

Training target definitions live in `TrainingRange.luau`.

To replace placeholder targets:

- Create a model with a `Humanoid`.
- Set `TrainingTargetId`.
- Set `IsTrainingTarget = true`.
- Tag the model `TrainingTarget`.

## Codex

Reusable lore, terms, and discovered records live in `Codex.luau`.

Codex entries can unlock by location or story step. The temporary hub Codex panel reads this data.

## Validation

Run this after content edits:

```powershell
rojo sourcemap default.project.json --output NUL
```

Then check Studio server output for `ContentValidator` warnings.

The validator checks cross references for locations, missions, nodes, recipes, marketplace listings, NPCs, quests, rooms, resource nodes, training targets, social config, factions, codex, and hub layout.
