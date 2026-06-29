--!nonstrict
local MeleeAI = {}

function MeleeAI.Step(ai, model, humanoid, root, targetPlayer, targetRoot, distance, _dt)
    local range = model:GetAttribute("AttackRange") or 6
    local stopDistance = math.max(range * 0.72, 3)
    if distance > stopDistance then
        humanoid:MoveTo(targetRoot.Position)
    else
        humanoid:MoveTo(root.Position)
    end

    if distance <= range and ai:CanAttack(model) then
        ai:MarkAttack(model)
        ai:DamageTarget(model, targetPlayer)
    end
end

return MeleeAI
