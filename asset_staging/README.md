# Asset Staging

This folder is intentionally outside `src` and is not mapped by `default.project.json`.

Use it for planning/import notes for models, animations, VFX, icons, sounds, and other Studio-authored assets. Do not put live Rojo-managed instances here unless `default.project.json` is intentionally changed.

Expected live asset destinations:

- Weapon models: `ServerStorage.ServerAssets.Weapons`
- Room templates: `ServerStorage.ServerAssets.Rooms`
- Decorations: `ServerStorage.ServerAssets.Decorations`
- Enemy models: `ServerStorage.ServerAssets.Enemies`
- VFX templates: `ReplicatedStorage.Assets.VFX` only if clients need direct access
- Animation objects: `ReplicatedStorage.Animations` or `ReplicatedStorage.Assets.Animations.Sequences`
- Animation ids: data modules, not raw animation objects, unless intentionally synced
