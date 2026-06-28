-- Put this Script directly inside a Part in Workspace.
-- The server EnemyService will detect the attributes and spawn enemies here.

local part = script.Parent

part:SetAttribute("EnemySpawner", true)
part:SetAttribute("EnemyId", "Raider, Gunner") -- Raider, Gunner, Bulwark, Acolyte, Caster, Deadeye
part:SetAttribute("SpawnInterval", 6)
part:SetAttribute("MaxAlive", 4)
part:SetAttribute("SpawnRadius", 6)

part.Transparency = 0.35
part.Color = Color3.fromRGB(255, 120, 60)
part.Material = Enum.Material.Neon
