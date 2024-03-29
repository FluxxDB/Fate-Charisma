local KnitServer = {}

KnitServer.Version = script.Parent.Version.Value
KnitServer.Services = {}
KnitServer.Util = script.Parent.Util

_G.KnitServer = KnitServer

local knitRepServiceFolder = Instance.new("Folder")
knitRepServiceFolder.Name = "Services"
knitRepServiceFolder.Parent = script.Parent

local Promise = require(KnitServer.Util.Promise)
local Thread = require(KnitServer.Util.Thread)
local Signal = require(KnitServer.Util.Signal)
local RemoteEvent = require(KnitServer.Util.Remote.RemoteEvent)
local RemoteProperty = require(KnitServer.Util.Remote.RemoteProperty)
local TableUtil = require(KnitServer.Util.TableUtil)

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")


local function CreateRepFolder(serviceName)
	local folder = Instance.new("Folder")
	folder.Name = serviceName
	return folder
end


local function GetFolderOrCreate(parent, name)
	local f = parent:FindFirstChild(name)
	if (not f) then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end


local function AddToRepFolder(service, remoteObj)
	if (remoteObj:IsA("RemoteFunction")) then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RF")
	elseif (remoteObj:IsA("RemoteEvent")) then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RE")
	elseif (remoteObj:IsA("ValueBase")) then
		remoteObj.Parent = GetFolderOrCreate(service._knit_rep_folder, "RP")
	else
		error("Invalid rep object: " .. remoteObj.ClassName)
	end
	if (not service._knit_rep_folder.Parent) then
		service._knit_rep_folder.Parent = knitRepServiceFolder
	end
end


function KnitServer.IsService(object)
	return type(object) == "table" and object._knit_is_service == true
end


function KnitServer.CreateService(service)
	assert(type(service) == "table", "Service must be a table; got " .. type(service))
	assert(type(service.Name) == "string", "Service.Name must be a string; got " .. type(service.Name))
	assert(#service.Name > 0, "Service.Name must be a non-empty string")
	assert(KnitServer.Services[service.Name] == nil, "Service \"" .. service.Name .. "\" already exists")
	TableUtil.Extend(service, {
		_knit_is_service = true;
		_knit_rf = {};
		_knit_re = {};
		_knit_rp = {};
		_knit_rep_folder = CreateRepFolder(service.Name);
	})
	if (type(service.Client) ~= "table") then
		service.Client = {Server = service}
	else
		if (service.Client.Server ~= service) then
			service.Client.Server = service
		end
	end
	KnitServer.Services[service.Name] = service
	return service
end


function KnitServer.BindRemoteEvent(service, eventName, remoteEvent)
	assert(service._knit_re[eventName] == nil, "RemoteEvent \"" .. eventName .. "\" already exists")
	local re = remoteEvent._remote
	re.Name = eventName
	service._knit_re[eventName] = re
	AddToRepFolder(service, re)
end


function KnitServer.BindRemoteFunction(service, funcName, func)
	assert(service._knit_rf[funcName] == nil, "RemoteFunction \"" .. funcName .. "\" already exists")
	local rf = Instance.new("RemoteFunction")
	rf.Name = funcName
	service._knit_rf[funcName] = rf
	AddToRepFolder(service, rf)
	function rf.OnServerInvoke(...)
		return func(service.Client, ...)
	end
end


function KnitServer.BindRemoteProperty(service, propName, prop)
	assert(service._knit_rp[propName] == nil, "RemoteProperty \"" .. propName .. "\" already exists")
	prop._object.Name = propName
	service._knit_rp[propName] = prop
	AddToRepFolder(service, prop._object)
end


function KnitServer.Start()
	
	if (started) then
		return Promise.Reject("Knit already started")
	end

	started = true
	
	local services = KnitServer.Services
	
	return Promise.new(function(resolve)
		
		-- Bind remotes:
		for _,service in pairs(services) do
			for k,v in pairs(service.Client) do
				if (type(v) == "function") then
					KnitServer.BindRemoteFunction(service, k, v)
				elseif (RemoteEvent.Is(v)) then
					KnitServer.BindRemoteEvent(service, k, v)
				elseif (RemoteProperty.Is(v)) then
					KnitServer.BindRemoteProperty(service, k, v)
				elseif (Signal.Is(v)) then
					warn("Found Signal instead of RemoteEvent (Knit.Util.RemoteEvent). Please change to RemoteEvent. [" .. service.Name .. ".Client." .. k .. "]")
				end
			end
		end
		
		-- Init:
		local promisesStartServices = {}
		for _,service in pairs(services) do
			if (type(service.KnitInit) == "function") then
				table.insert(promisesStartServices, Promise.new(function(r)
					service:KnitInit()
					r()
				end))
			end
		end
		resolve(Promise.All(promisesStartServices))

	end):Then(function()
		
		-- Start:
		for _,service in pairs(services) do
			if (type(service.KnitStart) == "function") then
				Thread.SpawnNow(service.KnitStart, service)
			end
		end
		
		startedComplete = true
		onStartedComplete:Fire()

		Thread.Spawn(function()
			onStartedComplete:Destroy()
		end)
		
	end)
	
end


function KnitServer.OnStart()
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


return KnitServer