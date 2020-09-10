-- Servicees
local Knit = _G.KnitServer
local CollectionService = game:GetService("CollectionService")
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
local function GetSequence(Type, Name)
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


function StartCombo(Player, SequenceName, Index)
    Index = tonumber(Index)

    local PlayerObject = Players[Player]
    if not PlayerObject or 
        not Index or
        PlayerObject:HasKey("Attack") or
        PlayerObject:HasKey("Stagger")
    then
        return
    end
    
    local Tool = PlayerObject.Tool
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
        LAttack and LAttack == Sequence and LIndex ~= Index - 1 or
        Index > 1 and not PlayerObject:HasKey("CanCombo")
     then
        return
    end

    if LAttack and LAttack ~= Sequence and LAttack.Possible then
        local Invalid = true

        for Number, Possible in pairs(LAttack.Possible) do
            if Possible == Sequence and 
                Number - 1 == LIndex and 
                Index == 1 and
                PlayerObject:HasKey("CanCombo")
            then
                Invalid = false
            end
        end
        
        if Invalid then return end
    end
    
    PlayerObject:RemoveKey("CanCombo")

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

    Thread.Delay(Length + 0.55 + Ping, function()
        local Attack = PlayerObject.Attack
        if not Attack or Move ~= Attack.Move then return end

        if not PlayerObject.Finished then
            PlayerObject:RemoveKey("CanCombo")
            PlayerObject.LastAttack = nil
            PlayerObject.LastIndex = nil
            PlayerObject.Attack = nil
        end
    end)

    if Sequence.AttackCount == Index then
        PlayerObject:RemoveKey("CanCombo")
        PlayerObject.Finished = true
        PlayerObject.LastAttack = nil
        PlayerObject.LastIndex = nil
    else
        PlayerObject.Finished = false
    end
end

function HitCheck(Player, Humanoids)
    local PlayerObject = Players[Player]
    if not PlayerObject or
        not PlayerObject.Tool or
        PlayerObject:HasKey("Stagger")
    then
        return
    end

    local Attack = PlayerObject.Attack
    if not Attack or
        Attack.Ended
    then
        return 
    end
    
    local Ping = PlayerObject.PingBuffer.Ping
    local Hits = Attack.Hits
    local Move = Attack.Move
    local MaxHits = Move.MaxHits
    local Damage = Move.Damage
    local Tags = Move.Tags

    local Parts = {}
    
    local DistancePing = math.clamp(math.ceil(Ping * 10 - 1), 1, 9)
    local LerpPosition = math.fmod(Ping, 0.1) * 10
    
    for _, Hit in ipairs(Humanoids) do
        if Hits[Hit] and Hits[Hit] >= MaxHits then
            continue
        end

        local Invalid = true
        local IsPlayer = PlayerService:GetPlayerFromCharacter(Hit)

        if IsPlayer then -- Player
            local Victim = Players[IsPlayer]
            if not Victim or Victim:HasKey("iFrame") then
                continue
            end

            local Data = Victim.PostionBuffer.Data
            if not Data or #Data < 10 then continue end
            
            local P0 = Data[DistancePing]
            local P1 = Data[DistancePing + 1]

            local Part = Instance.new("Part")
            Part.Size = Vector3.new(4, 5, 1)
            Part.CFrame = P1:Lerp(P0, LerpPosition) * CFrame.new(0, -0.5, 0)
            Part.CanCollide = false
            Part.Anchored = true
            Part.Parent = Hit

            Hits[Hit] = (Hits[Hit] or 0) + 1
            continue
        else -- NPC
            Invalid = Player:DistanceFromCharacter(Hit.RootPart.Position) > 50
        end

        if Invalid then continue end
        
        for Tag, Length in pairs(Tags) do
            local Delay = Length + Ping
            CollectionService:AddTag(Hit, Tag)
            PlayerObject:SetKey(Hit, Delay * 0.95)

            Thread.Delay(Delay, function()
                if PlayerObject:HasKey(Hit) then return end
                CollectionService:RemoveTag(Hit, Tag)
            end)
        end

        Hit:TakeDamage(Damage)
        Hits[Hit] = (Hits[Hit] or 0) + 1
        PlayerObject:SetKey("CanCombo")
    end
end


-- Start
function SequenceService:KnitStart()
    Players = Knit.Services.PlayerService.Players

    local Client = SequenceService.Client
    Client.Start:Connect(StartCombo)
    Client.Hit:Connect(HitCheck)
end

return SequenceService