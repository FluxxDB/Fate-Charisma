-- Servicees
local Knit = _G.KnitClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")


-- Variables
local Player = Knit.Player
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Rng = Random.new();

local PlayerGui = Player:WaitForChild("PlayerGui")
local Music = SoundService.Music
local Areas = Music.Areas
-- local CombatMusic = Music.Combat:GetChildren()

local Utils = Knit.Util
local Modules = Knit.Modules

local LoadedRegions = {}


-- Require Modules
local Zone = require(Utils.ZoneService.Zone)
local Thread = require(Utils.Thread)
local BoatTween = require(Modules.BoatTween)


-- Create Knit controller
local RegionController = Knit.CreateController {
    Name = "RegionService";

    -- Client exposed fields:
    Label = nil;
    Stroke = nil;
    LabelDuration = 3;

    CurrentRegion = nil;

    AmbienceList = nil;
    SongList = nil;

    PlayingAmbience = nil;
    PlayingSong = nil;
}

local tweenInfo = {
    LabelPlay = {
        Time = 1;
        EasingStyle = "Quad";
        EasingDirection = "In";

        StepType = "Heartbeat";

        Goal = {
            TextTransparency = 0;
            TextStrokeTransparency = 0.3;
        };
    };
    LabelStop = {
        Time = 1.5;
        EasingStyle = "Linear";
        EasingDirection = "Out";

        StepType = "Heartbeat";

        Goal = {
            TextTransparency = 1;
            TextStrokeTransparency = 1;
        };
    };
    StrokePlay = {
        Time = 0.6;
        EasingStyle = "Quad";
        EasingDirection = "In";

        StepType = "Heartbeat";

        Goal = {
            ImageTransparency = 0.3;
        };
    };
    StrokeStop = {
        Time = 1.7;
        EasingStyle = "Linear";
        EasingDirection = "Out";

        StepType = "Heartbeat";

        Goal = {
            ImageTransparency = 1;
        };
    };
    SongPlay = {
        Time = 2;
        EasingStyle = "Linear";
        EasingDirection = "InOut";

        StepType = "Heartbeat";

        Goal = {
            Volume = 1;
        };
    };
    SongStop = {
        Time = 2;
        EasingStyle = "Linear";
        EasingDirection = "InOut";

        StepType = "Heartbeat";

        Goal = {
            Volume = 0;
        };
    };
}


function RegionController:StopAll()
    Thread.SpawnNow(function()
        self:StopMusic("Song")
    end)
    Thread.SpawnNow(function()
        self:StopMusic("Ambience")
    end)
    Thread.SpawnNow(function()
        self:StopMusic("Combat")
    end)
end

-- Stop Current
function RegionController:StopMusic(Name)
    -- Set Tweens table
    local Tweens = {}
    local Connection = self[Name .. "Connection"]
    local Sound = self[Name .. "Playing"]

    -- Destroy any connections for the playlist
    if Connection then
        Connection:Disconnect()
    end

    -- Create Tweens for transition
    if Sound and Sound.Playing then
        local OriginalVolume = Sound.Volume
        local Tween = BoatTween:Create(Sound, tweenInfo.SongStop)
        table.insert(Tweens, Tween)
        Tween.Completed:Connect(function()
            Sound:Stop()
            Sound.Volume = OriginalVolume
            Sound.TimePosition = 0
            Tween:Destroy()
        end)
        Tween:Play()
    end

    wait(tweenInfo.SongStop.Time)
end

