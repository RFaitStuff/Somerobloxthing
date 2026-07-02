# Gap Analysis

This is the current missing/improvement list against the active project goal.

## Biggest Missing Pieces

### Persistence

Profiles now have a DataStore-backed envelope with autosave, session lock metadata, release-on-leave, shutdown save, versioning, and local fallback when DataStore is unavailable. Before serious playtests, this still needs live Studio/API testing, retry/backoff tuning, migration review, and transaction/audit logs for economy-sensitive actions.

### Real Hub And World Geometry

The code can create dev placeholders, but the game still needs real Studio-built spaces:

- Moonveil starter base and gate area.
- Earth patrol area.
- Atlas Shard hub.
- Mars patrol/mission entrances.
- Training range.
- Room templates and decoration assets.

### Mission Runtime Depth

Mission nodes have data, matchmaking, rewards, a modular objective runtime foundation, and basic starts/completions, but need richer objective logic:

- Defense objective health and fail states.
- Survival extraction/resource drain.
- Patrol/public event state.
- Boss phases.
- Story variants.
- Extraction and failure rules.
- Mission result screen.

### Enemy Variety And AI

Enemy roles exist, but the game needs:

- Faction-specific behaviors.
- More ranged/melee archetypes.
- Boss AI.
- Spawn directors by mission type.
- Level scaling and elite variants.
- Better encounter pacing.

### Quest Objective Coverage

Quest data supports story direction, but objective handling is still narrow. Needed:

- Craft/own objective completion.
- Travel/visit objective completion beyond debug flows.
- Multi-step objectives.
- Objective UI markers.
- Quest rewards and replay/variant behavior.

### Inventory Item Identity

Stackables are fine, but long-term RPG systems need unique item ids for:

- Rare weapons.
- Armor rolls.
- Tradable cosmetics.
- Decor variants.
- Equipped item protection.
- Trade escrow/audit logs.

### Polished UI

Temporary UI exercises systems but is not final. Needed:

- Real hub panels.
- Drag/drop mod grid.
- Inventory filters/search.
- Mission star chart UI.
- Marketplace/trade UI.
- Room editor UI.
- Chat window integrated into normal gameplay.

### Economy Balancing

Coins, Dallions, materials, marketplace, crafting, trading, and rooms exist as scaffolds. Needed:

- Real earning rates.
- Material sinks.
- Drop rates per planet/node.
- Daily/weekly rotation rules.
- Anti-dupe protections.
- Trade taxes/fees if desired.

### Matchmaking And Teleports

Local/studio flow exists, but production needs:

- Published mission place ids.
- Reserved server testing.
- Party retention.
- Rejoin/failure handling.
- Cross-server public zone routing.

### Settings And Moderation

Settings and chat exist, but production needs:

- Mute/block/report.
- Moderation audit hooks.
- Chat privacy controls.
- Settings persistence hardening.
- Accessibility pass.

## Improvements To Prioritize Next

1. Implement profile persistence and migrations.
2. Add a real mission objective controller layer.
3. Add quest objective completion for `CraftOrOwn` and `VisitLocation`.
4. Create a proper room editor placement mode.
5. Expand enemy AI and faction spawn directors.
6. Replace temporary hub UI with panel-specific UI modules.
7. Add more content nodes using the final data structure.
8. Add automated/content validation checks beyond Rojo sourcemap.

## Things That Are In Good Shape For Now

- Data separation between shared display data and server authority data.
- Hub safe-zone enforcement.
- Physical hub station/NPC prompt hookup.
- Room ownership/privacy/visiting foundation.
- Chat channel scoping foundation.
- Marketplace/trade split.
- Moon prologue into Atlas Shard direction.
- Content validator coverage.

## Definition Of Ready For Polish

The project is ready for polish when:

- New content can be added without touching core services.
- Studio assets can be dropped in with attributes/tags and work.
- A fresh player can complete Moon prologue, unlock hub, run Earth/Mars nodes, use hub systems, craft, trade, chat, train, and customize a room.
- Runtime warnings are expected and documented.
- Core data saves and loads across sessions.
