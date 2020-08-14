-- Servicees
local Knit = _G.KnitServer
local PlayersService = game:GetService("Players")

-- Require Modules
local Util = Knit.Util
local Modules = Knit.Modules

local ProfileService = require(Modules.ProfileService)
local PlayerObject = require(Modules.PlayerObject)
local RemoteEvent = require(Util.Remote.RemoteEvent)


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
        Cens = 0;

        Inv = {};
        Skills = {};
        Customization = {};
        Model = "";

        Options = {
            Ragdolls = true;
            DeathEffects = true;
        };
    }
)

local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync(
        "Player_" .. player.UserId,
        "ForceLoad"
    )
    if profile ~= nil then
        profile:ListenToRelease(function()
            PlayerService.Players[player] = nil
            -- The profile could've been loaded on another Roblox server:
            player:Kick("The profile couldn't be loaded.")
        end)
        if player:IsDescendantOf(PlayersService) then
            local Player = PlayerObject.new(player, profile)
            PlayerService.Players[player] = Player
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
        PlayerAdded(Player)
    end)
end

-- Initialize
function PlayerService:KnitInit()
    -- Clean up data when player leaves:
    game:GetService("Players").PlayerRemoving:Connect(function(Player)
        local Object = Players[Player]

        if Object and Object.Data ~= nil then
            Object.Data:Release()
        end

        Players[Player] = nil
    end)
end


return PlayerService