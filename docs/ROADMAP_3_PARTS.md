# Three Part Roadmap

This roadmap splits the current goal into three large passes so the project can keep improving without turning every task into one giant edit.

## Part 1: Foundation, Data, Persistence

Purpose: make the game safe to expand.

Now in place or underway:

- Coins replaced old Credits as the normal currency name, with legacy Credits compatibility in profile/trade code.
- Dallions remain the premium currency. Starter Dallions are not tradeable; purchased/traded Dallions are tradeable at mastery rank 4.
- Item tag scaffolding exists for materials, decorations, mods, armor, attachments, and Dallions.
- Trade listings can escrow unique mod/armor state instead of only stack counts.
- Static authority data is kept in `ServerStorage/ServerData` where possible.
- Profile persistence now has a DataStore-backed envelope, session lock metadata, autosave, release-on-leave, shutdown save, and Studio/local fallback.

Still needed:

- Live-test profile persistence with Studio API Services and a published test place.
- Add retry/backoff policy for transient DataStore failures.
- Add transaction/audit logs for marketplace, trade, crafting, and Dallions.
- Add unique item ids for weapons and attachments once those inventories become non-stack systems.
- Add content validation for item tags, attachment ids, and economy references.
- Add migration notes for any saved profiles from old wallet shapes.

## Part 2: Combat, Vestiges, Weapons, Abilities

Purpose: make frames feel like real playable identities.

Now in place or underway:

- Shared ability hitbox presets exist in `ReplicatedStorage/Shared/Data/Combat/AbilityHitboxes.luau`.
- Server ability hitbox resolution exists in `ServerScriptService/GameServer/Combat/AbilityHitboxResolver.luau`.
- Supported ability shapes include projectile/fireball, sphere, box, cone, capsule, beam, field, and whip trace.
- `Luma` exists as a Wisp-like light/float support frame scaffold with projectile, mote field, phase dash, whip/beam, and bloom/burst options.
- The temporary Hub Console can select frames and ability variants.

Needed next:

- Convert ability timing to animation markers instead of immediate release.
- Add client VFX/SFX prediction for casts, fields, beams, whips, and impacts.
- Weapon behavior parity is improved for rifle, sidearm, shotgun, launcher, micro-rocket, beam, and melee slot switching. Still needed: bows, charge weapons, ammo pickups, and richer reload marker timing.
- Weapon model fallback now generates a simple rifle placeholder if Studio assets are missing. Still needed: authored models and attachment-specific grip offsets.
- Animation marker conventions for fire, reload insert, reload finish, melee active, ability release, footstep, land, float enter, and float exit.

Do not polish tuning too early. First make every intended control path exercisable in the temporary UI or dev tools.

## Part 3: Worlds, Missions, Quests, Publishing Path

Purpose: make the game loop scale from dev testing to real sessions.

Needed next:

- Expand the new mission objective runtime beyond exterminate/timer/wave/boss foundations into defense target health, patrol/public event state, salvage interaction steps, extraction, and failure rules.
- Node setup modules that place spawns, defense targets, extraction zones, resource drops, NPCs, and scripted story objects.
- Matchmaking shape: local studio launch, solo private launch, friend/squad launch, public queue, and reserved server handoff.
- Quest objective coverage now includes talk, complete node, own/craft item, gather resources, defeat enemy type, visit location, unlock gate, and complete bounty scaffolds. Still needed: codex scan objectives, deeper bounty completion hooks, and UI progress polish.
- Open planet area systems for Earth-style patrol spaces with fast travel points, enemy level bands, public events, resource nodes, and discoverable mission entrances.
- Hub unlock flow: Moon prologue, Earth gate, return to Moon, Mars gate, Atlas Shard hub reveal, then post-hub Moon/Earth/Mars expansion.

Publishing-facing work later:

- Real moderation-safe chat UX.
- Monetization compliance pass.
- Analytics for funnels, mission failure, economy sources/sinks, and retention.
- Server performance pass for enemies, projectiles, physics, matchmaking, rooms, and hub populations.
