# Project Docs

Start here when returning to the project.

## Main Manuals

- [Setup](SETUP.md): how to run, validate, and hook Studio assets to the current systems.
- [Game Goal And Features](GAME_GOAL_FEATURES.md): the intended Destiny/Warframe/RPG direction and current feature map.
- [Content Authoring](CONTENT_AUTHORING.md): how to add missions, nodes, quests, shops, rooms, enemies, rewards, and more.
- [Story](STORY.md): core lore, opening flow, Atlas Shard, Moonveil, and major terms.
- [Organization](ORGANIZATION.md): how the codebase is laid out and how systems talk to each other.
- [Gap Analysis](GAP_ANALYSIS.md): what is missing, weak, or needs polish against the current goal.
- [Three Part Roadmap](ROADMAP_3_PARTS.md): the current implementation plan split into foundation, combat/content identity, and world/runtime work.

## Supporting Notes

- [Hub World Setup](HUB_WORLD_SETUP.md): detailed hub, room, resource, training, matchmaking, trade, and chat hookup notes.
- [Social Settings Roadmap](SOCIAL_SETTINGS_ROADMAP.md): chat, trade, clan, and settings production concerns.
- [Parkour Tuning Update](PARKOUR_TUNING_UPDATE.md): movement tuning notes.
- [Non-world Update](NON_WORLD_UPDATE.md): earlier combat/equipment/progression pass notes.
- [Vestige Animation/SFX Guide](extra/VESTIGE_ANIMATION_SFX_GUIDE.md): assets, animation markers, sound hooks, and hitbox expectations for frames and abilities.
- [UI And Asset Requests](extra/UI_ASSET_REQUESTS.md): what temporary systems need from future UI, icon, model, VFX, and audio work.

## Current Validation Command

Run this after data or Rojo tree changes:

```powershell
rojo sourcemap default.project.json --output NUL
```

This only validates the Rojo project mapping. Studio playtesting is still required for runtime behavior.
