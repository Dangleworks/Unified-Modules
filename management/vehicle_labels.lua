
function VehicleLabels()
    AddHook(hooks.onVehicleLoad, AddVehicleLabel)
end

function AddVehicleLabel(vehicle_id)
    local vehicle = GetUserVehicle(vehicle_id)
    if vehicle then
        local owner = GetPlayerByPeerId(vehicle.peer_id)
        local label = string.format("Owner: %s\nID: %d\n%s", owner.peer_id, vehicle_id, vehicle.filename)
        server.setVehicleTooltip(vehicle_id, label)
    end
end
