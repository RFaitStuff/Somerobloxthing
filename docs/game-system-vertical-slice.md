# Game Systems Vertical Slice Checklist

## Data
- [x] Add shared frame, ability, weapon, enemy, faction, reward, XP, CE, mission, melee, and status definitions.
- [x] Keep definitions data-driven so new content can be added without bespoke scripts.
- [x] Preserve compatibility wrappers for existing weapon, melee, and status module callers.

## Server Systems
- [x] Add memory-backed profile service shaped for future DataStore persistence.
- [x] Add frame/stat service and runtime resource service for health, shield, and mana.
- [x] Add shared combat damage pipeline used by melee, weapons, abilities, and enemies.
- [x] Add ability, weapon, enemy, mission, reward, and progression services.
- [x] Add server-authoritative remotes for test UI requests.

## Combat
- [x] Improve melee validation, combo timing, active windows, hit confirmation, and status application.
- [x] Improve statuses with duration, stacking, ticking, movement modifiers, control effects, and resource modifiers.
- [x] Add V1 ranged weapon fire/reload validation and damage.
- [x] Add V1 ability blocks for projectile, AoE, dash, buff, debuff, and heal/shield.

## UI
- [x] Add a toggleable game systems test menu separate from the movement debugger.
- [x] Add frame, ability, weapon, enemy, mission, progression, and reward testing views.
- [x] Show player resources, frame level, weapon XP, mastery, CE, cooldowns, and mission state.

## Testing
- [ ] Join with a default profile and frame.
- [ ] Select frames, variants, and weapons through UI.
- [ ] Spawn enemies and damage them with melee, weapons, and abilities.
- [ ] Confirm XP, CE, mastery, and rewards update.
- [ ] Confirm invalid remote requests are rejected server-side.

## Polish
- [ ] Replace placeholder UI with final production screens later.
- [ ] Replace memory profiles with DataStore-backed persistence later.
- [ ] Add armor, mods, crafting, trading, clans, housing, prestige, and subsuming after the vertical slice stabilizes.
