-- Servicees
local Knit = _G.KnitServer

-- Require Modules
local Util = Knit.Util
local PingBuffer = require(Util.PingBuffer)
local RingBuffer = require(Util.RingBuffer)

-- Initiate metatable
local PlayerObject = {}
PlayerObject.__index = PlayerObject


-- Constructor method
function PlayerObject.new(Player, Profile)
	local self = {
        _Player = Player;
        Data = Profile;

        PositionBuffer = RingBuffer.new(30);
        PingBuffer = PingBuffer.new(10);

        CanPing = true;
        Ping = 950;
    }

	return setmetatable(self, PlayerObject)
end


return PlayerObject