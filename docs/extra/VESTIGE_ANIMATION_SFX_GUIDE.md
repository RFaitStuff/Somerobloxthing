# Vestige Animation And SFX Guide

Use this for frame, weapon, ability, and enemy asset work. The current game can run on placeholders, but every real animation or sound should follow predictable ids and marker names so code can stay modular.

## Animation Sets

Each Vestige/frame should eventually define:

- Idle
- Idle_Rifle
- Idle_Rifle_Aim
- Crouch_Idle
- Sprint
- Jump_Start
- Jump_Loop
- Double_Jump
- Float
- Float_Reverse
- Land
- Roll or dodge
- Wall_Run_Left
- Wall_Run_Right
- Wall_Jump
- Ability_1 through Ability_4
- Melee_Light_1 through Melee_Light_3
- Melee_Heavy

Weapon-specific overlays should exist for rifle, pistol, bow, launcher, and melee. Missing overlays can fall back to rifle or neutral idle until proper assets exist.

## Required Markers

Use animation markers instead of hardcoded delays wherever possible:

- `Fire`: projectile or hitscan release.
- `ReloadInsert`: ammo enters the weapon.
- `ReloadFinish`: weapon can fire again.
- `MeleeActive`: hitbox begins.
- `MeleeRecover`: hitbox ends.
- `AbilityRelease`: projectile, field, or burst spawns.
- `AbilityRecover`: player regains normal control.
- `Footstep`: play material-aware footstep.
- `Land`: play landing sound/VFX.
- `FloatEnter`: start hover loop.
- `FloatExit`: end hover loop.

## SFX Needs

Create short, layered sounds for:

- Weapon fire, dry fire, reload start, reload insert, reload finish.
- Melee swing, melee impact flesh, melee impact armor, melee impact shield.
- Ability cast start, release, loop, impact, expire.
- Parkour jump, double jump, wall contact, wall jump, slide, roll, hard land.
- Pickup sounds for ammo, material, mod, armor, and Dallions.

Keep loops short and clean. The code should be able to start/stop loops without audible pops.

## VFX Needs

Each ability should declare expected VFX ids:

- Cast hand glow.
- Projectile or beam.
- Impact burst.
- Lingering field.
- Buff/debuff aura.
- Cooldown/ready flash for UI later.

## Hitbox Expectations

Abilities and weapons should choose a hitbox family:

- `Raycast`: rifle, pistol, precise beams.
- `Projectile`: fireball, rockets, thrown blades.
- `Sphere`: radial burst, healing pulse.
- `Box`: slam, rectangular trap.
- `Cone`: shotgun blast, breath attack.
- `Capsule`: melee arc approximation, dash strike.
- `Beam`: sustained beam or tether.
- `WhipTrace`: segmented melee/ability path.
- `Field`: lingering area hazard or support zone.

The ability data should own shape, lifetime, team rules, damage package, status package, and whether the hitbox can multi-hit.

Runtime note: `Field` abilities are anchored at the cast transform and tick server-side from `Duration` and `Ticks`. Author field VFX with a spawn burst, an optional loop that lasts for the duration, a tick/ pulse moment that can repeat, and an expire burst.

Ability lifecycle events currently replicate through `AbilityUpdate`: `Cast`, `Impact`, `FieldTick`, and `FieldExpire`, plus private `Cooldown` updates for the caster. Future VFX/SFX code should bind sounds, particles, beam attachments, and field loops to those event names.

Temporary client feedback lives in `StarterPlayerScripts/GameClient/Combat/AbilityFeedbackClient.luau`. It draws neon placeholders for cast bursts, impact bursts, field pulses, and directional lines. Replace those placeholders with authored particle emitters, Beam objects, sound assets, and cleanup timing as each Vestige kit gets real art.

## Wisp-Like Vestige Direction

Current scaffold name: `Luma`.

Identity:

- Float-heavy movement.
- Support field.
- Light projectile.
- Short blink or phase movement.
- Area control ultimate.

Starter ability kit target:

- `Glimmer Bolt`: light projectile with small splash.
- `Haven Mote`: support field that grants regen or shield recovery.
- `Phase Step`: short blink that leaves a decoy/afterimage later.
- `Solar Bloom`: area field that damages enemies and buffs allies.

Implemented data variants:

- Slot 1: `GlimmerBolt`, `SunflareOrb`
- Slot 2: `HavenMote`, `PhaseStep`
- Slot 3: `RadiantWhip`, `SolGate`
- Slot 4: `SolarBloom`, `PrismBurst`

Most casts currently resolve server-side immediately on cast, while `Field` abilities tick for their configured duration. The next asset/code pass should make casts wait for `AbilityRelease`, play SFX/VFX at marker time, and show field/beam/whip visuals on clients.
