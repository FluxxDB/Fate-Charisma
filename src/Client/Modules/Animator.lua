-- Servicees
local Knit = _G.KnitClient


-- Require Modules
local Util = Knit.Util
local MaidUtil = require(Util.Maid)
local TableUtil = require(Util.TableUtil)


-- Variables
local Rng = Random.new()
local Speeds = {
	Walk   = 1.8;
	Sprint = 1.3;
}


-- Loaders
local Load = {
	Default = function(Object, Folder)
		local Humanoid = Object.Humanoid
		local LoadedAnimations = {}
	
		for _, Animation in ipairs(Folder:GetChildren()) do
			LoadedAnimations[Animation.Name] = Humanoid:LoadAnimation(Animation)
			
			if string.match(Animation.Name, "Damage") then
				Object.DamageCount = Object.DamageCount + 1
			end
		end
	
		if Object.Animations[Folder.Name] then
			Object.Animations[Folder.Name] = TableUtil.Assign(Object.Animations[Folder.Name], LoadedAnimations)
		else
			Object.Animations[Folder.Name] = LoadedAnimations
		end
	end;
	
	Movement = function(Object, Folder)
		local Humanoid = Object.Humanoid
        local LoadedAnimations = {}
        
		for _, Animation in ipairs(Folder:GetChildren()) do
			local Name = Animation.Name
			local Stance = string.split(Name, "_")

			if #Stance == 2 then
				local Animations = LoadedAnimations[Stance[1]]
				if not LoadedAnimations[Stance[1]] then
					Animations = {}
					LoadedAnimations[Stance[1]] = Animations
				end

				Animations[Stance[2]] = Humanoid:LoadAnimation(Animation)
			else
				LoadedAnimations[Name] = Humanoid:LoadAnimation(Animation)
			end
		end
	
		Object.Animations[Folder.Name] = LoadedAnimations
	end;
}


-- Class
local Animator = {}
Animator.__index = Animator


function Animator.new(Character)
	if not Character or not Character.Parent then return end

	local Humanoid = Character:WaitForChild("Humanoid")
	if not Humanoid or Humanoid.Health == 0 then return end

	local Info = Character:WaitForChild("Info")
	if not Info then return end

	local Maid = MaidUtil.new()
	local self = setmetatable({
        __Maid 	 	= Maid;
        
		Disabled 	= false;
		Stopped 	= false;

		Info        = Info;
		Stance      = Info.Stance.Value;
		LastProt	= Info.Protection.Value;

		Humanoid    = Humanoid;

		HRP 	    = Humanoid.RootPart;
		LastHealth  = Humanoid.MaxHealth;

		DamageCount = 0;
		Animations  = {};
	}, Animator)
	
	local AnimationsToLoad = Info:FindFirstChild("Animations")
	local AnimationPlaying = Info:FindFirstChild("AnimationPlaying")

	if AnimationsToLoad and AnimationsToLoad.Value then
		for _, Section in ipairs(AnimationsToLoad.Value:GetChildren()) do
			self:LoadAnimation(Section)
		end
	end
	
	if AnimationPlaying then
		Maid:GiveTask(AnimationPlaying.Changed:Connect(function(AnimationPath)
			local Path = AnimationPath:split(".")
			local Animation = self:Get(Path[1], Path[2])

			if Animation then
				Animation:Play()
			end
		end))
	end

	Maid:GiveTask(Humanoid.HealthChanged:Connect(function(Health)
		local Difference = Health - self.LastHealth
		
		if Difference < 0 then
			self:Damage(-Difference)
		end

		if Humanoid.Health == 0 then
			Maid:DoCleaning()
		end
		
		self.LastHealth	= Health
	end))
	
	Maid:GiveTask(Info.Protection.Changed:Connect(function(Protection)
		local Difference = Protection - self.LastProt
		
		if Difference < 0 then
			self:Damage(-Difference)
		end
		
		self.LastProt = Protection
	end))
	
	Maid:GiveTask(Humanoid.StateChanged:connect(function(_, NewState)
		if NewState == Enum.HumanoidStateType.Jumping then
			if Humanoid.FloorMaterial ~= Enum.Material.Air then
				local Actions = self.Animations["Actions"]
				Actions.Jump:Play(0.05, 1, 2)
			end
		end
	end))
	
	return self
end


function Animator:Get(Section, Name)
	local Animations = self.Animations[Section]
	if not Animations then return end
	
	return Animations[Name]
