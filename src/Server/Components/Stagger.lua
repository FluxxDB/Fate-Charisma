-- Services
local Knit = _G.KnitServer
local PlayerService = game:GetService("Players")
local Players = Knit.Services.PlayerService.Players

local Stagger = {
    Tag = "Stagger";
}
Stagger.__index = Stagger

-- CONSTRUCTOR
function Stagger.new(Humanoid)    
    local self = setmetatable({
        Object = Players[PlayerService:GetPlayerFromCharacter(Humanoid.Parent)];
        Humanoid = Humanoid;
    }, Stagger)
    
    return self
end

-- OPTIONAL LIFECYCLE HOOKS
function Stagger:Init() --                     -> Called right after constructor
    local Object = self.Object
    if not Object then return end

    local Humanoid = self.Humanoid
    if Humanoid and Humanoid.RootPart and Humanoid.Parent then
        Humanoid.JumpPower = 0
        Humanoid.WalkSpeed = 5
        Humanoid.AutoRotate = false
        Humanoid.RootPart:SetNetworkOwner(nil)
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
    local Object = self.Object
    if not Object then return end
    
    local Humanoid = self.Humanoid
    if Humanoid and Humanoid.RootPart and Humanoid.Parent then
        Humanoid.JumpPower = 50
        Humanoid.WalkSpeed = 16
        Humanoid.AutoRotate = true
        Humanoid.RootPart:SetNetworkOwner(Object._Player)
    end

    Object:RemoveKey("Stagger")
end

return Stagger