local trackedConvars, convarEvents = {}, {}

---@alias ConvarType 'int'|'string'|'bool'|'float'

local convar = setmetatable({}, {
    ---@param self table
    ---@param convarName string
    ---@return any | nil
    __index = function (self, convarName)
        AddConvarChangeListener(convarName, function (name)
            local newValue

            local convarData = trackedConvars[name]
            if convarData then
                local type, default = convarData.type, convarData.default
                if type == 'int' then
                    newValue = GetConvarInt(name, default or 0)
                elseif type == 'float' then
                    newValue = GetConvarFloat(name, default or 0.0)
                elseif type == 'bool' then
                    newValue = GetConvarBool(name, default or false)
                elseif type == 'string' then
                    newValue = GetConvar(name, default or '')
                end
            else
                newValue = GetConvar(name, '')
            end

		    TriggerEvent(('ox_lib:convar:%s'):format(name), newValue, self[name])
            self[name] = newValue
        end)

        return rawget(self, convarName)
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

        TriggerEvent(('ox_lib:convar:%s'):format(convarName), value, self[convarName])

        self[convarName] = value

        trackedConvars[convarName] = {
            type = type,
            default = default,
        }
    end
})

if IsDuplicityVersion() then
    ---(server only) set a new value to a convar
    ---@param convarName string
    ---@param value any
    ---@param replicated? boolean
    function convar:set(convarName, value, replicated)
        if replicated then
            SetConvarReplicated(convarName, value)
        else
            SetConvar(convarName, value)
        end
    end
end

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
