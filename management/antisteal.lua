require("base")

function AntiSteal()
    AddHook(hooks.onVehicleSpawn, LockSpawnedVehicle)
    AddHook(hooks.onCustomCommand, AntiStealCommands)
end

function LockSpawnedVehicle(vehicle_id, peer_id, x, y, z, cost)
    if peer_id ~= -1 then
        SetVehicleLocked(peer_id, vehicle_id, true)
    end
end

function AntiStealCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if command == "?l" or command == "?lock" then
        local vehicle_id = tonumber(args[1])
        if vehicle_id then
            SetVehicleLocked(user_peer_id, vehicle_id, true)
        else
            server.notify(user_peer_id, "Vehicle not found", 1)
        end
    elseif command == "?u" or command == "?unlock" then
        local vehicle_id = tonumber(args[1])
        if vehicle_id then
            SetVehicleLocked(user_peer_id, vehicle_id, false)
        else
            server.notify(user_peer_id, "Vehicle not found", 1)
        end
    end
end

function SetVehicleLocked(requester, vehicle_id, lock)
    local player = GetPlayerByPeerId(requester)
    local vehicle = GetUserVehicle(vehicle_id)
    if not vehicle then
        server.notify(requester, "Anti-Steal", "Vehicle not found", 1)
        return
    end
    if requester == vehicle.peer_id then
        server.setVehicleEditable(vehicle_id, not lock)
        server.notify(requester, "Anti-Steal", string.format("Set %d lock status to: %s", vehicle_id, string.upper(tostring(lock))), 1)
    elseif requester == -1 or player.is_admin then
        server.setVehicleEditable(vehicle_id, not lock)
        server.notify(requester, "Anti-Steal", string.format("Set %d lock status to: %s", vehicle_id, string.upper(tostring(lock))), 1)
    else
        server.notify(requester, "Anti-Steal", "You do not have permission run this command", 9)
    end
end
