require("base")
require("util.help")

function VehicleManagement()
    AddHook(hooks.onCustomCommand, VehicleManagementCommands)
    AddHook(hooks.onCreate, function(is_create) server.cleanVehicles() end)
    AddHook(hooks.onPlayerLeave, CleanVehiclesOnLeave)
    AddHelpEntry("vehicles", {
        {"?clean", "Removes all of your vehicles from the map"},
        {"?c", "An alias for ?clean"},
        {"?clean [peer_id]", "Removes all of the specified players vehicles", true},
        {"?despawn [id]", "Depawns your specific vehicle with the given id"},
        {"?d [id]", "An alias for ?despawn"}
    })
end

function CleanVehiclesOnLeave(steam_id, name, peer_id, is_admin, is_auth)
    ClearUsersVehicles(peer_id, -1)
end

function VehicleManagementCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if command == "?c" or command == "?clean" then
        local targ_pid = user_peer_id
        if args[1] ~= nil then
            targ_pid = tonumber(args[1])
            if targ_pid == nil then
                server.announce("[Error]", "Please provide a valid peer ID", user_peer_id)
                return
            end
        end
        ClearUsersVehicles(targ_pid, user_peer_id)
    end
    if command == "?d" or command == "?despawn" then
        local group_id = tonumber(args[1])
        if not group_id then
            server.announce("[Error]", "Please provide a valid vehicle id", user_peer_id)
            return
        end
        DespawnUserVehicle(group_id, user_peer_id)
    end
end

function DespawnUserVehicle(group_id, requester)
    local group_data = GetInternalVehicleGroupData(group_id)
    if group_data == nil then
        server.notify(requester, "Vehicle Management", "Vehicle not found", 1)
        return
    end

    if group_data.peer_id ~= requester and requester ~= -1 and not GetPlayerByPeerId(requester).is_admin then
        server.notify(requester, "Vehicle Management", "That vehicle does not belong to you", NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
        return
    end

    local isOwner = group_data.peer_id == requester
    
    DespawnVehicleGroup(group_id)

    server.notify(requester, "Vehicle Management", string.format("Vehicle %d has been despawned", group_id), NOTIFICATION_TYPE.COMPLETE_MISSION)
    if not isOwner then
        server.notify(group_data.peer_id, "Vehicle Management", "Your vehicle has been despawned by an admin", NOTIFICATION_TYPE.NETWORK_INFO)
    end
end

function ClearUsersVehicles(peer_id, requester)
    if peer_id ~= requester and requester ~= -1 and not GetPlayerByPeerId(requester).is_admin then
        server.notify(requester, "Vehicle Management", "You do not have permission to run this command", NOTIFICATION_TYPE.FAILED_MISSION_CRITICAL)
        return
    end
    
    local group_data = GetAllInternalVehicleGroupDataForPeer(peer_id)

    if TableLength(group_data) == 0 then
        server.notify(requester, "Vehicle Management", "You have no vehicles to clean up", NOTIFICATION_TYPE.COMPLETE_MISSION)
        return
    end

    for id, _ in pairs(group_data) do
        DespawnVehicleGroup(id)
    end

    server.notify(requester, "Vehicle Management", string.format("Cleaned up %d vehicles", TableLength(group_data)), NOTIFICATION_TYPE.COMPLETE_MISSION)

    if peer_id ~= requester then
        server.notify(peer_id, "Vehicle Management", "Your vehicles have been cleaned up by an admin", NOTIFICATION_TYPE.NETWORK_INFO)
    end
end
