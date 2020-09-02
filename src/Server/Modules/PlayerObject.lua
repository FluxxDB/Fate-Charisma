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
        Keys = {};

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

function PlayerObject:_LookForkey(KeyName)
    local Keys = self.Keys
    if next(Keys) == nil then return end
    local Key = Keys[KeyName]
    
    if Key and tick() >= (Key._Duration or math.huge) then
        return self:RemoveKey(KeyName)
    end
    
    return Key
end

function PlayerObject:RemoveKey(KeyName)
    local Keys = self.Keys
    if Keys[KeyName] then
        Keys[KeyName] = nil
    end
end

function PlayerObject:HasKey(KeyName)
    return self:_LookForkey(KeyName)
end

function PlayerObject:SetKey(KeyName, Duration)
    local start = tick()
    local Keys = self.Keys
    local Key = Keys[KeyName]
    
    if not Key then
        Key = {}
        Keys[KeyName] = Key
    end
    
    if Duration then
        Key._Duration = start + Duration
    end
end

return PlayerObject