-- Servicees
local Knit = _G.KnitServer
local PlayersService = game:GetService("Players")

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
        Ready = RemoteEvent.new(1, math.huge);
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

local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync(
        "Player" .. player.UserId,
        "ForceLoad"
    )
    if profile ~= nil then
        profile:ListenToRelease(function()
            Players[player] = nil
            -- The profile could've been loaded on another Roblox server:
            player:Kick("The profile couldn't be loaded.")
        end)

        if player:IsDescendantOf(PlayersService) then
            Players[player] = PlayerObject.new(player, profile)
        else
            -- Player left before the profile loaded:
            profile:Release()
        end
    else
        -- The profile couldn't be loaded possibly due to other
        --   Roblox servers trying to load this profile at the same time:
        player:Kick("The profile couldn't be loaded.")
    end
end


-- Start
function PlayerService:KnitStart()
    Client.Ready:Connect(function(Player)
        if Players[Player] then return end
        Players[Player] = {}
        PlayerAdded(Player)
    end)
end

-- Initialize
function PlayerService:KnitInit()
    Flood = Knit.Services.FloodService

    -- Clean up data when player leaves:
    game:GetService("Players").PlayerRemoving:Connect(function(Player)
        local Object = Players[Player]

        if Object and Object.Profile ~= nil then
            Object.Profile:Release()
        end

        Players[Player] = nil
    end)
end


return PlayerService