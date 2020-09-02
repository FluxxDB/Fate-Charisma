local Sequences = game.ReplicatedStorage.Assets.Sequences
local Hum = Instance.new("Humanoid")
Hum.Parent = workspace

for _, Type in ipairs(Sequences:GetChildren()) do
    for _, Sequence in ipairs(Type:GetChildren()) do
        for _, Animation in ipairs(Sequence:GetChildren()) do
            if not Animation:IsA("Animation") then continue end
            local Track = Hum:LoadAnimation(Animation)
            repeat wait() print(Track.Length) until Track.Length ~= 0
            Animation.Length.Value = Track.Length
        end
    end
end

Hum:Destroy()