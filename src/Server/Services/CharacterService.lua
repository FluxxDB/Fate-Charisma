-- Servicees
local Knit = _G.KnitServer
local ServerStorage = game:GetService("ServerStorage")
local PlayersService = game:GetService("Players")
local HttpService = game:GetService("HttpService")


-- Require Modules
local Util = Knit.Util
local RemoteEvent = require(Util.Remote.RemoteEvent)
local Thread = require(Util.Thread)


-- Variables
local Players, Flood
local Rng = Random.new()
local Map = workspace.Map
local Spawns = Map.Spawns:GetChildren()

local Characters = workspace.Entities.Characters
local EntitiesStorage = ServerStorage.Entities
local LoadedTools = {}

local StateType = Enum.HumanoidStateType
local DisabledStates = {
    StateType.Jumping,
    StateType.Swimming,
    StateType.Climbing,
    StateType.Flying,
    StateType.Seated,
    StateType.Ragdoll,
    StateType.StrafingNoPhysics,
    StateType.PlatformStanding,
    StateType.Freefall,
    StateType.GettingUp,
    StateType.FallingDown,
    StateType.Landed
}


-- Create Knit Service
local CharacterService = Knit.CreateService {
    Name = "CharacterService";

    -- Client exposed events
    Client = { Spawn = RemoteEvent.new(); };
}


-- References for faster LookUp
local Client = CharacterService.Client


-- Start
function CharacterService:KnitStart()
    Client.Spawn:Connect(function(Player, Character)
        if not Flood:Check(Player, 1, 5, "SpawnRemote") or not Character then
            return
        end

        local Object = Players[Player]
        if not Object or Object.Character then
            return
        end

        local Model = EntitiesStorage:FindFirstChild("R6")
        if not Model or not Model.PrimaryPart then return end
        Model = Model:Clone()
        Model:SetPrimaryPartCFrame(Spawns[Rng:NextInteger(1, #Spawns)].CFrame)

        Model.ChildAdded:Connect(function(Child)
            if not Child:IsA("Tool") then return end
            local Module = Child:FindFirstChild("Module")
            if not Module or not Module.Value then return end
            print(Object)
            
            Object.Tool = require(Module.Value)
            print(Object.Tool)
        end)
        
        Model.ChildRemoved:Connect(function(Tool)
            if not Tool:IsA("Tool") then return end
            Object.Tool = nil
        end)

        local Humanoid = Model:FindFirstChild("Humanoid")
        for _, State in ipairs(DisabledStates) do
            Humanoid:SetStateEnabled(State, false)
        end

        Humanoid.Died:Connect(function()
            Flood:Check(Player, 1, 5, "SpawnRemote")
            Object.Character = nil
        end)

        Model.Name = Player.Name
        Model.Parent = Characters
        Object.Character = Model
        Player.Character = Model
    end)

    Thread.DelayRepeat(0.1, function()
        for _, Object in pairs(Players) do
            local PositionBuffer = Object.PositionBuffer
            if not PositionBuffer then return end
            
            local Character = Object.Character
            if not Character then continue end

            PositionBuffer:insert(Character.PrimaryPart.CFrame)
        end
    end)
end

-- Initialize
function CharacterService:KnitInit()
    Players = Knit.Services.PlayerService.Players
    Flood = Knit.Services.FloodService

    workspace.ChildAdded:Connect(function(Child)
        if not Child:IsA("Tool") then return end
        Child:Destroy()
    end)
end


return CharacterService