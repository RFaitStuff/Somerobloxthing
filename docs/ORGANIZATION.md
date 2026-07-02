# Organization And Codebase Guide

This project is organized by Roblox service and gameplay domain. The long-term goal is a content-heavy RPG, so the codebase should stay data-first and modular.

## Core Rule

Client-safe display data can live in `ReplicatedStorage`.

Server authority data must live in `ServerStorage` or server scripts.

Never trust client-visible data for costs, drops, access, rewards, or spawn rules.

## Service Layout

| Roblox Service | Purpose |
| --- | --- |
| `ReplicatedStorage/Shared/Core` | Shared helpers: config, remotes, debug, input, utility, movement modes, animation registry. |
| `ReplicatedStorage/Shared/Data` | Client-visible public data: frames, weapons, missions summaries, public locations, rooms, codex, factions. |
| `ServerStorage/ServerData` | Server authority data: mission node configs, rewards, enemy drops, enemy stats, recipes, shops, bounties, marketplace catalog. |
| `ServerScriptService/GameServer` | Server services grouped by domain. |
| `StarterPlayerScripts/GameClient` | Client systems grouped by domain. |
| `asset_staging` | Non-Rojo asset notes/manifests. Safe place for Studio import planning. |
| `docs/extra` | Planning notes for assets, UI, animation, SFX, VFX, and other non-code production needs. |

## Server Domains

| Folder | Responsibility |
| --- | --- |
| `Core` | Player state, remotes, validation, settings, content validation. |
| `Combat` | Weapons, melee, abilities, statuses, action locks. |
| `Enemies` | Enemy spawning, AI, server enemy runtime. |
| `Missions` | Mission start, objective lifecycle, completion integration. |
| `Progression` | Profiles, inventory, resources, crafting, mastery, rewards. |
| `World` | Hub, world nodes, matchmaking, rooms, marketplace, NPCs, clans, chat, trade, training, quests, story. |
| `Security` | Movement/action validation helpers. |

## Client Domains

| Folder | Responsibility |
| --- | --- |
| `Movement` | Parkour controller, wall probing, slope/velocity motors, movement state machine. |
| `Camera` | Camera behavior. |
| `Combat` | Combat input and visual feedback. |
| `Animation` | Animation state and weapon visual attachment coordination. |
| `UI` | Temporary and domain UIs: hub console, equipment UI, gameplay HUD. |
| `Settings` | Settings client and keybind persistence calls. |
| `DevTools` | Debug/tuning/test panels. |

## Data Ownership Pattern

Use this split when adding systems:

1. Shared data describes what the client may display.
2. Server data describes what the server trusts.
3. Services consume server data and replicate sanitized snapshots.
4. Temporary UI consumes snapshots and sends small action requests.
5. ContentValidator checks references on startup.

Example:

- Public node display: `Locations.luau`
- Mission summary: `Missions.luau`
- Mission authority: `MissionNodes/Earth/Earth_Greenbelt_Exterminate.luau`
- Runtime service: `WorldService`, `MissionService`, `RewardService`
- UI: `HubConsoleClient`

## Current Important Services

- `HubService`: safe zone, station prompts, hub panel routing.
- `WorldService`: location/node visibility, node activation, matchmaking entry.
- `MissionService`: mission start/completion and reward integration.
- `MatchmakingService`: local/studio launch, solo, queues, reserved server path.
- `RoomService`: room rendering, privacy, visiting, invites, decoration placement.
- `SocialChatService`: server/hub/squad/clan/trade/room/whisper chat.
- `MarketplaceService`: premium-style vendor catalog.
- `TradeService`: player trade-board scaffold with escrow for stack items and unique mod/armor payloads.
- `NpcService`: NPC prompts, dialogue actions, shops, bounties.
- `QuestService`: story quest progress.
- `StoryService`: campaign/story journal and story node launching.
- `TrainingRangeService`: training target runtime and damage stats.

## Expansion Guidelines

- Prefer adding data files over editing services.
- Add a validator check when you add a new content table.
- Keep per-node mission setup in node files, not giant global tables.
- Keep marketplace and player trading separate.
- Put item trade/default rules in `ReplicatedStorage/Shared/Data/Economy/ItemTags.luau`.
- Keep story quests and repeatable bounties separate.
- Keep room ownership/privacy server-authoritative.
- Keep safe-zone combat rules server-side.
- Treat temporary UI as a test harness, not final product architecture.

## Asset Safety

Rojo can overwrite mapped instances. Imported Studio assets should live in Studio-owned storage unless intentionally mapped.

Recommended pattern:

- Define ids and expected model names in Luau data.
- Put real models in `ServerStorage.ServerAssets` or another deliberate Studio-owned folder.
- Let services prefer real models and fall back to placeholders.

Do not create asset folders under mapped source paths just to show where assets should go. In this project, `src/ServerStorage/ServerAssets` and `src/ReplicatedStorage/Shared/Assets` should stay absent unless we intentionally decide Rojo owns those assets. Use `asset_staging` for manifests and import notes instead.

## Validation And Testing

Run:

```powershell
rojo sourcemap default.project.json --output NUL
```

Then Studio playtest:

- Fresh profile Moon prologue.
- Hub unlock.
- Hub station prompts.
- Equipment/mod/crafting panels.
- Mission launch.
- Training range.
- Room entry/visit/invite/privacy.
- Chat channels.
- Marketplace/trade.

Rojo validation proves the project tree maps. It does not prove gameplay works.
