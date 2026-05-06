local protectedStates = {}

---@class StatebagActions
---@field filter? string
---@field drop? boolean
---@field revert? any

---creates a watcher for a statebag
---@param bagname string
---@param options? StatebagActions
local function addProtection(bagname, options)
    local filter = options and options.filter or ''

    local id = AddStateBagChangeHandler(bagname, filter, function (bagName, key, value, reserved, replicated)
        lib.print.info('statebag changed', key, {
            bagName = bagName,
            value = value,
            reserved = reserved,
            replicated = replicated
        })

        if reserved ~= 0 then
            local serverId
            local state --[[ @as EntityInterface ]]

            if bagName:find("^player:") then
                serverId = GetPlayerFromStateBagName(bagName)
                state = Player(serverId)
            elseif bagName:find("^entity:") then
                local entityId = GetEntityFromStateBagName(bagName)
                state = Entity(entityId)
            end

            if not state then
                lib.print.error(('Unable to fetch state from bagname (%s) !'):format(bagName))
                return
            end

            if options?.revert then
                state:set(bagname, options.revert, true)
            end

            -- ToDo: get client acting on statebag for dropping
            if options?.drop then
                if not serverId then
                    lib.print.warn('Unable to find acting client on unauthorised statebag change')
                    lib.print.warn(' - bangame: ', bagName)
                    lib.print.warn(' - key: ', key)
                    lib.print.warn(' - value: ', value)
                    return
                end

                DropPlayer(serverId, 'Unauthorized changing of a statebag')
            end
        end
    end)

    protectedStates[bagname] = id
end

local function removeProtection(bagname)
    local id = protectedStates[bagname]

    if not id then
        lib.print.warn(('Tried to remove protection from a statebag (%s) that isn\'t protected'):format(bagname))
        return
    end

    RemoveStateBagChangeHandler(id)
    protectedStates[bagname] = nil
end

lib.state = {
    add = addProtection,
    remove = removeProtection,
}

return lib.state
