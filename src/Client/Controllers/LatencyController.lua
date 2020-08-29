-- Servicees
local Knit = _G.KnitClient
local LatencyService

-- Create Knit controller
local LatencyController = Knit.CreateController {
    Name = "LatencyController";
    Ping = 0;
}

-- Start
function LatencyController:KnitStart()
    LatencyService.Ping:Connect(function(Ping)
        LatencyService.Ping:Fire()
        LatencyController.Ping = Ping or 1
        -- print(string.format("%s's ping is %.2fms", Knit.Player.Name, (Ping or 1) * 1000))
    end)
end

-- Initialize
function LatencyController:KnitInit()
    LatencyService = Knit.GetService("LatencyService")
end

return LatencyController