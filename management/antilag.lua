require("base")
require("util.buffer")
require("util.table")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.debug")
require("util.notify")

---@section AntiLag
antilag_default_settings = {
    max_mass = 100000,
    tps_threshold = 45,
    load_time_threshold = 8000,
    tps_recover_time = 4000,
    tps_avg_diff_threshold = 15,
    vehicle_stabilize_chances = 1
}

ticks, tps, tps_avg, ticks_time, vpop_delay = 0, 0, 0, 0, 0

function AntiLag()
    AddHook(hooks.onCreate, AntilagOnCreate)
    AddHook(hooks.onTick, CalculateTPS)
    AddHook(hooks.onTick, AntilagOnTick)
    AddHook(hooks.onGroupSpawn, AntilagOnVehicleGroupSpawn)
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

    for group_id, group_data in pairs(vehicle_group_list) do
        if group_data.antilag then
            local spawn_time = group_data.antilag.spawn_time
            local dtime = ctime - spawn_time
            if not group_data.loaded then
                if dtime > g_savedata.antilag.load_time_threshold then
                    DespawnVehicleGroup(group_id)
                    server.notify(group_data.peer_id, "Antilag", string.format("Your vehicle was despawned for exceeding the maxmimum load time of %.1f seconds.", g_savedata.antilag.load_time_threshold), 6)
                    -- todo: notify admins or log
                    notifyAdmins("Antilag", string.format("Vehicle %d was despawned for exceeding the maxmimum load time of %.2f seconds. (%.2f)", group_id, g_savedata.antilag.load_time_threshold/1000, dtime/1000))
                end
            elseif not group_data.antilag.cleared and dtime > g_savedata.antilag.tps_recover_time then
                local avg_ok = (group_data.antilag.spawn_tps_avg - tps_avg) < g_savedata.antilag.tps_avg_diff_threshold
                local ins_ok = (group_data.antilag.spawn_tps - tps) < g_savedata.antilag.tps_threshold

                if not avg_ok and ins_ok and group_data.antilag.stabilize_count < g_savedata.antilag.vehicle_stabilize_chances then
                    group_data.antilag.spawn_time=ctime
                    group_data.antilag.stabilize_count = group_data.antilag.stabilize_count + 1
                elseif not avg_ok and not ins_ok then
                    server.notify(group_data.peer_id, "Antilag", string.format("Vehicle %d was despawned. Server FPS did not stabilize in time (%0.2f to %0.2f)", group_id, group_data.antilag.spawn_tps, tps), 6)
                    DespawnVehicleGroup(group_id)
                    notifyAdmins("Antilag", string.format("Vehicle %d was despawned. Server FPS did not stabilize in time (%0.2f to %0.2f)", group_id, group_data.antilag.spawn_tps, tps))
                    -- todo: notifty admins or log
                elseif not avg_ok and ins_ok then
                    server.notify(group_data.peer_id, "Antilag", string.format("Vehicle %d was despawned. Average FPS did not recover in time (%0.2f to %0.2f)", group_id, group_data.antilag.spawn_tps_avg, tps_avg), 6)
                    --todo: notify admins and log
                    DespawnVehicleGroup(group_id)
                    notifyAdmins("Antilag", string.format("Vehicle %d was despawned. Average FPS did not recover in time (%0.2f to %0.2f)", group_id, group_data.antilag.spawn_tps_avg, tps_avg))
                elseif avg_ok and ins_ok then
                    group_data.antilag.cleared = true
                end
            end
        else
            debug.log("[DEBUG] ERROR: Antilag not present on vehicle record")
        end
    end
end

function AntilagOnVehicleGroupSpawn(group_id, peer_id, x, y, z, cost)
    if peer_id == -1 then return end

    if not spawning then
        server.despawnVehicleGroup(group_id, true)
        server.notify(peer_id, "Antilag", "Vehicle spawning is temporarily disabled by antilag because server FPS is too low", 6)
        return
    end

    local internal_group_data = GetInternalVehicleGroupData(group_id)
    if not internal_group_data then
        notifyAdmins("Antilag Error", "Failed to get internal group data during a group spawn event")
        return
    end

    internal_group_data.antilag = {
        spawn_time = server.getTimeMillisec(),
        spawn_tps = tps,
        spawn_tps_avg = tps_avg,
        cleared = false,
        stabilize_count = 0
    }
end
---@endsection