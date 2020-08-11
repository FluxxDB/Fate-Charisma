local Requests = {}

return function (Player, RateValue,	 TimeValue, Unique_Identifier)
    local Rate = RateValue
	local Time = TimeValue
	local Identifier = Unique_Identifier

	local Player_Object = Requests[Player]
	
	if not Player_Object then
		local Connection
		Connection = Player.AncestryChanged:Connect(function(Parent)
			if not Parent then
				Requests[Player] = nil
				Connection:Disconnect()
			end
		end)
		
		Requests[Player] = {}
		Player_Object = Requests[Player]
	end

	if not Player_Object[Identifier] then
		Player_Object[Identifier] = {}
	end

	Player_Object = Player_Object[Identifier]
	
	if Rate > Time then
		if Player_Object.Count then
			local TimeElapsed = tick() - Player_Object.StartTime 

			if TimeElapsed >= Time then
				Player_Object.Count = 1
				Player_Object.StartTime = tick()
				return true
			else
				Player_Object.Count = Player_Object.Count + 1
				return Player_Object.Count <= Rate
			end
		else
			Player_Object.Count = 1
			Player_Object.StartTime = tick()
			return true
		end
	end
	if Rate <= Time then
		if Player_Object.LastTime then
			local TimeElapsed = tick() - Player_Object.LastTime

			if TimeElapsed >= (Time/Rate) then
				Player_Object.LastTime = tick()
				return true
			else
				return false
			end
		else
			Player_Object.LastTime = tick()
			return true
		end
	end
end