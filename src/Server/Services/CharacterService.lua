-- Servicees
local Knit = _G.KnitServer
local PlayersService = game:GetService("Players")


-- Require Modules
local Util = Knit.Util
local RemoteEvent = require(Util.Remote.RemoteEvent)
local FloodCheck = require(Util.Remote.FloodCheck)
local Thread = require(Util.Thread)

-- Variables
local Players
local Rng = Random.new()
local Map = workspace.Maps
local Spawns = Map.Spawns:GetChildren()


-- Create Knit Service
local CharacterService = Knit.CreateService {
    Name = "CharacterService";

    -- Client exposed events
    Client = { Spawn = RemoteEvent.new(1, 5); };
}

-- References for faster LookUp
local Client = CharacterService.Client

-- Functions
function getRandomInPart(part)
    local randomCFrame = part.CFrame * CFrame.new(Rng:NextNumber(-part.Size.X/2,part.Size.X/2), 0, Rng:NextNumber(-part.Size.Z/2,part.Size.Z/2))
    return randomCFrame
end


-- Start
function CharacterService:KnitStart()
    Client.Spawn:Connect(function(Player)
        local Object = Players[Player]
        if not Object or Object.Character then
            return
        end

        
    end)

    Thread.DelayRepeat(0.1, function()
    end)
end

-- Initialize
function CharacterService:KnitInit()
    Players = Knit.Services.PlayerService.Players

    Players.PlayerAdded:Connect(function(Player)    
        Player.CharacterAdded:Connect(function(Character)
            local Humanoid = Character:WaitForChild("Humanoid")
            
            Humanoid.Died:Connect(function()
                FloodCheck(Player, 1, 5, "SpawnRemote")
                Players[Player].Character = nil
            end)
        end)
    end)
end


return CharacterService