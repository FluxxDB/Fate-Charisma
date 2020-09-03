local ControllersToLoad = {
    "PlayerController";
    "CharacterController";
    "InputController";
    "WeaponController";
    "CombatController";
    "LatencyController";
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnitModule = ReplicatedStorage:WaitForChild("Knit")
local Knit = require(KnitModule)
Knit.Modules = script.Modules

for _, Name in ipairs(ControllersToLoad) do
    local Module = script.Controllers:FindFirstChild(Name)

    if Module then
        require(Module)
    end
end

local Components = script:FindFirstChild("Components")
if Components then
    require(Knit.Util.Component).Auto(Components)
end

local Services = KnitModule:WaitForChild("Services")
repeat 
    wait() 
until #Services:GetChildren() > 1

Knit.Start():andThen(function()
    print("[Knit Client]: Started")
end):catch(function(err)
    warn("[Knit Client]: Failed to initialize")
    warn(tostring(err))
end)