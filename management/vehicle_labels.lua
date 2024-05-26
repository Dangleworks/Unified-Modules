require("tracking.vehicle_tracking")
require("tracking.player_tracking")

function VehicleLabels()
    AddHook(hooks.onVehicleLoad, AddVehicleLabel)
end

function AddVehicleLabel(vehicle_id)
    local group_data = GetInternalVehicleGroupDataByVehicleId(vehicle_id)

    if not group_data then return end

    local owner = GetPlayerByPeerId(group_data.peer_id)
    local label = string.format("Owner: %s (%d)\nID: %d", owner.name, owner.peer_id, group_data.group_id)
    
    server.setVehicleTooltip(vehicle_id, label)
end
