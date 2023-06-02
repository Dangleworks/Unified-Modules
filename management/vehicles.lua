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
        local vehicle_id = tonumber(args[1])
        if not vehicle_id then
            server.announce("[Error]", "Please provide a valid vehicle id", user_peer_id)
            return
        end
        DespawnUserVehicle(vehicle_id, user_peer_id)
    end
end

function DespawnUserVehicle(vehicle_id, requester)
    local vehicle = GetUserVehicle(vehicle_id)
    if vehicle == nil then
        server.notify(requester, "Vehicle Management", "Vehicle not found", 1)
        return
    end

    if vehicle.peer_id == requester then
        server.despawnVehicle(vehicle_id, true)
        server.notify(requester, "Vehicle Management", "Your vehicle has been despawned", 9)
    elseif requester == -1 or GetPlayerByPeerId(requester).is_admin then
        server.despawnVehicle(vehicle_id, true)
        server.notify(vehicle.peer_id, "Vehicle Management", "Your vehicle has been despawned by an admin", 1)
        server.notify(requester, "Vehicle Management", "Vehicle has been despawned", 9)
    else
        server.notify(requester, "Vehicle Management", "That vehicle does not belong to you", 1)
    end
end

function ClearUsersVehicles(peer_id, requester)
    local vehicles = GetUsersVehicles(peer_id)

    if requester == peer_id then
        DespawnVehicles(vehicles)
        server.notify(peer_id, "Vehicle Management", "Your vehicles have been cleaned up", 9)
    elseif requester == -1 or (GetPlayerByPeerId(requester) and GetPlayerByPeerId(requester).is_admin) then
        local count = DespawnVehicles(vehicles)
        server.notify(peer_id, "Vehicle Management", "Your vehicles have been cleaned up by an admin", 1)
        -- don't notify requester if requester is server
        if requester ~= -1 then
            server.notify(requester, "Vehicle Management", string.format("Cleaned up %d vehicles", count), 1)
        end
    else
        server.notify(peer_id, "Vehicle Management", "You do not have permission run this command", 1)
    end
end

-- Takes a list of vehicles to despawn; vid:vehicle_data
function DespawnVehicles(vehicles)
    local count = 0
    for vid, vehicle in pairs(vehicles) do
        server.despawnVehicle(vid, true)
        count = count + 1
    end
    return count
end
