-- Servicees
local Knit = _G.KnitClient
local UIS = game:GetService("UserInputService")

-- Require Modules
local Util = Knit.Util
local Signal = require(Util.Signal)

-- Variables
local Types = {
	[Enum.UserInputType.Keyboard] = true;
	[Enum.UserInputType.MouseButton1] = "M1";
	[Enum.UserInputType.MouseButton2] = "M2";
}
local SpecialKeys = {
	[Enum.KeyCode.LeftControl] = "Ctrl";
	[Enum.KeyCode.LeftShift] = "Shift";
	[Enum.KeyCode.RightControl] = "Ctrl";
	[Enum.KeyCode.RightShift] = "Shift";
}


local Inputs = {}

-- Functions
local function GetKey(input)
	local KeyCode = input.KeyCode
	local Key = string.char(KeyCode.Value)
	Key = string.match(Key, ".")

	if Key ~= "" and Key then
		Key = string.upper(Key)
	else
		Key = SpecialKeys[KeyCode]
	end

	return Key
end

function IsDown(Key)
	return UIS:IsKeyDown(Enum.KeyCode[Key])
end

function WereTapped(InSeconds, Key)
	local KeyObject = Inputs[Key]
	if not KeyObject then return end

	local Previous = KeyObject.Previous
	if not Previous or not ((tick() - Previous) <= InSeconds) then return end

	return true
end

function WereAnyTapped(InSeconds, ...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if WereTapped(InSeconds, Key) then
			return true
		end
	end

	return false
end

function WereAllTapped(InSeconds, ...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if not WereTapped(InSeconds, Key) then
			return false
		end
	end

	return true
end

function WasTapped(InSeconds, Key)
	local KeyObject = Inputs[Key]
	if not KeyObject then return end

	local Current = KeyObject.Current
	if not Current or not ((tick() - Current) <= InSeconds) then return end

	return true
end

function WasAnyTapped(InSeconds, ...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if WasTapped(InSeconds, Key) then
			return true
		end
	end

	return false
end

function WasAllTapped(InSeconds, ...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if not WasTapped(InSeconds, Key) then
			return false
		end
	end

	return true
end

function AreAnyDown(...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if UIS:IsKeyDown(Enum.KeyCode[Key]) then
			return true
		end
	end

	return false
end

function AreAllDown(...)
	local Keys = { ... }

	for _, Key in ipairs(Keys) do
		if not UIS:IsKeyDown(Enum.KeyCode[Key]) then
			return false
		end
	end

	return true
end

-- Create Knit controller
local InputController = Knit.CreateController {
    Name = "InputController";

    IsDown = IsDown;
	WereTapped = WereTapped;
	WereAnyTapped = WereAnyTapped;
	WereAllTapped = WereAllTapped;
	WasTapped = WasTapped;
	WasAnyTapped = WasAnyTapped;
	WasAllTapped = WasAllTapped;
	AreAllDown = AreAllDown;
	AreAnyDown = AreAnyDown;
}

function InputController:KnitInit()
	local Began = Signal.new()
	local Ended = Signal.new()
	
	self.Began = Began
	self.Ended = Ended

	UIS.InputBegan:Connect(function(Input, GameProcessed)
        if GameProcessed then return end

		local Type = Types[Input.UserInputType]
        if not (Type ~= "" and Type) then
            return
        end

        local Key
        if type(Type) == "string" then
            Key = Type
        elseif type(Type) == "boolean" then
            Key = GetKey(Input)
        end

        if Key ~= "" and Key then
            local PrevKeyValue = Inputs[Key]
            if PrevKeyValue then
                Inputs[Key] = {
                    Previous = PrevKeyValue.Current;
                    Current = tick();
                }
            else
                Inputs[Key] = {
                    Current = tick();
                }
            end
        end

        Began:Fire(Input, Key);
	end)

	UIS.InputEnded:Connect(function(Input, GameProcessed)
        if GameProcessed then return end

        local Type = Types[Input.UserInputType]
        if not (Type ~= "" and Type) then
            return
        end

        local Key

        if type(Type) == "string" then
            Key = Type
        elseif type(Type) == "boolean" then
            Key = GetKey(Input)
        end

        Ended:Fire(Input, Key)
	end)
end

return InputController