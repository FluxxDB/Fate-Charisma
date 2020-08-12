-- Servicees
local Knit = _G.KnitClient
local LatencyService

-- Create Knit controller
local LatencyController = Knit.CreateController {
    Name = "LatencyController";
    CurrentPing = 0;
}

-- Start
function LatencyController:KnitStart()
    LatencyService.Ping._remote.OnClientEvent:Connect(function(Ping)
        LatencyService.Ping:Fire()
        print(string.format("%s's ping is %.2fms", Knit.Player.Name, Ping or 0))
    end)
end

-- Initialize
function LatencyController:KnitInit()
    LatencyService = Knit.GetService("LatencyService")
end

return LatencyController