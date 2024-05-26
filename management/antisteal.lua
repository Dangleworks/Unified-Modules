require("base")
require("tracking.vehicle_tracking")
require("util.notify")

function AntiSteal()
    AddHook(hooks.onVehicleSpawn, LockSpawnedVehicle)
    AddHook(hooks.onCustomCommand, AntiStealCommands)
    AddHelpEntry("antisteal (vehicle locking)", {
        {"?lock [vehicle_id]", "Locks the specified vehicle"},
        {"?l [vehicle_id]", "An alias for ?lock"},
        {"?unlock [vehicle_id]", "Unlocks the specified vehicle"},
        {"?u [vehicle_id]", "An alias for ?unlock"}
    })
end

function LockSpawnedVehicle(vehicle_id, peer_id, x, y, z, group_cost, group_id)
    server.setVehicleEditable(vehicle_id, false)
end

function AntiStealCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    local lock = command == "?l" or command == "?lock"
    local unlock = command == "?u" or command == "?unlock"

    if lock or unlock then
        local group_id = tonumber(args[1])

        if group_id == nil then
            server.notify(user_peer_id, "Anti-Steal", "Invalid vehicle ID", NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
            return
        end

        SetVehicleLocked(user_peer_id, group_id, lock)
    end
end

-- @param requester number
-- @param group_id number
-- @param lock boolean
function SetVehicleLocked(requester, group_id, lock)
    local player = GetPlayerByPeerId(requester)

    interal_vehicle_data = GetInternalVehicleGroupData(group_id)

    if not interal_vehicle_data then
        server.notify(requester, "Anti-Steal", string.format("Group %d is not tracked - cannot complete request", group_id), NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
        return
    end

    if interal_vehicle_data.peer_id ~= requester and requester ~= -1 and not player.is_admin then
        server.notify(requester, "Anti-Steal", "That vehicle does not belong to you", NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
        return
    end

    local vehicles, ok = server.getVehicleGroup(group_id)

    if not ok then
        server.notify(requester, "Anti-Steal", string.format("Failed to get vehicles for grpup %d", group_id), NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
        return
    end

    for _, vehicle_id in ipairs(vehicles) do
        server.setVehicleEditable(vehicle_id, not lock)
    end

    server.notify(requester, "Anti-Steal", string.format("Set %d locked: %s", group_id, string.upper(tostring(lock))), NOTIFICATION_TYPE.NEW_MISSION_CRITICAL)
end
