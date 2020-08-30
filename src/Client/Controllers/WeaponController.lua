-- Servicees
local Knit = _G.KnitClient
local CharacterController

-- Variables
local Player = Knit.Player

-- Create Knit controller
local WeaponController = Knit.CreateController {
    Name = "WeaponController";
}

-- Functions
local function GetOrCreate(Name, Type, Parent)
	local Object = Parent:FindFirstChild(Name)
	if not (Object) then
		Object = Instance.new(Type)
		Object.Name = Name
		Object.Parent = Parent
	end
	return Object
end

local function weldAttachments(attach1, attach2)
    local weld = Instance.new("Weld")
    weld.Part0 = attach1.Parent
    weld.Part1 = attach2.Parent
    weld.C0 = attach1.CFrame
    weld.C1 = attach2.CFrame
    weld.Parent = attach1.Parent
    return weld
end
 
local function buildWeld(weldName, parent, part0, part1, c0, c1)
    local weld = Instance.new("Weld")
    weld.Name = weldName
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = parent
    return weld
end
 
local function findFirstMatchingAttachment(model, name)
    for _, child in pairs(model:GetChildren()) do
        if child:IsA("Attachment") and child.Name == name then
            return child
        elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then -- Don't look in hats or tools in the character
            local foundAttachment = findFirstMatchingAttachment(child, name)
            if foundAttachment then
                return foundAttachment
            end
        end
    end
end

local function addWeapon(character, accoutrement)  
    accoutrement.Parent = character
    local handle = accoutrement:FindFirstChild("Handle")
    if handle then
        local accoutrementAttachment = handle:FindFirstChildOfClass("Attachment")
        if accoutrementAttachment then
            local characterAttachment = findFirstMatchingAttachment(character, accoutrementAttachment.Name)
            if characterAttachment then
                weldAttachments(characterAttachment, accoutrementAttachment)
            end
        end
    end
end

local function Equip(Tool, Character)
    local Model = Tool:FindFirstChild("Model")
    if not (Model or Model:IsA("ObjectValue")) then return end

    local WeaponModel = Model.Value
    local ConfigModule = WeaponModel.Parent
    if not (ConfigModule or ConfigModule:IsA("ModuleScript")) then return end

    local Config = require(ConfigModule)
    local Parts = {}
    for _, LimbName in ipairs(Config.Parts) do
        local Limb = Character:FindFirstChild(LimbName)
        if not Limb then continue end
        
    end
end

-- Start
function WeaponController:KnitStart()
    CharacterController.CharacterAdded:Connect(function(Character)
        Character.ChildAdded:Connect(function(Tool)
            if not Tool:IsA("Tool") then return end
			return Equip(Tool, Character)
        end)
    end)
end

-- Initialize
function WeaponController:KnitInit()
    CharacterController = Knit.Controllers.CharacterController
end

return WeaponController