-- Play
function RegionController:PlayMusic(Index, Name, Musics)
    -- Stop previous music
    self:StopMusic(Name)

    -- Setup variables to be used in the loop
    local Sound = Musics[Index]
    local Volume = Sound.Volume

    self[Name .. "Playing"] = Sound
    Sound.TimePosition = 0
    Sound.Volume = 0
    Sound:Play()

    if not Sound.IsLoaded then
        Sound.Loaded:Wait()
    end

    if Name ~= "Ambience" then
        local Tween = BoatTween:Create(Sound, setmetatable({
            Goal = {
                Volume = Volume
            }
        }, tweenInfo.SongPlay))
        Tween.Completed:Connect(function()
            Tween:Destroy()
        end)
        Tween:Play()
    else
        Sound.Volume = Volume
    end

    local Connection
    Connection = Sound.Ended:Connect(function()
        self[Name .. "Index"] = (Index + 1 > #Musics and 1) or Index + 1
        self:PlayMusic(self[Name .. "Index"], Name, Musics)
        Connection:Disconnect()
    end)
    self[Name .. "Connection"] = Connection
end

-- Start
function RegionController:KnitStart()
    Player.CharacterAdded:Wait()
    local AmbientContainer = PlayerGui:WaitForChild("AmbientContainer")
    local Label = AmbientContainer:WaitForChild("Label")
    local Stroke = Label:WaitForChild("Stroke")

    self.Label = Label
    self.Stroke = Stroke

    local AreaMarkers = Assets:WaitForChild("AreaMarkers")
    AreaMarkers.Parent = workspace

    for _, Group in pairs(AreaMarkers:GetChildren()) do
        local zone = Zone.new(Group)

        zone.playerAdded:Connect(function()
            if self.CurrentRegion == Group.Name then return end
            self.CurrentRegion = Group.Name
            self.Label.Text = Group.Name

            local Area = Areas:FindFirstChild(Group.Name)
            if not Area then return end

            local AreaData = LoadedRegions[Group.Name]
            if not AreaData then
                AreaData = require(Area)
                LoadedRegions[Group.Name] = AreaData
            end

            if AreaData.Ambience and next(AreaData.Ambience) then
                Thread.SpawnNow(function()
                    local Index = Rng:NextInteger(1, #AreaData.Ambience)
                    self["AmbienceIndex"] = Index
                    self:PlayMusic(Index, "Ambience", AreaData.Ambience)
                end)
            elseif self["AmbienceIndex"] then
                Thread.SpawnNow(function()
                    self:StopMusic("Ambience")
                end)
            end

            if AreaData.Music and next(AreaData.Music) then
                Thread.SpawnNow(function()
                    local Index = Rng:NextInteger(1, #AreaData.Music)
                    self["SongIndex"] = Index
                    self:PlayMusic(Index, "Song", AreaData.Music)
                end)
            elseif self["SongIndex"] then
                Thread.SpawnNow(function()
                    self:StopMusic("Song")
                end)
            end


            local LabelTween = BoatTween:Create(self.Label, tweenInfo.LabelPlay)
            local StrokeTween = BoatTween:Create(self.Stroke, tweenInfo.StrokePlay)
            StrokeTween.Completed:Connect(function() StrokeTween:Destroy() end)
            StrokeTween:Play()
            LabelTween:Play()
            LabelTween.Completed:Wait()
            LabelTween:Destroy()

            Thread.Delay(2, function()
                LabelTween = BoatTween:Create(self.Label, tweenInfo.LabelStop)
                StrokeTween = BoatTween:Create(self.Stroke, tweenInfo.StrokeStop)
                StrokeTween.Completed:Connect(function() StrokeTween:Destroy() end)
                StrokeTween:Play()
                LabelTween:Play()
                LabelTween.Completed:Wait()
                LabelTween:Destroy()
            end)
		end)

        zone.playerDied:Connect(function()
            self:StopAll()
        end)

	    zone:initClientLoop()
    end
end

-- Initialize
function RegionController:KnitInit()
    local function ResetOnDeath(Character)
        local Humanoid = Character:WaitForChild("Humanoid")

        Humanoid.Died:Connect(function()
            self.CurrentRegion = nil
            self:StopAll()
        end)
    end

    Player.CharacterAdded:Connect(ResetOnDeath)
    if Player.Character then
        ResetOnDeath(Player.Character)
    end
end


return RegionController