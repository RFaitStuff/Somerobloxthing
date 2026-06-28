# Project Structure

## Roblox Containers
- `ReplicatedStorage.Shared`: client/server code that is safe to read on clients. Keep contracts, config, debug helpers, pure utilities, and non-secret game data here.
- `ReplicatedStorage.Remotes`: created by `GameServer/Core/Remotes` at runtime. Do not hand-create these unless Studio testing without the server boot script.
- `ServerScriptService.GameServer.Core`: boot wiring, remotes, persistent player state tables, collision setup, loadout/settings plumbing.
- `ServerScriptService.GameServer.Systems`: authoritative gameplay services. Profiles, frames, resources, abilities, weapons, enemies, missions, rewards, and combat routing live here.
- `ServerScriptService.GameServer.Enemies.AI`: reusable enemy decision logic. Keep the universal brain here, then add role/faction-specific AI modules as needed.
- `ServerScriptService.GameServer.Combat`: combat-specific server modules such as melee and status execution.
- `ServerScriptService.GameServer.Security`: validation and anti-cheat style checks.
- `ServerStorage.GameData`: server-only data, future secret drop tables, persistence templates, and validation-only tables.
- `ServerStorage.TempAnimations`: server-owned temporary animation id references. Keep real Studio `Animation` instances in `ReplicatedStorage.Animations`.
- `StarterPlayer.StarterPlayerScripts.AdvancedController`: only input, movement, camera, and character controller code.
- `StarterPlayer.StarterPlayerScripts.AdvancedSystems`: client-side animation, combat prediction, test UI, settings, and debug UI.

## Module Rules
- Put shared definitions in `Shared/GameData` when UI and server both need to read them.
- Put server authority in `GameServer/Systems`; clients should request actions through remotes, not calculate rewards or damage.
- Keep remotes named by intent: `SomethingRequest` for client-to-server, `SomethingUpdate` for server-to-client.
- Keep Studio assets out of Rojo if Rojo would replace real objects with folders, especially `ReplicatedStorage.Animations`.
