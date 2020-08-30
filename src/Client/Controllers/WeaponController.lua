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

local function JointAttachments(attach1, attach2)
    local Joint = Instance.new("Motor6D")
    Joint.Part0 = attach1.Parent
    Joint.Part1 = attach2.Parent
    Joint.C0 = attach1.CFrame
    Joint.C1 = attach2.CFrame
    Joint.Parent = attach1.Parent
    return Joint
end

local function addWeapon(Limb, Weapon)
    local WeaponAttachment = Weapon:FindFirstChildOfClass("Attachment")

    if WeaponAttachment then
        local LimbAttachment = Limb:FindFirstChild(WeaponAttachment.Name)
        if LimbAttachment then
            JointAttachments(LimbAttachment, WeaponAttachment).Parent = Weapon
        end
    end
end

local function Equip(Tool, Character)
    local Model = Tool:FindFirstChild("Model")
    if not (Model and Model:IsA("ObjectValue")) then return end

    local WeaponModel = Model.Value
    local ConfigModule = WeaponModel.Parent
    if not (ConfigModule and ConfigModule:IsA("ModuleScript")) then return end

    local Config = require(ConfigModule)
    local Holder = GetOrCreate("Weapons", "Folder", Character)
    for Name, Part in ipairs(Config.Parts) do
        local Limb = Character:FindFirstChild(Name)
        if not Limb then continue end
        
        local Weapon = Part:Clone()
        Weapon.Parent = Holder
        addWeapon(Limb, Weapon)
    end

    local Connection
    Connection = Tool.AncestryChanged:Connect(function()
        Holder:Destroy()
        Connection:Disconnect()
    end)
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