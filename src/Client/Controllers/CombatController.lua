-- Servicees
local Knit = _G.KnitClient
local Controllers = Knit.Controllers
local Input
local CharacterController
local PlayerController

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
    Input.Began:Connect(function(InputObject, Key)
        if not (Key or Player.Character) then return end
        if Input.IsDown("V") and Input.AreAnyDown("W", "S") then
            return Dash()
        end
        
        if not PlayerController.Weapon or PlayerController:HasKey("Attack") then return end
        local Attack = PlayerController.Weapon:Progress(Key)
        if not Attack then return end
        PlayerController:SetKey("Attack", Attack.Cooldown + Attack.Length)
    end)
end

-- Initialize
function CombatController:KnitInit()
    Input = Controllers.InputController
    CharacterController = Controllers.CharacterController
    PlayerController = Controllers.PlayerController
end

return CombatController