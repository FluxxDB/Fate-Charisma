-- Servicees
local Knit = _G.KnitClient

-- Require Controllers
local Input = Knit.Controllers.InputController

-- Require Modules
local Modules = Knit.Modules
local Sequencer = require(Modules.Sequencer)

-- Create Knit controller
local CombatController = Knit.CreateController {
    Name = "CombatController";
}

-- Start
function CombatController:KnitStart()
    wait(5)
    local Sword = Sequencer.new("Sword", "Basic", "RCombo")

    Input.Began:Connect(function(InputObject, Key)
        if not Key then return end

        local Sequence, Index = Sword:Progress(Key)
    end)
end

-- Initialize
function CombatController:KnitInit()

end

return CombatController