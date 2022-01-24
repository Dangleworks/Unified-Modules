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
    AddHook(hooks.onVehicleSpawn, CheckVehicleLimit)
    AddHook(hooks.onTick, UpdateVehicleCountPopup)
end

function SetupVehicleLimits(is_create)
    vehicle_uiid = server.getMapID()
    if not g_savedata.vehicle_limits then
        g_savedata.vehicle_limits = vehicle_limits_default_settings
    end

    for idx, player in pairs(server.getPlayers()) do
        SetBaseVehicleLimit(player.steam_id, player.name, player.id, player.admin, player.auth)
    end
end

function SetBaseVehicleLimit(steam_id, name, peer_id, is_admin, is_auth)
    -- TODO: Get vehicles limits from web service
    GetPlayerByPeerId(peer_id).vehicle_limit = g_savedata.vehicle_limits.base_vehicle_limit
end

function CheckVehicleLimit(vehicle_id, peer_id, x, y, z, cost)    
    -- Vehicle limit logic
    local cur_vehicles = GetUsersVehicles(peer_id)
    local num_vehicles = TableLength(cur_vehicles)
    local player = GetPlayerByPeerId(peer_id)

    if not player then return end

    if num_vehicles > player.vehicle_limit then
        local bypass = false
        if (player.is_admin and g_savedata.vehicle_limits.admin_bypass_vehicle_limit) or g_savedata.vehicle_limits.disable_vehicle_limit then
            bypass = true
        end

        if not bypass then
            if g_savedata.vehicle_limits.auto_despawn_vehicle_limit then
                -- TODO: does this break if vehicle limit = 1?
                local oldest = TableMinKey(cur_vehicles)
                server.notify(peer_id, "Vehicle Limit", string.format("Vehicle %d has been despawned to allow %d to spawn", oldest, vehicle_id), 6)
                server.despawnVehicle(oldest, true)
            else
                server.despawnVehicle(vehicle_id, true)
                server.notify(peer_id, "Vehicle Limit", string.format("You have reached your maxmimum spawned vehicle limit of %d", player.vehicle_limit), 6)
                return
            end
        end
    end
end

function UpdateVehicleCountPopup(ticks)
        -- TODO: Split vehicle spawn limits out into seperate module
        vpop_delay = vpop_delay + 1
        if vpop_delay > 60 then
            vpop_delay = 0
            for pid, player in pairs(player_list) do
                local vlimit = player.vehicle_limit
                local vehicles = GetUsersVehicles(pid)
                local vcount = TableLength(vehicles)
                if g_savedata.antilag.disable_vehicle_limit then
                    server.setPopupScreen(player.id, vehicle_uiid, "Vehicles", true, string.format("Vehicles: %d", vcount), 0.4, 0.88)
                else
                    server.setPopupScreen(player.id, vehicle_uiid, "Vehicles", true, string.format("Vehicles: %d/%d", vcount, vlimit), 0.4, 0.88)
                end
            end
        end
end

-- TODO: Get vehicle limits from web service
