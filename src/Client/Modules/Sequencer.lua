-- Services
local Knit = _G.KnitClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Controllers
local Input = Knit.Controllers.InputController
local CharacterController = Knit.Controllers.CharacterController

-- Require Modules
local Util = Knit.Util
local Thread = require(Util.Thread)


-- Variables
local Player = Knit.Player
local Assets = ReplicatedStorage:WaitForChild("Assets")
local SequencesFolder = Assets:WaitForChild("Sequences")


-- Class
local Sequencer = {}
Sequencer.__index = Sequencer


function Sequencer.new(Type, ...)
    local self = setmetatable({
        Index = 1,
        Sequences = {},
        Finished = false,
        Animator = CharacterController:Get(Player.Character),
    }, Sequencer)

    self:Update(Type, ...)
	return self
end

function Sequencer:Update(Type, ...)
    local Sequences = { ... }
    local SequenceType = SequencesFolder:FindFirstChild(Type)
    if not SequenceType then return end

    for _, Name in pairs(Sequences) do
        local SequenceName = Type .. Name
        if self.Sequences[SequenceName] ~= nil 
          or not self.Animator
        then
            warn("Sequence either exists or animator stopped working")
            continue
        end

        local SequenceFolder = SequenceType:FindFirstChild(Name)
        if not SequenceFolder then
            warn("Sequence folder not found")
            continue
        end

        local Info = SequenceFolder:FindFirstChild("Info")
        if not Info then 
            warn("Sequence Info not found")
            continue
        end

        self.Animator:LoadAnimation(SequenceFolder, "Sequences")
        self.Sequences[SequenceName] = require(Info)
    end
end

function Sequencer:GetSequence(Key)
    local NewSequence
    for _, Sequence in pairs(self.Sequences) do
        if self.CurrSequence or not Sequence.IsStarter then
            return
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
    if not self.Animator then return end

    local Sequence = self.CurrSequence
    if not Sequence then
        Sequence = self:GetSequence(Key)
        if not Sequence then
            return
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
        local Animator = CharacterController:Get(Knit.Player.Character)
        if not Animator then return end
        Animator:Play(Sequence.Type, Sequence.Name..Index)

        Thread.Delay(1.5, function()
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