local ServicesToLoad = {
    "PlayerService";
    "CharacterService";
    "LatencyService";
    "FloodService";
    "SequenceService";
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Knit"))
Knit.Modules = script.Modules

require(Knit.Util.Component).Auto(Knit.Comopnents)

for _, Name in ipairs(ServicesToLoad) do
    local Module = script.Services:FindFirstChild(Name)

    if Module then
        require(Module)
    end
end

Knit.Start():andThen(function()
    print("[Knit Server]: Started")
end):catch(function(err)
    warn("[Knit Server]: Failed to initialize")
    warn(tostring(err))
end)