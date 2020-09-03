-- Services
local Knit = _G.KnitClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require Controllers
local Controllers = Knit.Controllers
local Input = Controllers.InputController
local PlayerController = Controllers.PlayerController
local CharacterController = Controllers.CharacterController

-- Require Modules
local Util = Knit.Util
local Thread = require(Util.Thread)


-- Variables
local Player = Knit.Player

local RemoveKey = PlayerController.RemoveKey
local HasKey = PlayerController.HasKey
local SetKey = PlayerController.SetKey

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
            continue
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
    if Attack and not Input.WasAllTapped(0.3, unpack(Attack.Key)) and Sequence.Possible[Index] then
        local Possible = Sequence.Possible[Index]

        if Possible then
            local NewAttack = Possible.Attacks["1"]
            if NewAttack and table.find(NewAttack.Key, Key) and (Input.WasAllTapped(0.3, unpack(NewAttack.Key))) then
                self.Index = 1
                self.Last = nil
                self.CurrSequence = Possible
                Sequence = Possible
                Index = "1"
                Attack = NewAttack
            end
        end
    end

    if Attack and 
        Input.WasAllTapped(0.1, unpack(Attack.Key)) and
        not (self.Index > 1 and not HasKey("CanCombo"))
    then
        self.Last = tick()
        self.Animator:Play(Sequence.Type, Sequence.Name..Index)

        Thread.Delay(Attack.Length + Attack.Cooldown + 0.5, function()
            if not (self.Finished) and self.Last and (tick() - self.Last >= 0.5 + Attack.Length) then
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

        SetKey("Attack", Attack.Cooldown + Attack.Length)
        SetKey("AttackAnimation", Attack.Length)
        return Attack
    end

    if HasKey("CanCombo") then
        Thread.Delay(0.2, function()
            RemoveKey("CanCombo")
        end)
    end
end

return Sequencer