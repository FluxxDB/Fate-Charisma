-- Servicees
local Knit = _G.KnitClient


-- Require Modules
local Util = Knit.Util
local Modules = Knit.Modules
local AnimatorClass = require(Modules.Animator)
local Thread = require(Util.Thread)
local Signal = require(Util.Signal)


-- Variables
local Player = Knit.Player
local Camera = workspace:WaitForChild("Camera")
local CameraType = Enum.CameraType.Custom

local EntitiesFolder =  workspace:WaitForChild("Entities")
local CharacterAdded = Signal.new()

local Models = {}


-- Create Knit controller
local CharacterController = Knit.CreateController {
    Name = "CharacterController";
    CharacterAdded = CharacterAdded;
}


function RenderVisual(Model, IsPlayer)
    if Models[Model] then return end

    local Humanoid = Model:FindFirstChild("Humanoid")
    if not Humanoid then return end
    
    local HRP = Humanoid.RootPart
    if not HRP or 
        (Player.Character and (Player.Character.PrimaryPart.Position - HRP.Position).Magnitude or
        (Camera.CFrame.Position - HRP.Position).Magnitude) >= 1500
    then
        return
    end
    
    local Info = Model:FindFirstChild("Info")
    if not Info then return end
    
    local Visual = Info:FindFirstChild("Visual")
    if not Visual or not Visual.Value then return end
    Visual = Visual.Value:Clone()
    
    for _, Parts in ipairs(Visual:GetChildren()) do
        Parts.Parent = Model
    end
    Visual:Destroy()
    
    local IsR6 = HRP:FindFirstChild("RootJoint")
    if IsR6 then
        local Part1 = IsR6:FindFirstChild("Part1")
        Part1 = Model:FindFirstChild(Part1.Value)

        Humanoid.HipHeight = 0

        IsR6.Part0 = HRP
        IsR6.Part1 = Part1
    else
        local LowerTorso = Model:FindFirstChild("LowerTorso")
        local Joint = LowerTorso:FindFirstChild("Root")

        Joint.Part0 = HRP
        Joint.Part1 = LowerTorso
    end
    
    if IsPlayer then
        Models[Model] = true
    else
        Models[Model] = AnimatorClass.new(Model)
    end
    
    CharacterAdded:Fire(Model)

    Model.AncestryChanged:Connect(function()
        Models[Model] = nil
    end)
end

function CharacterController:Get(Model)
    return Models[Model]
end


-- Start
function CharacterController:KnitStart()
    local CharacterService = Knit.GetService("CharacterService")

    local Characters = EntitiesFolder:WaitForChild("Characters")
    local Npcs = EntitiesFolder:WaitForChild("Npcs")
    local Mobs = EntitiesFolder:WaitForChild("Mobs")

    local function LoopThroughEntities(Folder, IsPlayer)
        for _, Entity in ipairs(Folder:GetChildren()) do
            RenderVisual(Entity, IsPlayer)
        end
    end

    Thread.DelayRepeat(1, function()
        LoopThroughEntities(Characters, true)
        LoopThroughEntities(Npcs, false)
        LoopThroughEntities(Mobs, false)
    end)

    Thread.DelayRepeat(1/20, function()
        for _, Animator in pairs(Models) do
            if type(Animator) == "boolean" then continue end
            Animator:Update()
        end
    end)

    Player.CharacterAdded:Connect(function(Character)
        local Humanoid = Character:WaitForChild("Humanoid")
        Camera.CameraSubject = Humanoid
        Camera.CameraType = CameraType
        
        while true do
            local Tool = Character:FindFirstChildOfClass("Tool")
            if not Tool then break end
            
            Tool.Parent = Player.Backpack
        end

        RenderVisual(Character, false)

        Humanoid.Died:Connect(function()
            Thread.Delay(6, function()
                CharacterService.Spawn:Fire("R6")
            end)
        end)
    end)
end

return CharacterController