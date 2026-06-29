--!nonstrict
local Util = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Core"):WaitForChild("Util"))

local CharacterBinder = {}
CharacterBinder.__index = CharacterBinder

function CharacterBinder.new(controller)
    return setmetatable({ Controller = controller }, CharacterBinder)
end

function CharacterBinder:Bind(character)
    local controller = self.Controller
    controller.Character = character
    controller.Humanoid, controller.Root = Util.GetCharacterParts(character)
    if controller.Root then
        controller.Velocity = controller.Root.AssemblyLinearVelocity
    end
    if controller.Camera then controller.Camera:BindCharacter(character) end
    if controller.Animation then controller.Animation:BindCharacter(character) end
end

return CharacterBinder
