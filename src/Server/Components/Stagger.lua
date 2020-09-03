-- Services
local Knit = _G.KnitServer
local Players = Knit.Services.PlayerService.Players

local Stagger = {
    Tag = "Stagger";
}
Stagger.__index = Stagger

-- CONSTRUCTOR
function Stagger.new(Player)
    local self = setmetatable({
        PlayerObject = Players[Player];
    }, Stagger)
    return self
end

-- OPTIONAL LIFECYCLE HOOKS
function Stagger:Init() --                     -> Called right after constructor
    local Object = self.PlayerObject
    local Character = Object.Character
    if Character and Character.PrimaryPart then
        Character.PrimaryPart:SetNetworkOwner(nil)
    end
    Object:SetKey("Stagger")
end

--[[
function Stagger:Deinit() end --                   -> Called right before deconstructor
function Stagger:RenderUpdate(dt)  end --      -> Updates every render step
function Stagger:SteppedUpdate(dt)  end --     -> Updates every physics step
function Stagger:HeartbeatUpdate(dt)  end --   -> Updates every heartbeat
--]]

-- DESTRUCTOR
function Stagger:Destroy()
    local Object = self.PlayerObject
    local Character = Object.Character
    if Character and Character.PrimaryPart then
        Character.PrimaryPart:SetNetworkOwner(Object._Player)
    end
    Object:RemoveKey("Stagger")
end

return Stagger