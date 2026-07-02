# Weapons

Expected Studio asset shape for each weapon model:

- Model name matches weapon visual config, for example `Rifle`.
- Contains a main handle named `HandleRight`.
- Optional attachment named `Muzzle`.
- Parts are unanchored/massless at runtime by `WeaponService`.
- Missing weapon models should fall back to rifle visuals through `WeaponVisuals`.

Do not map this folder in Rojo unless you intend Rojo to own the weapon models.
