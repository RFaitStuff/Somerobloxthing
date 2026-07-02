# UI And Asset Requests

This file lists what the temporary systems need from future UI, art, model, animation, VFX, and audio work.

## UI Screens

Needed screens:

- Navigation map with planets, areas, nodes, locks, matchmaking, story variants, and fast travel.
- Mission select with rewards, enemy level, faction, squad state, and public/solo launch.
- Inventory with weapons, armor, mods, attachments, materials, cosmetics, and currencies.
- Equipment screen for Vestige/frame, weapons, armor, mods, attachments, cosmetics, and loadouts.
- Mod screen with equip, rank, fusion/upgrades, filtering, sorting, and capacity later.
- Marketplace with Dallions, Robux direct purchase, bundles, cosmetics, owned states, and limited offers.
- Trade board with listings, create listing, cancel, buy, fees later, and Dallion mastery lock messaging.
- NPC shop and bounty panels with rotations, limited stock, cooldowns, and requirements.
- Quest journal with story steps, active objective, story version flags, and rewards.
- Mission result screen with rewards, XP, mastery, drops, bounty progress, and quest progress.
- Settings, chat, clan, room, codex, and training range screens.

## Icons

Needed icon sets:

- Currencies: Coins, Dallions.
- Item types: weapon, armor, mod, attachment, material, decoration, bundle, cosmetic.
- Damage/status types.
- Mission types.
- Node locks and unlock requirements.
- Fast travel, squad, matchmaking, solo, public event, story variant.
- UI actions: equip, unequip, upgrade, craft, buy, sell/list, cancel, inspect, favorite, compare.

## 3D Models

Needed models:

- Default rifle fallback.
- Pistol, shotgun, bow, launcher, and melee placeholder families.
- Per-weapon `HandleRight`, optional `HandleLeft`, `Muzzle`, and `AimPart` attachments/parts matching `WeaponVisuals.luau`.
- Attachment models with grip/mount metadata.
- Moonveil starter base props.
- Atlas Shard hub stations.
- Earth patrol props and mission entrances.
- Resource node props.
- Drop pickups: ammo, health, material, mod, armor.
- NPC rigs with prompt attachment points.
- Enemy rigs for each starting faction.

## Animation Assets

See `VESTIGE_ANIMATION_SFX_GUIDE.md` for marker names. Priority order:

1. Core locomotion and rifle idle/aim/fire/reload.
2. Jump, double jump, float, float reverse, land.
3. Wall jump and wall run.
4. Ability casts.
5. Melee chains.
6. NPC/enemy locomotion and attacks.

## Audio And VFX

Needed early:

- Rifle fire/reload.
- Ability cast/release/impact.
- Parkour movement sounds.
- Pickup sounds.
- Hit shield, hit armor, hit flesh.
- Mission success/fail stingers.
- Hub ambient loop.

VFX should be authored as replaceable ids so placeholder particles can become polished effects without changing gameplay code.
