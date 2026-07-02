# Hub, World, Rooms, and Chat Setup

This project now has server logic for a Warframe/Destiny-style hub plus public zones and private activities. The current UI is temporary, but the services are meant to survive when real models and polished UI arrive.

For the content workflow and startup validator, also see `docs/CONTENT_AUTHORING.md`.

## Hub Safe Zone

Players default into `LocationId = "Hub"` with `SafeZone = true`.

In hub safe zone:

- Gun firing is rejected by `WeaponService`.
- Melee attacks and blocking are rejected by `Melee`.
- Ability casts are rejected by `AbilityService`.
- Training range missions set `TrainingRange = true`, which allows combat again.

Press `H` in-game to open the temporary Hub Console.

## Hub Stations

To make a physical hub station interactive, create a `BasePart` in `workspace.Hub` and set:

- Attribute `HubServiceId = "Equipment"` or another service id.

Valid ids:

- `Equipment`
- `Mods`
- `Crafting`
- `Missions`
- `Navigation`
- `Marketplace`
- `Room`
- `Training`

Alternatively, tag a part with `HubInteract` and one of the service tags from `Shared.Data.World.HubServices`, such as `ModStation`, `Foundry`, `MissionBoard`, or `TrainingRange`.

`HubService` will add a `ProximityPrompt` automatically if the part does not already have one.

In Studio, if `workspace.Hub` has no parts with `HubServiceId`, `HubService` creates temporary dev stations in `workspace.Hub.DevStations`. Delete or replace those once you have real hub models. A real hub can include a `BasePart` named `HubSpawn` for return-to-hub placement.

## NPC Interaction

NPC data lives in:

- `src/ReplicatedStorage/Shared/Data/World/Npcs.luau`

To attach an NPC prompt to a model, put a `BasePart` in `workspace.Hub` and set:

- Attribute `NpcId = "Navigator"` or another NPC id.

You can also tag the part with `NpcInteract`. `NpcService` will add a `ProximityPrompt` and send dialogue/action data to the temporary Hub Console. In Studio, if no NPC parts exist, dev NPC blocks are created in `workspace.Hub.DevNpcs`.

Current NPC actions can:

- Open hub panels.
- Start the next story node.
- Enter the shooting range.
- Enter/rebuild the player's room.

## World Nodes

World data lives in:

- `src/ReplicatedStorage/Shared/Data/World/Locations.luau`
- `src/ServerStorage/ServerData/World/NodeRules.luau`
- `src/ReplicatedStorage/Shared/Data/Missions/Missions.luau`
- `src/ServerStorage/ServerData/Rewards/RewardTables.luau`

Moon, Earth, Atlas Shard, and Mars have node/location definitions. Studio bypasses location locks for faster testing. In production, the player starts in Moonveil, opens Earth through the Moon gate, then unlocks Atlas Shard and Mars after `CompleteMarsGate`.

## Hub Model Hookup

Real hub models should live under `Workspace.Hub` in Studio. Any interactable station can be wired without new scripts by setting the `HubServiceId` attribute on a `BasePart` to one of the service ids in `ReplicatedStorage.Shared.Data.World.HubServices`, then tagging it with `HubInteract`.

Supported service ids currently include `Equipment`, `Mods`, `Crafting`, `Missions`, `Navigation`, `Marketplace`, `Room`, `Training`, and `Codex`. The shared `HubLayout` module documents the root folder name, interact tag, prompt defaults, and dev placeholder layout. If a station part does not already have a `ProximityPrompt`, the server creates one and opens the matching hub panel.

NPC interactables work the same way with the `NpcId` attribute and `NpcInteract` tag. The server creates prompts and routes actions through `NpcService`, including shops, bounties, story starts, room entry, and training entry.

## Personal Rooms

`RoomService` renders each online player's room under `Workspace.PlayerRooms` using either a real model in `ServerStorage.ServerAssets.Rooms` or the placeholder shell from `Rooms.luau`. Room templates define bounds and decoration limits; decorations can use real models in `ServerStorage.ServerAssets.Decorations` or placeholder parts.

Room privacy is server-authoritative:

- `Private`: only the owner can enter.
- `Friends`: Roblox friends can enter.
- `Invite`: only players in the owner's `Room.Invites` table can enter.
- `Clan`: players sharing the owner's clan id can enter.
- `Public`: any same-server player can enter.

The temporary hub Room panel exposes a same-server room directory, visit buttons, invite by player name, invite revocation, template switching, privacy changes, and decoration placement/removal. Later, this is the clean place to replace the placeholder renderer with a MeepCity-style room editor while preserving the server-side ownership and privacy checks.

Room templates can be unlocked two ways:

- Through crafting recipes that output `RoomTemplate`.
- Directly from the Room panel with `PurchaseTemplate`, which checks the template's mastery gate and material costs before granting ownership.

## Story Journal

Story data lives in:

- `src/ReplicatedStorage/Shared/Data/World/Storylines.luau`
- `src/ServerScriptService/GameServer/World/StoryService.luau`

The temporary Hub Console has a Story tab that shows the active arc, completed steps, the current objective, unlocked locations, and a button to start the next story node. In Studio, it also exposes a debug-complete button for the next unfinished step so Earth-to-Mars unlocks can be tested quickly.

