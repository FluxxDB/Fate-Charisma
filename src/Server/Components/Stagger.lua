local MyComponent = {
    Tag = "Stagger";
}
MyComponent.__index = MyComponent

-- CONSTRUCTOR
function MyComponent.new(instance)
    local self = setmetatable({}, MyComponent)
    return self
end

-- OPTIONAL LIFECYCLE HOOKS
function MyComponent:Init() end --                     -> Called right after constructor
function MyComponent:Deinit() end --                   -> Called right before deconstructor
function MyComponent:RenderUpdate(dt)  end --      -> Updates every render step
function MyComponent:SteppedUpdate(dt)  end --     -> Updates every physics step
function MyComponent:HeartbeatUpdate(dt)  end --   -> Updates every heartbeat

-- DESTRUCTOR
function MyComponent:Destroy()
end

return MyComponent