-- Servicees
local Knit = _G.KnitClient

-- Require Controllers
local Input = Knit.Controllers.InputController
local CharacterController = Knit.Controllers.CharacterController

-- Require Modules
local Modules = Knit.Modules
local Sequencer = require(Modules.Sequencer)

-- Variables
local Player = Knit.Player

-- Create Knit controller
local CombatController = Knit.CreateController {
    Name = "CombatController";
}

-- Functions
local function Dash()
    local Character = Player.Character
    local Animator = CharacterController:Get(Character)
    if not Animator then return end

    local Direction = Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Character.Humanoid.MoveDirection)
    if Direction.Z < 0 then
        Animator:Play("Actions", "DashForward")
    elseif Direction.Z > 0 then
        Animator:Play("Actions", "DashBackward")
    end
end

-- Start
function CombatController:KnitStart()
    wait(5)
    local Sword = Sequencer.new("Sword", "Basic", "RCombo")

    Input.Began:Connect(function(InputObject, Key)
        if not (Key or Player.Character) then return end
        if Input.IsDown("V") and Input.AreAnyDown("W", "S") then
            return Dash()
        end

        local Sequence, Index = Sword:Progress(Key)
    end)
end

-- Initialize
function CombatController:KnitInit()

end

return CombatController