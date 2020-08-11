-- Servicees
local Knit = _G.KnitServer

-- Require Modules
local Util = Knit.Util
local RemoteEvent = require(Util.Remote.RemoteEvent)
local Thread = require(Util.Thread)


-- Create Knit Service
local LatencyService = Knit.CreateService {
    Name = "LatencyService";

    -- Client exposed events
    Client = { Ping = RemoteEvent.new(2); };
}

-- References for faster LookUp
local Client = LatencyService.Client
local Players

-- Start
function LatencyService:KnitStart()
    Client.Ping:Connect(function(Player)
        local Object = Players[Player]
        if not Object then return end

        local Pinged = Object.Pinged
        if not Pinged then return end

        Object.PingBuffer:insert(math.min((tick() - Pinged)*1000, 950))

        Object.Pinged = nil
        Object.CanPing = true
    end)

    Thread.DelayRepeat(1, function()
        for Player, Object in pairs(Players) do
            local Pinged = Object.Pinged
            if Pinged and tick() - Pinged > 13 then
                Player:Kick("Latency too high.")
                continue
            end
            if not Object.CanPing then continue end
            
            Object.Pinged = tick()
            Object.CanPing = false

            self.Client.Ping:Fire(Player, Object.PingBuffer.Ping)
        end
    end)
end

-- Initialize
function LatencyService:KnitInit()
    Players = Knit.Services.PlayerService.Players
end


return LatencyService