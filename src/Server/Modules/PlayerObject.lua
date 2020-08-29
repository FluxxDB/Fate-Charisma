-- Servicees
local Knit = _G.KnitServer

-- Require Modules
local Util = Knit.Util
local RingBuffer = require(Util.Buffers.RingBuffer)

-- Initiate metatable
local PlayerObject = {}
PlayerObject.__index = PlayerObject


-- Constructor method
function PlayerObject.new(Player, Profile)
	local self = {
        _Player = Player;
        Profile = Profile;
        CanPing = true;

        PositionBuffer = RingBuffer.new(50);
        PingBuffer = RingBuffer.new(10, function(Object, Value)
            local Data = Object.Data

            if #Data >= Object.MaxSize then
                Object.Sum = Object.Sum - Data[1]
                table.remove(Data, 1)
            end

            table.insert(Data, Value)
            Object.Sum = (Object.Sum or 0) + Value
            Object.Ping = Object.Sum / #Data
        end);
    }

	return setmetatable(self, PlayerObject)
end


return PlayerObject