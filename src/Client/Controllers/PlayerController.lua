-- Servicees
local Knit = _G.KnitClient
local HttpService = game:GetService("HttpService")


-- Variables
local Keys = {}
local PlayerService
local CharacterService


-- Create Knit controller
local PlayerController = Knit.CreateController {
    Name = "PlayerController";
    Keys = Keys;
}

-- Functions
local function LookForkey(KeyName)
    if next(Keys) == nil then return end
    local Key = Keys[KeyName]
    
    if Key and tick() >= (Key._Duration or math.huge) then
        return PlayerController.RemoveKey(KeyName)
    end
    
    return Key
end

function PlayerController.RemoveKey(KeyName)
    if Keys[KeyName] then
        Keys[KeyName] = nil
    end
end

function PlayerController.HasKey(KeyName)
    return LookForkey(KeyName)
end

function PlayerController.SetKey(KeyName, Duration)
    local start = tick()
    local Key = Keys[KeyName]
    
    if not Key then
        Key = {}
        Keys[KeyName] = Key
    end
    
    if Duration then
        Key._Duration = start + Duration
    end
end

-- Start
function PlayerController:KnitStart()
    PlayerService = Knit.GetService("PlayerService")
    CharacterService = Knit.GetService("CharacterService")

    PlayerService.Update:Connect(function(Data)
        PlayerService.Data = HttpService:JSONDecode(Data)
    end)

    PlayerService.Update:Fire()
    CharacterService.Spawn:Fire("R6")
end

return PlayerController