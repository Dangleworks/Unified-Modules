-- vehicle tracking
require("base")
require("util.debug")

vehicle_group_list = {}
vehicle_list = {}

function VehicleTracking()
    AddHook(hooks.onGroupSpawn, TrackVehicleGroup)
    AddHook(hooks.onVehicleSpawn, TrackVehicle)
    AddHook(hooks.onVehicleDespawn, UntrackVehicle)
    AddHook(hooks.onVehicleLoad, TrackVehicleLoad)
end

function TrackVehicleGroup(group_id, peer_id, x, y, z, cost)
    if peer_id == -1 then return end

    if vehicle_group_list[group_id] ~= nil then return end
    
    vehicle_group_list[group_id] = {
       group_id=group_id,
       peer_id=peer_id,
       spawn_coords={x=x,y=y,z=z},
       cost=cost,
       loaded=false
   }
end

-- Track the group for each vehicle
function TrackVehicle(vehicle_id, peer_id, x, y, z, group_cost, group_id)
    if peer_id == -1 then return end
    if vehicle_list[vehicle_id] ~= nil then return end

    vehicle_list[vehicle_id] = group_id
end

function TrackVehicleLoad(vehicle_id)
    local group_data = GetInternalVehicleGroupDataByVehicleId(vehicle_id)
    if group_data == nil then return end
    group_data.loaded = true
end

function UntrackVehicle(vehicle_id)
    if vehicle_list[vehicle_id] == nil then return end

    group_id = vehicle_list[vehicle_id]
    vehicles, ok = server.getVehicleGroup(group_id)
    vehicle_list[vehicle_id] = nil

    if not ok then return end

    -- Untrack the group if there are no more vehicles in it
    if #vehicles == 0 then
        vehicle_group_list[group_id] = nil
    end
end

function GetInternalVehicleGroupData(group_id)
    return vehicle_group_list[group_id]
end

function GetInternalVehicleGroupDataByVehicleId(vehicle_id)
    return GetInternalVehicleGroupData(vehicle_list[vehicle_id])
end

--- Get all vehicle group data entries for a specific peer
--- @param peer_id number The peer ID to search for
--- @return group_data table A table of vehicle group data entries indexed by group ID
function GetAllInternalVehicleGroupDataForPeer(peer_id)
    local group_data = {}
    for group_id, data in pairs(vehicle_group_list) do
        if data.peer_id == peer_id then
            group_data[group_id] = data
        end
    end

    return group_data
end

function DespawnVehicleGroup(group_id)
    ok = server.despawnVehicleGroup(group_id, true)
    if not ok then return end

    vehicle_group_list[group_id] = nil
end

function VehicleTrackingCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if is_admin and (command == "?vehiclelist" or command == "?vl") then
        if #args == 0 then
            for vid, vehicle in pairs(vehicle_group_list) do
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

            for vid, vehicle in pairs(vehicle_group_list) do
                local data = string.format("%d ", vid)
                for _, field in ipairs(selected_fields) do
                    if field == "position" then
                        local pos, ok = server.getVehiclePos(vid,0,0,0)
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
        local vid = tonumber[args[1]]
        local data, ok = server.getVehicleData(vid)
        if not ok then
            server.announce("[VEHICLE DATA]", "Could not get data for that vehicle", user_peer_id)
            return
        end
        server.announce("[VEHICLE DATA] "..args[1], debugutils.DumpTable(data), user_peer_id)
    end
end
