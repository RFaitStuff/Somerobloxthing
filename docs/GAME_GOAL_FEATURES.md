# Game Goal And Features

## Vision

Build a frame-based action RPG inspired by Warframe, Destiny, and traditional RPGs.

The player is a Stained: a powerful post-human survivor awakened in Moonveil on the moon. The game loop should combine fast parkour combat, RPG progression, mission nodes, open patrol areas, story quests, loot/crafting, social hub systems, player rooms, trading, and long-term mastery.

## Target Pillars

- Fast traversal and combat: bullet jumps, wall movement, aiming, gunplay, melee, abilities, and frame identity.
- World map progression: Moon prologue, Earth patrol/open area, Atlas Shard hub, Mars expansion, then more planets/nodes.
- Hub as operating base: equipment, mods, crafting, navigation, marketplace, trading, NPCs, quests, training, codex, and personal rooms.
- Content-driven expansion: most content should be data tables and per-node/per-planet modules, not hardcoded service edits.
- Social RPG layer: clans, chat channels, trade board, rooms, room chat, and future public hubs.
- Long-term progression: frames, weapons, armor, mods, crafting, mastery, CE/enemy knowledge, cosmetics, and story unlocks.

## Current Feature Map

| Area | Current State |
| --- | --- |
| Moon prologue | Moonveil starter flow exists with hidden post-hub Moon nodes. |
| Earth | Location/node data exists with prologue salvage and post-hub missions. |
| Mars | Location/node data exists with patrol, defense, event, and boss nodes. |
| Atlas Shard hub | Hub service exists with safe-zone rules and station prompts. |
| Safe zone | Weapons, melee, and abilities reject combat in hub/rooms unless training. |
| Equipment | Temporary UI supports weapon equip, armor, mods, and debug progression. |
| Mods | Basic equip/unequip and click-to-pick/drop simulation exists. |
| Crafting | Server recipe book, jobs, timers, claims, materials, and outputs exist. |
| Inventory | Profile inventory stores materials, armor, mods, weapons, decorations, room templates, wallet. |
| Marketplace | Vendor-style catalog exists with Coins/Dallions and direct Robux placeholders. |
| Player trade | Dev escrow board exists for materials, decorations, mods, armor, Coins, and Dallions rules. |
| Rooms | Own room, templates, privacy, visiting, invites, decoration placement/removal exist. |
| Training range | Hub training node and placeholder targets exist. |
| Mastery | Profile mastery summary, XP hooks, and mastery gates exist. |
| Chat | Server/hub/squad/clan/trade/room/whisper/system channels exist with filtering. |
| NPCs | Prompted NPCs, dialogue actions, shops, and bounties exist. |
| Quests/story | Storyline and questline scaffolds exist for Moonveil Awakening. |
| Codex | Shared codex entries and temporary hub panel exist. |

## Desired Player Flow

1. Player awakens in Moonveil on the moon.
2. Player restores a temporary moon base.
3. Player opens the Earth gate.
4. Player travels to Earth to recover Asteri gate components.
5. Player returns to Moonveil and completes the Mars/Atlas route.
6. Player reaches the Atlas Shard hub.
7. Player explores hub systems and ends the tutorial/prologue.
8. Player unlocks wider Moon nodes, Earth activities, Mars, rooms, trading, crafting, and long-term progression.

## Feature Quality Target

The current goal is not final polish. The target is a quality scaffold where:

- Systems are organized and expandable.
- Content authors can add data safely.
- Real Studio models can replace placeholders.
- Temporary UI can exercise every major system.
- Startup validation catches broken content references.
- The project is ready for iterative polish, map building, animation replacement, and economy tuning.

## Biggest Missing Pieces

- Real profile persistence through DataStore/ProfileStore style session locking.
- More complete combat identities: per-frame abilities, special hitboxes, melee shapes, projectiles, elemental/status behaviors, and animation marker events.
- Mission runtime depth: defense waves, exterminate counts, patrol events, story variants, bounty objectives, generated placement, extraction, and failure/retry rules.
- Quest objective coverage beyond the current TalkToNpc, CompleteNode, and CraftOrOwn scaffold.
- Real UI/UX: navigation map, inventory, equipment, mods, market, trade, quests, mission result, settings, and codex screens.
- Asset pass: frame models, weapon models, attachment grip points, animations, SFX, VFX, enemy rigs, drops, hub props, icons, and planet/node art.
- Economy tuning later: Coins, Dallions, crafting costs, shop rotations, drop rates, trade fees, premium bundles, and anti-abuse logging.
