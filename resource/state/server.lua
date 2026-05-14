local protectedStates = {}
local setBehaviour = GetConvarInt('ox:statebagBehaviour', 0)

local BEHAVIOUR <const> = {
    -- allow client to set state on "unprotected" statebag
    NOTHING = 0,
    -- allow client to set state on "unprotected" statebag
    LOG = 1,
    -- drop client when setting an "unprotected" statebag
    DROP = 2,
}

---@class StatebagPayload
---@field target { player: number } | { entity: number }
---@field bagname string
---@field value any

local function handleUnauthorized(src, target, bagname)
    if setBehaviour == BEHAVIOUR.NOTHING then return end

    if setBehaviour == BEHAVIOUR.LOG then
        lib.print.info('Player %s %s tried changing a protected statebag value (target: %s - bag name: %s)')
    elseif setBehaviour == BEHAVIOUR.DROP then
        lib.print.info('Dropping player %s %s for changing a protected statebag value (target: %s - bag name: %s)')
        DropPlayer(src, 'Unauthorized statebag change')
    end
end

---@param payload StatebagPayload
local function setState(payload)
    local state
    if payload.target.entity then
        state = Entity(payload.target.entity)
    elseif payload.target.player then
        state = Player(payload.target.player)
    end

    if not state then
        lib.print.warn('Attempted to set a statebag on an invalid target')
        return
    end

    state:set(payload.bagname, payload.value)
end

local function addProtection(bagname, handler)
    if not protectedStates[bagname] then
        protectedStates[bagname] = {
            validators = {}
        }
    end

    local idx = protectedStates[bagname] and #protectedStates[bagname] or 0
    local id = string.format("%s.%s", bagname, idx)

    protectedStates[bagname].validators[idx] = handler

    return id
end

---@param payload StatebagPayload
RegisterNetEvent('ox_lib:setstate', function (payload)
    local src = source

    if not protectedStates[payload.bagname] then

        if setBehaviour ~= BEHAVIOUR.NOTHING then
            return handleUnauthorized(src, payload.target.entity and 'entity' or 'player', payload.bagname)
        end

        setState(payload)
    else
        local validators = protectedStates[payload.bagname]

        for i = 1, #validators, 1 do
            local validator = validators[i]

            local _, result = pcall(validator, src, payload)

            if result == false then
                return handleUnauthorized(src, payload.target.entity and 'entity' or 'player', payload.bagname)
            end
        end
    end
end)

lib.state = {
    add = addProtection,
}

return lib.state