Mission completion calls `ProfileService:MarkMissionComplete`, which updates completed story steps, unlocks Mars after `DefeatDeadeye`, and refreshes the story journal for the player.

## Resource Nodes

Resource definitions live in:

- `src/ReplicatedStorage/Shared/Data/World/ResourceNodes.luau`

To attach a gatherable resource to the map, create a `BasePart` and set:

- `ResourceId = "AlloyOutcrop"` or another resource id.
- `LocationId = "Earth"` or `"Mars"`.

Optionally tag the part with `ResourceNode`. `ResourceNodeService` adds a `ProximityPrompt`, validates the location, grants materials server-side, and applies a per-player cooldown. In Studio, temporary resource nodes are created under `workspace.WorldResources` if no real nodes exist.

## Training Range

Training target definitions live in:

- `src/ReplicatedStorage/Shared/Data/World/TrainingRange.luau`
- `src/ServerScriptService/GameServer/World/TrainingRangeService.luau`

The hub Training station starts the `Hub_TrainingRoom` node, which makes the player's server state `TrainingRange = true`. Weapons, melee, and abilities are still blocked in the normal hub safe zone, but they are allowed in this training mission.

In Studio, `TrainingRangeService` creates placeholder targets under `workspace.TrainingRange`. To replace them with real models, create a model with:

- Attribute `TrainingTargetId = "LightDummy"` or another target id.
- Attribute `IsTrainingTarget = true`.
- A `Humanoid`.
- One or more hit parts under the model.

Tag the model with `TrainingTarget`. The service resets target health/shields, tracks player hit damage from the shared combat pipeline, and replicates temporary stats to the Hub Console Training tab.

## Matchmaking

`World/MatchmakingService.luau` supports:

- Local Studio launch fallback.
- Solo launch.
- In-memory server queue.
- MemoryStore queue intent.
- Reserved server TeleportService path when `PlaceId` is configured on node rules.

To turn on real private mission places, add `PlaceId` to node rules and publish the destination place.

## Rooms

Room definitions live in `Shared.Data.World.Rooms`.

Profiles store:

- Current room template.
- Privacy mode.
- Owned decorations.
- Placed decoration transforms.

`RoomService` stores layout data and can also render a dev room preview into `workspace.PlayerRooms/<UserId>`.

Model override paths:

- Room templates: `ServerStorage.ServerAssets.Rooms.<TemplateId>`
- Decorations: `ServerStorage.ServerAssets.Decorations.<DecorationId>`

If those models do not exist, the service creates simple anchored placeholder parts. Room template models should include a `BasePart` named `RoomSpawn` somewhere inside the model when you want precise spawn placement.

The temporary Hub Console room tab can enter/rebuild the room, swap owned room templates, set privacy, place owned decorations, and remove placed decorations. This is intentionally compatible with replacing the renderer later with a MeepCity-style plot/room system: keep the `Room.Placed` data shape and swap the rendering internals.

## Crafting

Server-only recipes live in:

- `src/ServerStorage/ServerData/Crafting/RecipeBook/<Category>.luau`

The temporary Hub Console reads recipes through `CraftingService` and can:

- Start recipes.
- Spend materials.
- Wait for timers.
- Claim outputs.

Outputs currently support:

- `Weapon`
- `Material`
- `Decoration`
- `RoomTemplate`
- `Mod`

## Marketplace

Marketplace data lives in:

- `src/ServerStorage/ServerData/Economy/MarketplaceCatalog/<Category>.luau`

`World/MarketplaceService.luau` is currently an in-game vendor, not a Robux purchase flow. It spends profile wallet Coins and grants materials, room decorations, or room templates through the same profile grant path as crafting.

Use this for early economy tuning:

- Material catch-up packs.
- Room decorations.
- Non-combat cosmetics later.
- Weekly vendor stock later.

Real player trading should be a separate service with escrow, duplicate prevention, and server-validated listing ownership.

## Trade Board

`World/TradeService.luau` is a dev trade-board scaffold, separate from the vendor marketplace.

Current support:

- Stackable materials.
- Room decorations.
- Credit prices.
- Server escrow when a listing is created.
- Seller cancel to reclaim escrow.
- Online seller payout when another player buys.

The temporary Hub Console has a Trade tab. This should evolve into persistent cross-server listings only after unique inventory IDs and audit logs are in place.

## Chat

Custom social chat is scaffolded in `World/SocialChatService.luau`.

Channels:

- Server
- Hub
- Squad
- Clan
- Trade
- Room
- System

Messages are filtered through `TextService`. This is a custom remote-driven chat surface, not yet integrated into Roblox `TextChatService` UI channels. A future polished chat UI can consume the same `SocialChatUpdate` packets.

## Temporary UI

Press `H` to open `HubConsoleClient`.

It includes:

- Equipment
- Mods with click-to-pick/drop simulation
- Crafting
- Navigation/Missions
- Marketplace vendor
- Room customization
- Training
- Chat

This is intentionally temporary and system-focused. Replace visuals later, keep the remotes/services.
