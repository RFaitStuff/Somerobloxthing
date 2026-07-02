--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = {}

Registry.SequenceRootPath = { "Assets", "Animations", "Sequences" }

Registry.Aliases = {
    Idle = { Sequence = "Idle" },
    Sprint = { Sequence = "Sprint(remp)", Fallbacks = { "Sprint(temp)", "Sprint" } },
    Crouch = { Sequence = "Crouch_Idle" },
    CrouchWalk = { Sequence = "Crouch_Idle" },
    Jump = { Sequence = "Jump_Start", Fallbacks = { "Jump_start" } },
    Fall = { Sequence = "Jump_Loop", Fallbacks = { "Jump_loop" } },
    DoubleJump = { Sequence = "Double_Jump", Fallbacks = { "Double_jump" } },
    BulletJump = { Sequence = "Double_Jump", Fallbacks = { "Double_jump" } },
    AimGlide = { Sequence = "Float" },
    AimGlideForward = { Sequence = "Float" },
    AimGlideBackward = { Sequence = "Float_Reverse" },
    AimGlideTurn = { Sequence = "Float" },
    WeaponRelaxed = { Sequence = "Idle_Rifle" },
    WeaponAim = { Sequence = "Idle_rifle_aim", Fallbacks = { "Idle_Rifle_aim", "Aim_Rifle" } },
}

Registry.Looped = {
    Idle = true,
    Crouch = true,
    CrouchWalk = true,
    Fall = true,
    Sprint = true,
}

Registry.PreviewOrder = {
    "Idle",
    "WeaponRelaxed",
    "WeaponAim",
    "Sprint",
    "Jump",
    "Fall",
    "AimGlideForward",
    "AimGlideBackward",
    "DoubleJump",
    "Crouch",
}

local function findPath(root, path)
    local current = root
    for _, name in ipairs(path) do
        current = current and current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

function Registry.GetSequenceFolder()
    return findPath(ReplicatedStorage, Registry.SequenceRootPath)
end

function Registry.GetLegacyAnimationFolder()
    return ReplicatedStorage:FindFirstChild("Animations")
end

function Registry.Ensure()
    local sequenceFolder = Registry.GetSequenceFolder()
    if sequenceFolder then return sequenceFolder end

    local legacyFolder = Registry.GetLegacyAnimationFolder()
    if legacyFolder then return legacyFolder end

    warn("[AnimationRegistry] No animation folder found. Expected ReplicatedStorage.Animations or ReplicatedStorage.Assets.Animations.Sequences.")
    return nil
end

function Registry.GetSource(folder, alias)
    local entry = Registry.Aliases[alias]
    if not entry then return nil end
    folder = folder or Registry.Ensure()
    if not folder then return nil end

    local names = { entry.Sequence }
    for _, fallback in ipairs(entry.Fallbacks or {}) do
        table.insert(names, fallback)
    end

    for _, name in ipairs(names) do
        local source = folder:FindFirstChild(name)
        if source then
            return source, name
        end
    end

    return nil, entry.Sequence
end

return Registry
