--!nonstrict
local RecipeBook = {}

RecipeBook.Categories = {
    Weapons = require(script:WaitForChild("Weapons")),
    Rooms = require(script:WaitForChild("Rooms")),
    Decorations = require(script:WaitForChild("Decorations")),
}

RecipeBook.ById = {}
RecipeBook.Order = {}

for categoryId, recipes in pairs(RecipeBook.Categories) do
    for recipeId, recipe in pairs(recipes) do
        recipe.Id = recipe.Id or recipeId
        recipe.Category = recipe.Category or categoryId
        RecipeBook.ById[recipeId] = recipe
        table.insert(RecipeBook.Order, recipeId)
    end
end

table.sort(RecipeBook.Order)

function RecipeBook.Get(recipeId)
    return RecipeBook.ById[recipeId]
end

function RecipeBook.GetPublic()
    local public = {}
    for recipeId, recipe in pairs(RecipeBook.ById) do
        public[recipeId] = {
            Id = recipe.Id,
            DisplayName = recipe.DisplayName,
            Category = recipe.Category,
            OutputType = recipe.OutputType,
            OutputId = recipe.OutputId,
            TimeSeconds = recipe.TimeSeconds,
            Costs = recipe.Costs,
            MasteryRank = recipe.MasteryRank,
            MasteryGate = recipe.MasteryGate,
        }
    end
    return public
end

return RecipeBook
