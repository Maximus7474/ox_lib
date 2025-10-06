local trackedConvars, convarEvents = {}, {}

---@alias ConvarType 'int'|'string'|'bool'|'float'

local convar = setmetatable({}, {
    ---@param self table
    ---@param key string
    ---@return any | nil
    __index = function (self, key)
        return rawget(self, key)
    end,

    ---add a new convar to the internal tracking
    ---@param self table
    ---@param convarName string
    ---@param type ConvarType
    ---@param default any
    __call = function (self, convarName, type, default)
        if trackedConvars[convarName] then
            warn(("'%s' is arleady being tracked"):format(convarName))
            return
        end

        local value
        if type == 'int' then
            value = GetConvarInt(convarName, default or 0)
        elseif type == 'float' then
            value = GetConvarFloat(convarName, default or 0.0)
        elseif type == 'bool' then
            value = GetConvarBool(convarName, default or false)
        elseif type == 'string' then
            value = GetConvar(convarName, default or '')
        end

        self[convarName] = value

        local handler = AddStateBagChangeHandler(convarName, nil, function ()
            local newValue
            if type == 'int' then
                newValue = GetConvarInt(convarName, default or 0)
            elseif type == 'float' then
                newValue = GetConvarFloat(convarName, default or 0.0)
            elseif type == 'bool' then
                newValue = GetConvarBool(convarName, default or false)
            elseif type == 'string' then
                newValue = GetConvar(convarName, default or '')
            end

		    TriggerEvent(('ox_lib:convar:%s'):format(convarName), newValue, self[convarName])
            self[convarName] = newValue
        end)

        convarEvents[convarName] = {}

        AddEventHandler(('ox_lib:convar:%s'):format(convarName), function(value, oldValue)
            local events = convarEvents[convarName]

            for i = 1, #events do
                Citizen.CreateThreadNow(function()
                    events[i](value, oldValue)
                end)
            end
        end)

        trackedConvars[convarName] = {
            handler = handler,
            type = type,
            default = default,
        }
    end
})

---add a listener for a convr change
---@param key string convarname
---@param cb fun(newValue: any, oldValue: any)
function lib.onConvar(key, cb)
    if not trackedConvars[key] then
        warn(("Convar '%s' is not tracked. Use convar('%s', 'type', default) first to track it."):format(key, key))
        return
    end

    table.insert(convarEvents[key], cb)
end

_ENV.convar = convar
