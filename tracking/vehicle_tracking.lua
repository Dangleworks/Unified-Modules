-- vehicle tracking
require("base")

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