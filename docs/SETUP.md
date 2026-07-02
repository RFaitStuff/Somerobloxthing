# Setup

This project is a Rojo-based Roblox game scaffold. The current build is focused on fast local iteration, content tables, and temporary UI panels that can be replaced later.

## Quick Start

1. Open the repo folder:

```powershell
cd "D:\Projects\Game Dev\Roblox\Somerobloxthing"
```

2. Validate the Rojo tree:

```powershell
rojo sourcemap default.project.json --output NUL
```

3. Open/sync through your normal Rojo + Studio workflow.

4. In Studio, run Play Solo or Start Server/Players.

5. Press `H` in-game to open the temporary Hub Console.

## Important Dev Keys

- `H`: temporary Hub Console.
- `I`: equipment UI.
- `G`: game systems debug menu.
- `F6`: hitbox visualization.

## Studio Asset Hookup

Rojo should not own imported Studio assets unless you intentionally map them. Keep Studio-owned models, animations, VFX, and meshes outside mapped source folders.

Current mapping rule:

- `src/ServerStorage/ServerData` is Rojo-owned.
- `src/ReplicatedStorage/Shared` is Rojo-owned code/data.
- `ServerStorage.ServerAssets` is Studio-owned and intentionally not mapped.
- `ReplicatedStorage.Animations` and `ReplicatedStorage.Assets` are Studio-owned and intentionally not mapped.
- `asset_staging` is repo-only planning/import material and is not synced into Studio.

Use these locations for runtime model overrides:

- Weapon models: `ServerStorage.ServerAssets.Weapons.<WeaponName>`
- Room templates: `ServerStorage.ServerAssets.Rooms.<TemplateId>`
- Decorations: `ServerStorage.ServerAssets.Decorations.<DecorationId>`
- Weapon visuals: follow `ReplicatedStorage.Shared.Data.Combat.WeaponVisuals`
- Animations: place real Animation instances under `ReplicatedStorage.Animations` or `ReplicatedStorage.Assets.Animations.Sequences`

## Hub Setup

Real hub models should live under `Workspace.Hub`.

For hub station parts:

- Set attribute `HubServiceId` to a service id such as `Equipment`, `Mods`, `Crafting`, `Missions`, `Navigation`, `Marketplace`, `Room`, `Training`, or `Codex`.
- Tag the part `HubInteract`.

For NPC parts:

- Set attribute `NpcId` to an id from `Npcs.luau`.
- Tag the part `NpcInteract`.

The server creates `ProximityPrompt`s automatically if missing.

## Room Setup

Room rendering uses placeholder geometry unless a matching model exists in `ServerStorage.ServerAssets.Rooms`.

For real room models:

- Model name must match the room template id.
- Include a `RoomSpawn` part for custom spawn placement.
- Keep expected bounds roughly aligned with `Rooms.luau`.

For real decoration models:

- Model name must match the decoration id.
- The server will pivot the model to the saved placement transform.

## Validation

Startup content validation runs in `ContentValidator`. It warns about broken references but does not crash Studio.

Use warnings as a to-do list before polish or publish.

## Profile Persistence

Profiles now use `ProfileService` with a DataStore envelope:

- Store name: `Config.Networking.ProfileDataStoreName`
- Autosave interval: `Config.Networking.ProfileAutosaveSeconds`
- Session lock timeout: `Config.Networking.ProfileSessionLockSeconds`

In Studio, enable API Services if you want DataStore saves to actually persist. If DataStore calls fail, the service falls back to local-only profiles for that session so dev testing can continue.

Player leaving releases the profile lock. Server shutdown saves and releases all loaded profiles.

## What Is Not Production Ready

- DataStore persistence is scaffolded but still needs live Studio/API testing, migration review, retry/backoff tuning, and abuse-safe transaction logs.
- Player trading is development-only and online-only.
- Matchmaking has local/studio fallbacks and needs published place ids for real reserved servers.
- Temporary UI is system-facing, not final UX.
- Combat/movement needs Studio tuning against real maps and animation assets.
