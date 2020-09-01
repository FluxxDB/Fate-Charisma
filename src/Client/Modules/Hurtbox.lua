-- Servicees
local Debris = game:GetService("Debris")

-- Functions
local function GetTouchingParts(Part)
    local connection = Part.Touched:Connect(function() end)
    local results = Part:GetTouchingParts()
    connection:Disconnect()
    return results
 end

return function(CFrame, Size, Debug)
    local Hurtbox = Instance.new("Part")
    Hurtbox.Size = Size
    Hurtbox.CFrame = CFrame
    Hurtbox.Transparency = Debug and 0.8 or 1 
    Hurtbox.CanCollide = false
    Hurtbox.Anchored = true
    Hurtbox.BrickColor = BrickColor.new(Debug or "Bright red")
    Hurtbox.BottomSurface = Enum.SurfaceType.Smooth
    Hurtbox.TopSurface = Enum.SurfaceType.Smooth
    Hurtbox.Parent = workspace
    
    Debris:AddItem(Hurtbox, 0.5)
    
    if Debug then return end
    return GetTouchingParts(Hurtbox)
end