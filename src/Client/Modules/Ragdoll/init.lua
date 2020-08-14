--- Base class for ragdolls, meant to be used with binders
-- @classmod Ragdoll

local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("Ragdoll")
PhysicsService:CollisionGroupSetCollidable("Ragdoll", "Ragdoll", false)

local RagdollUtils = require(script.RagdollUtils)

local Ragdoll = {}
Ragdoll.ClassName = "Ragdoll"
Ragdoll.__index = Ragdoll


function Ragdoll.new(humanoid)
	assert(humanoid and humanoid:IsA("Humanoid"), "[Knit Ragdoll]: Humanoid must be Humanoid; got " .. type(humanoid))

	local self = setmetatable({}, Ragdoll)

	self._obj = humanoid
	self:_collideLimbs()
	self._obj.BreakJointsOnDeath = false
	self._obj.PlatformStand = true
	self._obj:ChangeState(Enum.HumanoidStateType.Physics)

	self:StopAnimations()

	self._maid:GiveTask(function()
		self._obj.PlatformStand = false
		self._obj:ChangeState(Enum.HumanoidStateType.GettingUp)
	end)

	self:_setupRootPart()

	for _, balljoint in ipairs(RagdollUtils.createBallJoints(self._obj)) do
		self._maid:GiveTask(balljoint)
	end

	for _, noCollision in ipairs(RagdollUtils.createNoCollision(self._obj)) do
		self._maid:GiveTask(noCollision)
	end

	for _, motor in ipairs(RagdollUtils.getMotors(self._obj)) do
		local originalParent = motor.Parent
		motor.Parent = nil

		self._maid:GiveTask(function()
			if originalParent:IsDescendantOf(workspace) then
				motor.Parent = originalParent
			else
				motor:Destroy()
			end
		end)
	end

	-- After joints have been removed
	self:_setupHead()

	return self
end

function Ragdoll:_setupHead()
	local model = self._obj.Parent
	if not model then
		return
	end

	local head = model:FindFirstChild("Head")
	if not head then
		return
	end

	local originalSize = head.Size
	head.Size = Vector3.new(1, 1, 1)

	self._maid:GiveTask(function()
		head.Size = originalSize
	end)
end

function Ragdoll:_setupRootPart()
	local rootPart = self._obj.RootPart
	if not rootPart then
		return
	end

	rootPart.Massless = true
	rootPart.CanCollide = false

	self._maid:GiveTask(function()
		rootPart.Massless = false
		rootPart.CanCollide = true
	end)
end

function Ragdoll:_collideLimbs()
	local Character = self._obj.Parent
	local Limbs = {
		Character:FindFirstChild("Head");
		Character:FindFirstChild("Torso");
		Character:FindFirstChild("Left Arm");
		Character:FindFirstChild("Right Arm");
		Character:FindFirstChild("Left Leg");
		Character:FindFirstChild("Right Leg");
	}

	for _, v in ipairs(Limbs) do
		if v:IsA("BasePart") then
			local Collider = Instance.new("Part")
			Collider.CanCollide = true
			Collider.Anchored = false
			Collider.Transparency = 1
			Collider.Size = Vector3.new(v.Size.X, v.Size.Y/2, v.Size.Z)
			Collider.CFrame = v.CFrame - Vector3.new(0,v.Size.Y * .25, 0)

			local w = Instance.new("Weld")
			w.Part0 = v
			w.Part1 = Collider
			w.C0 = CFrame.new()
			w.C1 = w.Part1.CFrame:toObjectSpace(w.Part0.CFrame)
			w.Parent = Collider
			Collider.Parent = v

			self._maid:GiveTask(Collider)
		end
	end
end

function Ragdoll:StopAnimations()
	for _, item in pairs(self._obj:GetPlayingAnimationTracks()) do
		item:Stop()
	end
end

function Ragdoll:Destroy()
	self._maid:DoCleaning()
	self._obj = nil
end

return Ragdoll