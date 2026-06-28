# Studio Setup And Testing

## Setup
- Sync Rojo, then play from Roblox Studio.
- Do not manually add `ReplicatedStorage.Remotes`; the server creates it.
- Keep real `Animation` objects in `ReplicatedStorage.Animations` with the names already used by the controller.
- Optional: add a flat test arena and a `SpawnLocation`.

## Test Keys
- `G`: game systems test menu.
- `P`: movement tuning/debugger.
- `Alt`: unlock cursor for menus.

## Quick Tests
- Select each frame and confirm health, shield, mana, and abilities update.
- Spawn each enemy role and confirm they move toward you and attack.
- Enemy factions currently have 3 enemies each: Earth Bandits (`Raider`, `Gunner`, `Bulwark`) and Void Cult (`Acolyte`, `Caster`, `Deadeye`).
- For part-based spawning, paste `docs/enemy-spawner-part-script.server.lua` into a Script inside any Workspace Part.
- Use the `G` menu `Runtime Tuning` section to adjust frame, gun, melee, and enemy values for the current play session.
- Use `G > Enemies > Pause Enemy AI` when tuning damage, weapons, or movement without enemies chasing.
- Start each mission type and confirm progress/completion/rewards update.
- Equip each weapon, fire, reload, and confirm enemy kills grant XP/CE.
- Try melee light/heavy/air/slide/slam against spawned enemies.
- Cast every ability and confirm cooldown, mana, damage, and statuses.
- Use the `Validation` buttons in the `G` menu and confirm `Last reject` updates.
