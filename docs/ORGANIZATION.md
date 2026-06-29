# Organization Notes

This version is Rojo-focused and organized by gameplay domain instead of by generic "Systems" folders.

## Roblox services

- `ReplicatedStorage/Shared/Core` contains shared engine-level helpers: config, net names, debug helpers, utilities, movement modes, input bindings, and animation ids.
- `ReplicatedStorage/Shared/Data` contains client-visible/public data only: frames, abilities, weapons, melee definitions, public enemy/codex data, factions, CE display rules, missions, rewards previews, and world location data.
- `ServerStorage/ServerData` contains server-owned authority data: reward tables, CE rewards, mission rules, enemy stats, crafting recipes, and node rules.
- `ServerScriptService/GameServer` contains real server systems grouped by domain: combat, enemies, missions, progression, world, core, security.
- `StarterPlayerScripts/GameClient` contains client systems grouped by domain: movement, camera, combat, animation, UI, settings, dev tools.

## Dev keys

- `G` toggles the game systems debug menu.
- `I` toggles the equipment menu.
- `F6` toggles hitbox visualization.

## Notes

Movement and camera were kept close to the previous implementation to avoid breaking the tuned controller. The biggest changes are organization, data ownership, weapon reliability, projectile support, equipment UI, XP debug controls, and world/node scaffolding.
