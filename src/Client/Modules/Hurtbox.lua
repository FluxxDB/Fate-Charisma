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

return function(Position, Size, Debug)
    local Character = Player.Character
    if not Character or not Character.PrimaryPart then return end

    local Hurtbox = Instance.new("Part")
    Hurtbox.Size = Size
    Hurtbox.CFrame = Position
    Hurtbox.CanCollide = false
    Hurtbox.Transparency = 1
    Hurtbox.Anchored = true
    Hurtbox.Parent = workspace
    
    if Debug then
        if DebugBox then
            DebugBox:Destroy()
        end

        local Weld = Instance.new("WeldConstraint")
        Weld.Part0 = Hurtbox
        Weld.Part1 = Character.PrimaryPart
        Weld.Parent = Hurtbox

        Hurtbox.Massless = true
        Hurtbox.Anchored = false
        Hurtbox.BrickColor = BrickColor.new(Debug or "Lime green")
        Hurtbox.Transparency = 0.9
        Hurtbox.TopSurface = Enum.SurfaceType.Smooth
        Hurtbox.BottomSurface = Enum.SurfaceType.Smooth
        DebugBox = Hurtbox

        local SelectionBox = Instance.new("SelectionBox")
        SelectionBox.Adornee = Hurtbox
        SelectionBox.LineThickness = 0.01
        SelectionBox.Color3 = Hurtbox.Color
        SelectionBox.Parent = Hurtbox
        
        return Debris:AddItem(Hurtbox, 0.5)
    end

    return GetTouchingParts(Hurtbox)
end