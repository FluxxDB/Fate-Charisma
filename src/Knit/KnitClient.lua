local KnitClient = {}

KnitClient.Version = script.Parent.Version.Value
KnitClient.Player = game:GetService("Players").LocalPlayer
KnitClient.Controllers = {}
KnitClient.Util = script.Parent.Util

_G.KnitClient = KnitClient

local Promise = require(KnitClient.Util.Promise)
local Thread = require(KnitClient.Util.Thread)
local RemoteEvent = require(KnitClient.Util.Remote.RemoteEvent)
local RemoteProperty = require(KnitClient.Util.Remote.RemoteProperty)
local TableUtil = require(KnitClient.Util.TableUtil)

local services = {}
local servicesFolder = script.Parent:WaitForChild("Services")

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function BuildService(serviceName, folder)
	local service = {}
	if (folder:FindFirstChild("RF")) then
		for _,rf in ipairs(folder.RF:GetChildren()) do
			if (rf:IsA("RemoteFunction")) then
				service[rf.Name] = function(self, ...)
					return rf:InvokeServer(...)
				end
				service[rf.Name .. "Promise"] = function(self, ...)
					local args = table.pack(...)
					return Promise.new(function(resolve)
						resolve(rf:InvokeServer(table.unpack(args, 1, args.n)))
					end)
				end
			end
		end
	end
	if (folder:FindFirstChild("RE")) then
		for _,re in ipairs(folder.RE:GetChildren()) do
			if (re:IsA("RemoteEvent")) then
				service[re.Name] = RemoteEvent.new(re)
			end
		end
	end
	if (folder:FindFirstChild("RP")) then
		for _,rp in ipairs(folder.RP:GetChildren()) do
			if (rp:IsA("ValueBase")) then
				service[rp.Name] = RemoteProperty.new(rp)
			end
		end
	end
	services[serviceName] = service
	return service
end


function KnitClient.CreateController(controller)
	assert(type(controller) == "table", "Controller must be a table; got " .. type(controller))
	assert(type(controller.Name) == "string", "Controller.Name must be a string; got " .. type(controller.Name))
	assert(#controller.Name > 0, "Controller.Name must be a non-empty string")
	assert(KnitClient.Controllers[controller.Name] == nil, "Service \"" .. controller.Name .. "\" already exists")
	TableUtil.Extend(controller, {
		_knit_is_controller = true;
	})
	KnitClient.Controllers[controller.Name] = controller
	return controller
end


function KnitClient.GetService(serviceName)
	assert(type(serviceName) == "string", "ServiceName must be a string; got " .. type(serviceName))
	local folder = servicesFolder:WaitForChild(serviceName, 5)
	assert(folder ~= nil, "Could not find service \"" .. serviceName .. "\"")
	return services[serviceName] or BuildService(serviceName, folder)
end


function KnitClient.Start()
	
	if (started) then
		return Promise.Reject("Knit already started")
	end
	
	started = true

	local controllers = KnitClient.Controllers
	
	return Promise.new(function(resolve)

		-- Init:
		local promisesStartControllers = {}
		for _,controller in pairs(controllers) do
			if (type(controller.KnitInit) == "function") then
				table.insert(promisesStartControllers, Promise.new(function(r)
					controller:KnitInit()
					r()
				end))
			end
		end

		resolve(Promise.All(promisesStartControllers))

	end):Then(function()

		-- Start:
		for _,controller in pairs(controllers) do
			if (type(controller.KnitStart) == "function") then
				Thread.SpawnNow(controller.KnitStart, controller)
			end
		end
		
		startedComplete = true
		onStartedComplete:Fire()

		Thread.Spawn(function()
			onStartedComplete:Destroy()
		end)
		
	end)
	
end


function KnitClient.OnStart()
	if (startedComplete) then
		return Promise.Resolve()
	else
		return Promise.new(function(resolve)
			if (startedComplete) then
				resolve()
				return
			end
			onStartedComplete.Event:Wait()
			resolve()
		end)
	end
end


return KnitClient