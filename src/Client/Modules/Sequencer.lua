-- Services
local Knit = _G.KnitClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Controllers
local Input = Knit.Controllers.InputController

-- Variables
local SequencesFolder = ReplicatedStorage.Assets.Sequences
local Sequencer = {}
Sequencer.__index = Sequencer

-- Functions
function Sequencer.new(Type, ...)
    local self = setmetatable({
        Index = 1,
        Sequences = {},
        Finished = false
    }, Sequencer)
    
    self:Update(Type, ...)
	return self
end

function Sequencer:Update(Type, ...)
    local Sequences = { ... }
    local SequenceType = SequencesFolder:FindFirstChild(Type)
    if not SequenceType then
        return nil
    end
    for _, Name in pairs(Sequences) do
        local SequenceName = Type .. Name
        if self.Sequences[SequenceName] ~= nil then
        --or (not (PlayerData.Animator)) 
            return nil
        end
        
        local SequenceFolder = SequenceType:FindFirstChild(Name)
        if not SequenceFolder then
            return nil
        end

        local Info = SequenceFolder:FindFirstChild("Info")
        if not Info then
            return nil
        end
        --PlayerData.Animator:LoadAnimations(SequenceFolder, SequenceName)
        self.Sequences[SequenceName] = require(Info)
    end
end

function Sequencer:GetSequence(Key)
    local NewSequence
    for _, Sequence in pairs(self.Sequences) do
        if self.CurrSequence or not Sequence.IsStarter then
            return nil
        end

        local Attack = Sequence.Attacks["1"]
        if Attack and table.find(Attack.Key, Key) and Input.WasAllTapped(0.3, unpack(Attack.Key)) then
            NewSequence = Sequence
            self.Index = 1
            self.CurrSequence = Sequence
        end
    end
    return NewSequence
end

function Sequencer:Progress(Key)
    --[[
    if not (PlayerData.Animator)) or (not (PlayerData.Weapon)) or (Cache:HasAnyKey(unpack(ValidArgs)) then
        return nil;
    end;
    --]]
    local Sequence = self.CurrSequence
    if not Sequence then
        Sequence = self:GetSequence(Key)
        if not Sequence then
            return nil
        end
    end

    local Index = tostring(self.Index)
    local Attack = Sequence.Attacks[Index]
    if Attack and not Input.WasAllTapped(0.3, unpack(Attack.Key)) and Sequence.Possible[Index] ~= nil then
        local Possible = Sequence.Possible[Index]
        
        if Possible then
            local NewAttack = Possible.Attacks["1"]
            if NewAttack and table.find(NewAttack.Key, Key) and (Input.WasAllTapped(0.3, unpack(NewAttack.Key))) then
                self.Index = 1
                self.Last = nil
                self.CurrSequence = Possible
                Attack = NewAttack
            end
        end
    end

    if Attack and Input.WasAllTapped(0.3, unpack(Attack.Key)) then
        
        self.Last = tick()
        local Length = Attack.Length
        
        -- TS.map_forEach(PlayerData.Weapon.Hitboxes, function(Hitbox)
        --     Hitbox:HitStop()
        --     Hitbox:HitStart()
        --     delay(Length, function()
        --         if tostring(self.Index - 1) == Index then
        --             Hitbox:HitStop()
        --         end
        --     end)
        -- end)

        delay(1.5, function()
            if not (self.Finished) and (tick() - self.Last >= 1) then
                self.CurrSequence = nil
                self.Last = nil
            end
        end)

        self.Index = self.Index + 1
        if Sequence.AttackCount == self.Index - 1 then
            self.Finished = true
            self.CurrSequence = nil
            self.Last = nil
        else
            self.Finished = false
        end
        return Sequence, Index
    end
end

return Sequencer