end


function Animator:Play(Section, Name)
	local Animation = self:Get(Section, Name)
	if not Animation or Animation.IsPlaying then return end

	Animation:Play()
end


function Animator:Stop(Section, Name)
	local Animation = self:Get(Section, Name)
	if not Animation or not Animation.IsPlaying then return end

	Animation:Stop()
end


function Animator:StopAll()
	for _, v in ipairs(self.Humanoid:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end


function Animator:LoadAnimation(Folder)
	if not Folder then return end

	if not Load[Folder.Name] then
		Load.Default(self, Folder)
		return
	end
	
	Load[Folder.Name](self, Folder)
end


function Animator:Damage(amount)
	if self.DamageCount == 0 then return end
	
	local Actions = self.Animations["Actions"]
	local Damage = Actions["Damage" .. tostring(Rng:NextInteger(1, self.DamageCount))]
	
	if not Damage then
		Damage:Play(0.05, amount / 50, 1.5)
	end
end


function Animator:SetStance(NewStance)
    if self.Stance ~= NewStance then
        local OldStance = self.Stance
		self.Stance	= NewStance
		
		if OldStance == "Falling" then
			self.Animations.Movement.Falling:Stop()
			return
		end

		for _, animation in pairs(self.Animations.Movement[OldStance]) do
			animation:Stop()
		end
	end
end


function Animator:UpdateMovement(LocalVelocity)
    local Stance = self.Stance
    if Stance == "Falling" then return end
    
    local Animations = self.Animations
	local Speed = LocalVelocity.Magnitude

    for _, emote in pairs(Animations.Emotes) do
        if emote.IsPlaying then
            emote:Stop()
        end
    end

    if Speed < 1 then
        for Name, Animation in pairs(Animations.Movement[Stance]) do
			local State	= string.match(Name, "^" .. Stance .. "_(.+)")

			if State then
				if State == "Idle" then
					if not Animation.IsPlaying then
						Animation:Play()
					end
				else
					if Animation.IsPlaying then
						Animation:Stop()
					end
				end
			else
				if Animation.IsPlaying then
					Animation:Stop()
				end
			end
		end
		
		return
    end

    local Unit = LocalVelocity.Unit
	for State, Animation in pairs(Animations.Movement[Stance]) do
        if not State then
            if Animation.IsPlaying then
                Animation:Stop()
			end
        end
        
        if State == "Idle" then
            if Animation.IsPlaying then
                Animation:Stop(0.4)
            end
        else
            if Speeds[Stance] then
                Animation:AdjustSpeed(math.max(Speeds[Stance] * (Speed / 20), 0.1))
            end
            if not Animation.IsPlaying then
                Animation:Play()
            end
        end

        if State == "Forward" then
            Animation:AdjustWeight(math.abs(math.clamp(Unit.Z, -1, 0.1))^2)
        elseif State == "Backward" then
            Animation:AdjustWeight(math.abs(math.clamp(Unit.Z, 0.1, 1))^2)
        elseif State == "Right" then
            Animation:AdjustWeight(math.abs(math.clamp(Unit.X, 0.1, 1))^2)
        elseif State == "Left" then
            Animation:AdjustWeight(math.abs(math.clamp(Unit.X, -1, 0.1))^2)
        end
    end
end


function Animator:Update()
	if self.Disabled then
		if not self.Stopped then
			self.Stopped = true
			self:StopAll()
		end
		return 
	else 
		self.Stopped = false 
	end

	local HRP = self.HRP
	local OnAir = self.Humanoid.FloorMaterial == Enum.Material.Air
	local LocalVelocity

	if not HRP.Anchored then
		LocalVelocity = HRP.CFrame:VectorToObjectSpace(Vector3.new(HRP.Velocity.X, 0, HRP.Velocity.Z))
	else
		local LastPos = self.LastPosition or HRP.Position
		LocalVelocity = (LastPos - HRP.Position) / (tick() - (self.LastTick or tick()))

		self.LastPosition = HRP.Position
		self.LastTick = tick()
	end
	
	if OnAir then
        local Movement = self.Animations.Movement
        if not Movement then return end

		local Fall = Movement.Falling
		if Fall and not Fall.IsPlaying then
			Fall:Play()
			self:SetStance("Falling")
		end
	else
		self:SetStance(self.Info.Stance.Value)
		self:UpdateMovement(LocalVelocity)
	end
end

return Animator