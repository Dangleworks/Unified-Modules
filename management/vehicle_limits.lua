require("base")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.table")

vehicle_limits_default_settings = {
    base_vehicle_limit = 1,
    auth_vehicle_limit = 3,
    auto_despawn_vehicle_limit = true,
    admin_bypass_vehicle_limit = false,
    disable_vehicle_limit = false
}

function VehicleLimits()
    AddHook(hooks.onCreate, SetupVehicleLimits)
    AddHook(hooks.onPlayerJoin, SetBaseVehicleLimit)
    AddHook(hooks.onGroupSpawn, CheckVehicleLimit)
    AddHook(hooks.onTick, UpdateVehicleCountPopup)
end

function SetupVehicleLimits(is_create)
    vehicle_uiid = server.getMapID()
    if not g_savedata.vehicle_limits then
        g_savedata.vehicle_limits = vehicle_limits_default_settings
    end

    for _, player in pairs(server.getPlayers()) do
        SetBaseVehicleLimit(player.steam_id, player.name, player.id, player.admin, player.auth)
    end
end

function SetBaseVehicleLimit(steam_id, name, peer_id, is_admin, is_auth)
    -- TODO: Get vehicles limits from web service
    GetPlayerByPeerId(peer_id).vehicle_limit = g_savedata.vehicle_limits.base_vehicle_limit
end

function CheckVehicleLimit(group_id, peer_id, x, y, z, cost)
    local group_data = GetAllInternalVehicleGroupDataForPeer(peer_id)
    local num_vehicles = TableLength(group_data)
    local player = GetPlayerByPeerId(peer_id)

    if not player then return end

    local bypass = (player.is_admin and g_savedata.vehicle_limits.admin_bypass_vehicle_limit) or
    g_savedata.vehicle_limits.disable_vehicle_limit
    if bypass then return end

    if num_vehicles > player.vehicle_limit then
        if g_savedata.vehicle_limits.auto_despawn_vehicle_limit then
            --- @type InternalGroupData
            local oldest = group_data[TableMinKey(group_data)]
            server.notify(peer_id, "Vehicle Limit",
                string.format("Vehicle %d has been despawned to allow %d to spawn", oldest.group_id, group_id), 6)
            server.despawnVehicleGroup(oldest.group_id, true)
        else
            server.despawnVehicleGroup(group_id, true)
            server.notify(peer_id, "Vehicle Limit",
                string.format("You have reached your maxmimum spawned vehicle limit of %d", player.vehicle_limit), 6)
            return
        end
    end
end

function UpdateVehicleCountPopup(ticks)
    vpop_delay = vpop_delay + 1
    if vpop_delay > 60 then
        vpop_delay = 0
        for peer_id, player in pairs(player_list) do
            if not server.getPlayerName(peer_id) then
                debug.log("[DEBUG] UpdateVehicleCountPopup - could not find player name for peer_id: " .. peer_id)
                goto continue
            end

            local vehicle_limit = player.vehicle_limit
            local group_data = GetAllInternalVehicleGroupDataForPeer(player.peer_id)
            local vehicle_count = TableLength(group_data)
            if g_savedata.vehicle_limits.disable_vehicle_limit then
                server.setPopupScreen(player.peer_id, vehicle_uiid, "Vehicles", true,
                string.format("Vehicles: %d", vehicle_count), 0.4, 0.88)
            else
                server.setPopupScreen(player.peer_id, vehicle_uiid, "Vehicles", true,
                string.format("Vehicles: %d/%d", vehicle_count, vehicle_limit), 0.4, 0.88)
            end
            
            ::continue::
        end
    end
end

-- TODO: Get vehicle limits from web service
