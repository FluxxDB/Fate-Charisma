local PingBuffer = {}
PingBuffer.__index = PingBuffer

function PingBuffer.new(Size)
	assert(Size, "Cannot create PingBuffer with nil")
	assert(Size > 0, "Cannot create PingBuffer to Size < 1")

	return setmetatable({
		Data = {};
		Sum = 0;
		MaxSize = Size;
	}, PingBuffer)
end

function PingBuffer.insert(Object, Value)
	local Data = Object.Data

	if #Data >= Object.MaxSize then
		Object.Sum = Object.Sum - Data[1]
		table.remove(Data, 1)
	end

	table.insert(Data, Value)
	Object.Sum = Object.Sum + Value
	Object.Ping = Object.Sum / #Data
end

return PingBuffer