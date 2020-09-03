-- Servicees
local Knit = _G.KnitServer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

-- Require Modules
local Util = Knit.Util
local RemoteEvent = require(Util.Remote.RemoteEvent)
local Thread = require(Util.Thread)

-- Create Knit Service
local SequenceService = Knit.CreateService {
    Name = "SequenceService";

    -- Client exposed events:
    Client = { 
        Start = RemoteEvent.new();
        Hit = RemoteEvent.new(); 
    };
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
    SequenceService.Client.Start:Connect(function(Player, SequenceName, Index)
        Index = tonumber(Index)

        local PlayerObject = Players[Player]
        if not PlayerObject or 
            not Index or
            PlayerObject:HasKey("Attack")
        then
            return
        end
        
        local Tool = PlayerObject.Tool
        print(PlayerObject, Tool)
        if not Tool or
            not table.find(Tool.Sequences, SequenceName)
        then
            return
        end

        local LAttack = PlayerObject.LastAttack
        local LIndex = PlayerObject.LastIndex
        local Sequence = GetSequence(Tool.Type, SequenceName)

        if not Sequence or
            not LAttack and (Index > 1 or not Sequence.IsStarter) or
            LAttack and LAttack == Sequence and LIndex ~= Index - 1
         then
            return
        end

        if LAttack and LAttack ~= Sequence and LAttack.Possible then
            local Invalid = true
    
            for Number, Possible in pairs(LAttack.Possible) do
                if Possible == Sequence and Number - 1 == LIndex and Index == 1 then
                    Invalid = false
                end
            end
            
            if Invalid then return end
        end
        

        local Ping = PlayerObject.PingBuffer.Ping
        local Move = Sequence.Attacks[tostring(Index)]
        local Length = Move.Length + Move.Cooldown
        PlayerObject:SetKey("Attack", Length - Ping)

        PlayerObject.LastAttack = Sequence
        PlayerObject.LastIndex = Index
        PlayerObject.Attack = {
            Move = Move;
            Ended = false;
            Hits = {};
        }

        Thread.Delay(Length + Ping, function()
            local Attack = PlayerObject.Attack
            if not Attack or Move ~= Attack.Move then return end
            Attack.Ended = true
        end)

        Thread.Delay(Length + 0.6 + Ping, function()
            local Attack = PlayerObject.Attack
            if not Attack or Move ~= Attack.Move then return end

            if not PlayerObject.Finished then
                PlayerObject.LastAttack = nil
                PlayerObject.LastIndex = nil
                PlayerObject.Attack = nil
            end
        end)

        if Sequence.AttackCount == Index then
            PlayerObject.Finished = true
            PlayerObject.LastAttack = nil
            PlayerObject.LastIndex = nil
        else
            PlayerObject.Finished = false
        end
    end)
    
    SequenceService.Client.Hit:Connect(function(Player, Humanoids)
        local PlayerObject = Players[Player]
        if not PlayerObject or
            not PlayerObject.Tool
        then
            return
        end

        local Attack = PlayerObject.Attack
        if not Attack or
            Attack.Ended
        then
            return 
        end
        
        local MaxHits = Attack.Move.MaxHits
        local Damage = Attack.Move.Damage
        local Hits = Attack.Hits
        
        for _, Hit in ipairs(Humanoids) do
            if Hits[Hit] and Hits[Hit] >= MaxHits then
                continue
            end

            local Invalid = true
            local IsPlayer = PlayerService:GetPlayerFromCharacter(Hit)

            if IsPlayer then -- Player
                Invalid = false
            else -- NPC
                Invalid = Player:DistanceFromCharacter(Hit.RootPart.Position) > 50
            end

            if Invalid then continue end
            Hit:TakeDamage(Damage)
            Hits[Hit] = (Hits[Hit] or 0) + 1
        end
    end)
end

-- Initialize
function SequenceService:KnitInit()
    Players = Knit.Services.PlayerService.Players
end

return SequenceService