--!nonstrict
local RangedAI = {}

function RangedAI.Step(ai, model, humanoid, root, targetPlayer, targetRoot, distance, _dt)
    local range = model:GetAttribute("AttackRange") or 90
    local preferred = model:GetAttribute("PreferredRange") or math.min(range * 0.62, 55)
    local retreat = model:GetAttribute("RetreatRange") or math.max(preferred * 0.45, 12)

    if distance > range * 0.88 then
        humanoid:MoveTo(targetRoot.Position)
    elseif distance < retreat then
        local away = root.Position - targetRoot.Position
        away = Vector3.new(away.X, 0, away.Z)
        if away.Magnitude > 0.01 then
            humanoid:MoveTo(root.Position + away.Unit * 16)
        else
            humanoid:MoveTo(root.Position)
        end
    elseif distance < preferred * 0.8 or distance > preferred * 1.2 then
        local toward = targetRoot.Position - root.Position
        toward = Vector3.new(toward.X, 0, toward.Z)
        local goal = toward.Magnitude > 0.01 and targetRoot.Position - toward.Unit * preferred or root.Position
        humanoid:MoveTo(goal)
    else
        humanoid:MoveTo(root.Position)
    end

    if distance <= range and ai:CanAttack(model) and ai:HasLineOfSight(model, targetRoot) then
        ai:MarkAttack(model)
        local falloff = distance > preferred and math.clamp(1 - ((distance - preferred) / math.max(range - preferred, 1)) * 0.35, 0.65, 1) or 1
        local burst = math.max(1, model:GetAttribute("BurstCount") or 1)
        local interval = model:GetAttribute("BurstInterval") or 0.08
        for index = 1, burst do
            task.delay((index - 1) * interval, function()
                if model.Parent then
                    ai:ShootTarget(model, targetPlayer, falloff)
                end
            end)
        end
    end
end

return RangedAI
