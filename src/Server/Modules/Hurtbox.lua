-- Servicees
local Knit = _G.KnitClient
local Debris = game:GetService("Debris")


-- Variables
local Player = Knit.Player
local DebugBox

-- Functions
local function GetTouchingParts(Part)
    local connection = Part.Touched:Connect(function() end)
    local results = Part:GetTouchingParts()
    connection:Disconnect()
    Part:Destroy()
    return results
 end

return function(Position, Size)
    local Character = Player.Character
    if not Character or not Character.PrimaryPart then return end

    local Hurtbox = Instance.new("Part")
    Hurtbox.Size = Size
    Hurtbox.CFrame = Position
    Hurtbox.CanCollide = false
    Hurtbox.Transparency = 1
    Hurtbox.Anchored = true
    Hurtbox.Parent = workspace

    return GetTouchingParts(Hurtbox)
end