-- Servicees
local Knit = _G.KnitClient
local Debris = game:GetService("Debris")

-- Require Modules
local Util = Knit.Util

-- Functions
local function GetTouchingParts(Part, Debug)
    local connection = Part.Touched:Connect(function() end)
    local results = Part:GetTouchingParts()
    connection:Disconnect()

    if Debug then
        Part.Transparency = 0.5
        Debris:AddItem(Part, 0.5)
    else
        Part:Destroy()
    end

    return results
 end

return function(CFrame, Size, Debug)
    local Hurtbox = Instance.new("Part")
    Hurtbox.Size = Size
    Hurtbox.CFrame = CFrame
    Hurtbox.Transparency = 1
    Hurtbox.CanCollide = false
    Hurtbox.Color = BrickColor.new("Bright red")
    Hurtbox.Parent = workspace
    
    return GetTouchingParts(Hurtbox, Debug)
end