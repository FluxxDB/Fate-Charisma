local RingBuffer = {}
RingBuffer.__index = RingBuffer

function RingBuffer.new(Size)
	assert(Size, "Cannot create RingBuffer with nil")
	assert(Size > 0, "Cannot create RingBuffer to Size < 1")

	return setmetatable({
		Data = {};
		Size = 0;
		MaxSize = Size;
	}, RingBuffer)
end

function RingBuffer.insert(Object, Value)
	if #Object.Data >= Object.MaxSize then
		table.remove(Object.Data, 1)
	end

	table.insert(Object.Data, Value)
	Object.Size = #Object.Data
end

return RingBuffer