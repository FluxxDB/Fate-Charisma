-- Servicees
local Knit = _G.KnitServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

-- Require Modules
local Util = Knit.Util
local RemoteEvent = require(Util.Remote.RemoteEvent)
local Sequencer = require(Util.Sequencer)

-- Create Knit Service
local SequenceService = Knit.CreateService {
    Name = "SequenceService";

    -- Client exposed events:
    Client = { Hit = RemoteEvent.new(2, 1); };
}

-- References for faster LookUp
local SequencesFolder = ReplicatedStorage.Assets.Sequences
local Sequences = {}
local Players

-- Functions
function GetSequence(Type, Name)
    local SequenceType = SequencesFolder:FindFirstChild(Type)
    if not SequenceType then
        return nil
    end

    local SequenceName = Type .. Name
    if Sequences[SequenceName] ~= nil then
        return Sequences[SequenceName]
    end
    
    local SequenceFolder = SequenceType:FindFirstChild(Name)
    if not SequenceFolder then
        return nil
    end

    local Info = SequenceFolder:FindFirstChild("Info")
    if not Info then
        return nil
    end

    Sequences[SequenceName] = require(Info)
    return Sequences[SequenceName]
end

-- Start
function SequenceService:KnitStart()
    SequenceService.Client.Hit:Connect(function(Player, Hit, SequenceName, Index)
        local PlayerObject = Players[Player]
        if not PlayerObject or
            not PlayerObject.Tool or
            not Hit or
            not Hit.Parent 
        then 
            return 
        end

        local Sequence = GetSequence(PlayerObject.Tool.Type,SequenceName)
        if not Sequence or 
            PlayerObject.LastAttack and (
            Sequence[Index]
            )
            
        then
            return
        end

        local IsPlayer = PlayerService:GetPlayerFromCharacter(Hit)
        if IsPlayer then -- Player
            print("Valid Magnitude Check")
        else -- NPC
            print("Basic Magnitude Check")
        end

        PlayerObject.LastAttack = Sequence
        PlayerObject.LastIndex = Index
    end)
end

-- Initialize
function SequenceService:KnitInit()
    Players = Knit.Services.PlayerService.Players
end

return SequenceService