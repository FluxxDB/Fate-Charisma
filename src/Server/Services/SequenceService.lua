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
            not Hit.Parent or
            not Hit.PrimaryPart
        then
            return
        end

        local LAttack = PlayerObject.LastAttack
        local LIndex = PlayerObject.LastIndex
        local Sequence = GetSequence(PlayerObject.Tool.Type, SequenceName)

        if not Sequence or
            not LAttack and (Index > 1 or not Sequence.IsStarter) or
            not (LAttack == Sequence and LIndex == Index - 1)
         then
            return
        end

        if LAttack ~= Sequence then
            local Invalid = true

            for Number, Possible in pairs(LAttack.Possible) do
                if Possible == Sequence and Number == LIndex and Index == 1 then
                    Invalid = false
                end
            end

            if Invalid then return end
        end

        local IsPlayer = PlayerService:GetPlayerFromCharacter(Hit)
        if IsPlayer then -- Player
            print("Valid Magnitude Check")
        else -- NPC
            if Player:DistanceFromCharacter(Hit.PrimaryPart.Position) > 50 then
                return
            end
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