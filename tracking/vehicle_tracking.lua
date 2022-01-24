-- vehicle tracking
require("base")
require("util.debug")

vehicle_list = {}

function VehicleTracking()
    AddHook(hooks.onVehicleLoad, TrackVehicleLoaded)
    AddHook(hooks.onVehicleSpawn, TrackVehicle)
    AddHook(hooks.onVehicleDespawn, UntrackVehicle)
end


function TrackVehicle(vehicle_id, peer_id, x, y, z, cost)
    if peer_id == -1 then return end
    
    vehicle_list[vehicle_id] = {
       peer_id=peer_id,
       spawn_coords={x=x,y=y,z=z},
       cost=cost,
       loaded=false,
       mass=0,
       voxels=0,
       filename="not loaded"
   }
end

function TrackVehicleLoaded(vehicle_id)
    if vehicle_list[vehicle_id] ~= nil then
        vd, ok = server.getVehicleData(vehicle_id)
        if ok then
            vehicle_list[vehicle_id].loaded = true
            vehicle_list[vehicle_id].mass = vd.mass
            vehicle_list[vehicle_id].voxels = vd.voxels
            vehicle_list[vehicle_id].filename = vd.filename
        end
    end
end

function UntrackVehicle(vehicle_id)
    vehicle_list[vehicle_id] = nil
end

function GetUsersVehicles(peer_id)
    local vehicles = {}
    for vid, vehicle in pairs(vehicle_list) do
        if vehicle.peer_id == peer_id then
            vehicles[vid] = vehicle
        end
    end

    return vehicles
end

function GetUserVehicle(vehicle_id)
    return vehicle_list[vehicle_id]
end

function VehicleTrackingCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if is_admin and (command == "?vehiclelist" or command == "?vl") then
        if #args == 0 then
            for vid, vehicle in pairs(vehicle_list) do
                server.announce("[VEHICLE LIST]", string.format("%d: %s - %d", vid, vehicle.filename, vehicle.peer_id), user_peer_id)
            end
        else
            local available_fields = {"name", "mass", "voxels", "cost", "position"}
            local selected_fields = {}
            for _, arg in ipairs(args) do
                arg = string.lower(arg)
                for _, field in ipairs(available_fields) do
                    if arg == field then table.insert(selected_fields, field) end
                end
            end

            for vid, vehicle in pairs(vehicle_list) do
                local data = string.format("%d ", vid)
                for _, field in ipairs(selected_fields) do
                    if field == "position" then
                        local pos, ok = server.getVehiclePos(vid)
                        if ok then
                            local x,y,z = matrix.position(pos)    
                            data = data..string.format("| X%.1f,Y%.1f,Z%.1f", x,y,z)
                        else
                            data = data.."| [pos unknown]"
                        end
                    else
                        data = data..tostring(vehicle[field])
                    end
                end
                server.announce("[VEHICLE LIST]", data, user_peer_id)
            end
        end

        return
    end

    if is_admin and command == "?vehicle" and args[1] and tonumber(args[1]) then
        local vid = tonumber[args1]
        local vehicle = GetUserVehicle(vid)
        if not vehicle then
            server.announce("[VEHICLE DATA]", "Vehicle not found", user_peer_id)
            return
        end
        server.announce("[VEHICLE DATA] "..args[1], debugutils.DumpTable(vehicle), user_peer_id)
    end
end
