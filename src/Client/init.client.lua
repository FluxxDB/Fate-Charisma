local ControllersToLoad = {
    "RegionController";
    "LatencyController";
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Knit"))
Knit.Modules = script.Modules

for _, Name in ipairs(ControllersToLoad) do
    local Module = script.Controllers:FindFirstChild(Name)

    if Module then
        require(Module)
    end
end

Knit.Start():andThen(function()
    print("[Knit Client]: Started")
    Knit.GetService("PlayerService").Ready:Fire()
    print("Requested Character.")
end):catch(function(err)
    warn("[Knit Client]: Failed to initialize")
    warn(tostring(err))
end)