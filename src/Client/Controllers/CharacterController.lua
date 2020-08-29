-- Servicees
local Knit = _G.KnitClient


-- Require Modules
local Util = Knit.Util
local Modules = Knit.Modules
local Thread = require(Util.Thread)
local AnimatorClass = require(Modules.Animator)


-- Variables
local Player = Knit.Player
local Camera = workspace.CurrentCamera
local EntitiesFolder =  workspace:WaitForChild("Entities")

local Models = {}


-- Create Knit controller
local CharacterController = Knit.CreateController {
    Name = "CharacterController";
}


function RenderVisual(Model, IsPlayer)
    if Models[Model] then return end

    local Humanoid = Model:FindFirstChild("Humanoid")
    if not Humanoid then return end
    
    local HRP = Humanoid.RootPart
    if not HRP or 
    (Player.Character and (Player.Character.PrimaryPart.Position - HRP.Position).Magnitude or 
    (Camera.CFrame.Position - HRP.Position).Magnitude) >= 1500 then
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

    Model.AncestryChanged:Connect(function()
        Models[Model] = nil
    end)
end


-- Start
function CharacterController:KnitStart()
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

    Thread.DelayRepeat(1/14, function()
        for Model, Animator in pairs(Models) do
            if type(Model) == "boolean" then continue end
            Animator:Update()
        end
    end)
end

-- Init
function CharacterController:KnitInit()
    Player.CharacterAdded:Connect(function(Character)
        while true do
            local Tool = Character:FindFirstChildOfClass("Tool")
            if not Tool then break end
            
            Tool.Parent = Player.Backpack
        end

        RenderVisual(Character, false)
    end)
end

return CharacterController