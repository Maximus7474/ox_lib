lib.state = {
    ---@param payload StatebagPayload
    set = function (payload)
        if not payload?.target.player or not payload?.target.entity then
            lib.print.error('payload for lib.state.set was invalid !')
            return
        end

        TriggerServerEvent('ox_lib:setstate', payload)
    end,
    ---@param bagname string
    ---@param value any
    setPlayer = function (bagname, value)
        lib.state.set({
            target = {
                player = cache.serverId,
            },
            bagname = bagname,
            value = value,
        })
    end,
    ---@param entity number
    ---@param bagname string
    ---@param value any
    setEntity = function (entity, bagname, value)
        lib.state.set({
            target = {
                entity = entity,
            },
            bagname = bagname,
            value = value,
        })
    end,
}

return lib.state
