require("base")
require("util.buffer")
require("util.table")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.debug")

antilag_default_settings = {
    max_mass = 100000,
    tps_threshold = 45,
    load_time_threshold = 3000,
    tps_recover_time = 4000,
    tps_avg_diff_threshold = 15,
    vehicle_stabilize_chances = 1
}

ticks, tps, tps_avg, ticks_time, vpop_delay = 0, 0, 0, 0, 0

function AntiLag()
    AddHook(hooks.onCreate, AntilagOnCreate)
    AddHook(hooks.onTick, CalculateTPS)
    AddHook(hooks.onTick, AntilagOnTick)
    AddHook(hooks.onVehicleSpawn, AntilagOnVehicleSpawn)
    AddHook(hooks.onVehicleLoad, AntilagOnVehicleLoad)
end

function AntilagOnCreate()
    tps_uiid = server.getMapID()

    if not g_savedata.antilag then
        g_savedata.antilag = antilag_default_settings
    end
    tps_buff = NewBuffer(g_savedata.antilag.tps_recover_time/500)
end

function CalculateTPS(game_ticks)
    ticks = ticks + 1
    local ctime = server.getTimeMillisec()
    if  ctime - ticks_time >= 500 then
        tps = ticks*2
        ticks = 0
        ticks_time = ctime
        tps_buff.Push(tps)
        tps_avg = TableMean(tps_buff.values)
        for _, p in pairs(server.getPlayers()) do
            server.setPopupScreen(p.id, tps_uiid, "FPS", true, string.format("FPS: %.1f\n(AVG:%.1f)", tps, tps_avg), 0.56, 0.88)
        end
    end
end

function AntilagOnTick(game_ticks)
    local ctime = server.getTimeMillisec()
    if tps < g_savedata.antilag.tps_threshold then
        spawning = false
    else
        spawning = true
    end

    if server.getGameSettings().vehicle_spawning and not spawning then
        server.setGameSetting("vehicle_spawning", false)
    elseif not server.getGameSettings().vehicle_spawning and spawning then
        server.setGameSetting("vehicle_spawning", true)
    end

    for vid, vehicle in pairs(vehicle_list) do
        local spawn_time = vehicle.antilag.spawn_time
        if not spawn_time then spawn_time = ctime end

        local dtime = ctime - spawn_time
        if not vehicle.loaded then
            if dtime > g_savedata.antilag.load_time_threshold then
                server.despawnVehicle(vid, true)
                server.notify(vehicle.peer_id, "Antilag", string.format("Your vehicle was despawned for exceeding the maxmimum load time of %.1f seconds.", g_savedata.antilag.load_time_threshold), 6)
                -- todo: notify admins or log
            end
        elseif not vehicle.antilag.cleared and dtime > g_savedata.antilag.tps_recover_time then
            local avg_ok = (vehicle.antilag.spawn_tps_avg - tps_avg) < g_savedata.antilag.tps_avg_diff_threshold
            local ins_ok = (vehicle.antilag.spawn_tps - tps) < g_savedata.antilag.tps_threshold

            if not avg_ok and ins_ok and vehicle.antilag.stabilize_count < g_savedata.antilag.vehicle_stabilize_chances then
                vehicle.antilag.spawn_time=ctime
                vehicle.antilag.stabilize_count = vehicle.antilag.stabilize_count + 1
            elseif not avg_ok and not ins_ok then
                server.notify(vehicle.peer_id, "Antilag", string.format("Vehicle %d was despawned. Server FPS did not stabilize in time (%0.2f to %0.2f)", vid, vehicle.antilag.spawn_tps, tps), 6)
                server.despawnVehicle(vid, true)
                -- todo: notifty admins or log
            elseif not avg_ok and ins_ok then
                server.notify(vehicle.peer_id, "Antilag", string.format("Vehicle %d was despawned. Average FPS did not recover in time (%0.2f to %0.2f)", vid, vehicle.antilag.spawn_tps_avg, tps_avg), 6)
                --todo: notify admins and log
                server.despawnVehicle(vid, true)
            elseif avg_ok and ins_ok then
                vehicle.antilag.cleared = true
            end
        end
    end
end

function AntilagOnVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
    if peer_id == -1 then return end

    if not spawning then
        server.despawnVehicle(vehicle_id, true)
        server.notify(peer_id, "Antilag", "Vehicle spawning is temporarily disabled by antilag because server FPS is too low", 6)
        return
    end

    -- do this instead of using cur_vehicles to make sure it's being set to the actual vehicle record
    GetUserVehicle(vehicle_id).antilag = {
        spawn_time = server.getTimeMillisec(),
        spawn_tps = tps,
        spawn_tps_avg = tps_avg,
        cleared = false,
        stabilize_count = 0
    }
end

function AntilagOnVehicleLoad(vehicle_id)
    local vehicle = GetUserVehicle(vehicle_id)
    if not vehicle then return end
    
    if vehicle.mass >= g_savedata.antilag.max_mass then
        server.despawnVehicle(vehicle_id, true)
        server.notify(vehicle.peer_id, "Antilag", string.format("Your vehicle was despawned for being an absolute chonker (Weight Limit: %d)", g_savedata.antilag.max_mass), 6)
        return
    end

    vehicle.antilag.spawn_time = server.getTimeMillisec()
end
