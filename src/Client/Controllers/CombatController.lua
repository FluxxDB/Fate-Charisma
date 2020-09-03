-- Servicees
local Knit = _G.KnitClient
local Controllers = Knit.Controllers
local Input
local CharacterController
local PlayerController

-- Variables
local Player = Knit.Player
local SetKey
local HasKey

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
    
    SetKey("DashAnimation", 0.5)
    SetKey("Dash", 2)
end

-- Start
function CombatController:KnitStart()
    Input.Began:Connect(function(_, Key)
        if not (Key or Player.Character) then return end
        if HasKey("AttackAnimation") then return end

        if Input.IsDown("V") and Input.AreAnyDown("W", "S") and not HasKey("Dash") then
            return Dash()
        end
        
        if not PlayerController.Weapon or HasKey("Attack") or HasKey("DashAnimation") then return end
        PlayerController.Weapon:Progress(Key)
    end)
end

-- Initialize
function CombatController:KnitInit()
    Input = Controllers.InputController
    CharacterController = Controllers.CharacterController
    PlayerController = Controllers.PlayerController

    SetKey = PlayerController.SetKey
    HasKey = PlayerController.HasKey
end

return CombatController