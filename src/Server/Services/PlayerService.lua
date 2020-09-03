-- Servicees
local Knit = _G.KnitServer
local PlayersService = game:GetService("Players")
local HttpService = game:GetService("HttpService")


-- Require Modules
local Util = Knit.Util
local Modules = Knit.Modules

local ProfileService = require(Modules.ProfileService)
local PlayerObject = require(Modules.PlayerObject)
local RemoteEvent = require(Util.Remote.RemoteEvent)


-- Variables
local Flood


-- Create Knit Service
local PlayerService = Knit.CreateService {
    Name = "PlayerService";

    -- Server exposed fields:
    Players = {};

    -- Client exposed events:
    Client = {
        Update = RemoteEvent.new();
    };
}


-- References for faster lookups
local Players = PlayerService.Players
local Client  = PlayerService.Client


-- Set DataStore template:
local GameProfileStore = ProfileService.GetProfileStore(
    "PlayerData",
    {
        Inv = {};
        Equipped = {};

        Options = {
            Ragdolls = true;
            DeathEffects = true;
        };
    }
)

local function LoadData(Player, Object)
    local Profile = GameProfileStore:LoadProfileAsync(
        "Player" .. Player.UserId,
        "ForceLoad"
    )
    
    if Profile ~= nil then
        Profile:ListenToRelease(function()
            -- The profile could've been loaded on another Roblox server:
            Player:Kick("The Profile couldn't be loaded.")
        end)

        if Player:IsDescendantOf(PlayersService) then
            Object.Profile = Profile
        else
            -- Player left before the profile loaded:
            Profile:Release()
        end
    else
        -- The profile couldn't be loaded possibly due to other
        --   Roblox servers trying to load this profile at the same time:
        Player:Kick("The profile couldn't be loaded.")
    end
end


-- Start
function PlayerService:KnitStart()
    Flood = Knit.Services.FloodService
    
    Client.Update:Connect(function(Player)
        local Object = Players[Player]
        if Object and Flood:Check(Player, 1, 2.5, "Update") then 
            return Client.Update:Fire(Player, HttpService:JSONEncode(Object.Profile))
        end

        Object = PlayerObject.new(Player)
        Players[Player] = Object
        
        local success = pcall(function()
            LoadData(Player, Object)
        end)
            
        if not success then
            Player:Kick("The profile couldn't be loaded.")
        end
        
        Client.Update:Fire(
            Player, 
            HttpService:JSONEncode(Object.Profile.Data)
        )
    end)
end

-- Initialize
function PlayerService:KnitInit()

    -- Clean up data when player leaves:
    PlayersService.PlayerRemoving:Connect(function(Player)
        local Object = Players[Player]

        if Object and Object.Profile ~= nil then
            Object.Profile:Release()
        end

        Players[Player] = nil
    end)
end


return PlayerService