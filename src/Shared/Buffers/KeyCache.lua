local KeyCache = {}
KeyCache.__index = KeyCache

function KeyCache.new()
    return setmetatable({
        _Cache = {}
    }, KeyCache)
end

function KeyCache:_LookForkey(KeyName)
    local Cache = self._Cache
    if next(Cache) == nil then return end
    local Key = Cache[KeyName]
    
    if Key and tick() >= (Key._Duration or math.huge) then
        self:RemoveKey(KeyName)
        return
    end
    
    return Key
end

function KeyCache:RemoveKey(KeyName)
    local Cache = self._Cache
    
    if Cache[KeyName] then
        Cache[KeyName] = nil
    end
end

function KeyCache:GetKey(KeyName)
    local Key = self:_LookForkey(KeyName)
    if not Key then return end
    
    local KeyValue = Key["Value"]
    
    return KeyValue
end

function KeyCache:HasKey(...)
  for _, KeyName in ipairs({...}) do
    if not self:_LookForkey(KeyName) then
      return false
    end
  end
  
  return true
end

function KeyCache:SetKey(KeyName, Value, Duration)
    local start = tick()
    local Cache = self._Cache
    local Key = Cache[KeyName]
    
    if Key then
        Key["Value"] = Value
    else
        Key = {
            ["Value"] = Value
        }
        Cache[KeyName] = Key
    end
    
    if Duration then
        Key._Duration = start + Duration
    end
    
    return true
end

return KeyCache