local ControllersToLoad = {
    "PlayerController";
    "CharacterController";
    "InputController";
    "WeaponController";
    "CombatController";
    "LatencyController";
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Knit"))
Knit.Modules = script.Modules

require(Knit.Util.Component).Auto(Knit.Comopnents)

for _, Name in ipairs(ControllersToLoad) do
    local Module = script.Controllers:FindFirstChild(Name)

    if Module then
        require(Module)
    end
end

Knit.Start():andThen(function()
    print("[Knit Client]: Started")
end):catch(function(err)
    warn("[Knit Client]: Failed to initialize")
    warn(tostring(err))
end)