-- Servicees
local Knit = _G.KnitServer

-- Variables
local Players

-- Create Knit Service
local FloodService = Knit.CreateService {
    Name = "FloodService";
}


function FloodService:Check(Player, Rate, Time, Identifier, PingCheck)
	local Object = Players[Player]
    if not Object then
        return
    end

    if not Object.Flood then
        local Connection
        Connection = Player.AncestryChanged:Connect(function(Parent)
            if not Parent then
                Connection:Disconnect()
            end
        end)

        Object.Flood = {}
    end
    Object = Object.Flood

	if not Object[Identifier] then
		Object[Identifier] = {}
	end
	Object = Object[Identifier]

	if Rate > Time then
		if Object.Count then
            local TimeElapsed = tick() - Object.StartTime

            if PingCheck then
                TimeElapsed = TimeElapsed - (Players[Player].PingBuffer.Ping or 0)
            end

			if TimeElapsed >= Time then
				Object.Count = 1
				Object.StartTime = tick()
				return true
			else
				Object.Count = Object.Count + 1
				return Object.Count <= Rate
			end
		else
			Object.Count = 1
			Object.StartTime = tick()
			return true
		end
	elseif Rate <= Time then
		if Object.LastTime then
            local TimeElapsed = tick() - Object.LastTime

            if PingCheck then
                TimeElapsed = TimeElapsed - (Players[Player].PingBuffer.Ping or 0)
            end

			if TimeElapsed >= (Time/Rate) then
				Object.LastTime = tick()
				return true
			else
				return false
			end
		else
			Object.LastTime = tick()
			return true
		end
	end
end

-- Initialize
function FloodService:KnitInit()
    Players = Knit.Services.PlayerService.Players
end


return FloodService