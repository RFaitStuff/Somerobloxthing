# Non-world gameplay update

This pass focused on core systems that are useful before world/node work.

## Melee

- Rebuilt `Shared/Data/Combat/Melee.luau` into a cleaner data-driven stance file.
- Added richer attacks: light combo, forward combo, heavy, air, slide, slam, and block data.
- Server melee now resolves attack timing, active windows, hitboxes, damage, and status effects.
- Client melee now only predicts animation/movement and sends action requests.
- Added melee block replication to the server and basic block damage reduction.
- Added box, radius, and capsule-style melee hitbox debug support.
- Fixed melee equip so equipping a melee weapon no longer replaces the active gun.

## Weapons

- Server now applies weapon spread instead of trusting the client for spread direction.
- Fixed explosion/projectile radius queries so overlap queries use `OverlapParams`, not `RaycastParams`.
- Kept client recoil visual-only.

## Equipment UI

- Added armor cards and armor equip/upgrade debug buttons.
- Added mod equip/unequip buttons.
- Added set weapon level, frame XP, weapon XP, and mastery XP debug buttons.
- Ranged weapons can now be assigned as Primary or Secondary separately.
- Melee weapons are equipped in their own melee slot.

## Progression

- Added starter armor data and stat scaling by frame level.
- Armor stats now contribute to frame stats.
- Added simple armor upgrade support.
- XP distribution now gives active gear XP and passive equipped gear drip.
- CE rewards now support role rewards plus faction bias.

## Not touched

- World structure / node routing / matchmaking.
- Publish-ready anti-cheat.
- Datastore persistence beyond the existing prototype profile flow.
