-- Services
local Knit = _G.KnitClient
local Controllers = Knit.Controllers
local PlayerController = Controllers.PlayerController

-- Variables
local Player = Knit.Player

local Stagger = {
    Tag = "Stagger";
}
Stagger.__index = Stagger

-- CONSTRUCTOR
function Stagger.new(PlayerInstance)
    local self = setmetatable({
        Player = PlayerInstance
    }, Stagger)
    return self
end

-- OPTIONAL LIFECYCLE HOOKS
function Stagger:Init() --                     -> Called right after constructor
    local Object = self.Player
    if Object ~= Player then return end

    local Character = Object.Character
    if Character and Character.PrimaryPart then
        local Humanoid = Character:FindFirstChild("Humanoid")
        Humanoid.JumpPower = 0
        Humanoid.WalkSpeed = 0
        Humanoid.AutoRotate = false
    end
    PlayerController.SetKey("Stagger")
end

--[[
function Stagger:Deinit() end --                   -> Called right before deconstructor
function Stagger:RenderUpdate(dt)  end --      -> Updates every render step
function Stagger:SteppedUpdate(dt)  end --     -> Updates every physics step
function Stagger:HeartbeatUpdate(dt)  end --   -> Updates every heartbeat
--]]

-- DESTRUCTOR
function Stagger:Destroy()
    local Object = self.Player
    if Object ~= Player then return end

    local Character = Object.Character
    if Character and Character.PrimaryPart then
        local Humanoid = Character:FindFirstChild("Humanoid")
        Humanoid.JumpPower = 50
        Humanoid.WalkSpeed = 16
        Humanoid.AutoRotate = true
    end
    PlayerController.RemoveKey("Stagger")
end

return Stagger