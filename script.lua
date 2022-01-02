
require("base")
require("tracking.player_tracking")
require("tracking.vehicle_tracking")
require("management.vehicles")
require("management.vehicle_labels")
require("management.antisteal")
require("management.antilag")
require("management.vehicle_limits")

-- Module order defines execution order. Put dependancies first.
modules={
    VehicleTracking,
    PlayerTracking,
    VehicleLabels,
    VehicleManagement,
    AntiSteal,
    VehicleLimits,
    AntiLag
}

function onCreate(is_world_create)
    for _, f in ipairs(modules) do
        f()
    end

    if hook_funcs[hooks.onCreate] then
        for _, f in ipairs(hook_funcs[hooks.onCreate]) do
            f(is_world_create)
        end
    end
end

function onTick(game_ticks)
    if hook_funcs[hooks.onTick] then
        for _, f in ipairs(hook_funcs[hooks.onTick]) do
            f(game_ticks)
        end
    end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
    if hook_funcs[hooks.onPlayerJoin] then
        for _, f in ipairs(hook_funcs[hooks.onPlayerJoin]) do
            f(steam_id, name, peer_id, is_admin, is_auth)
        end
    end
end

function onPlayerLeave(steam_id, name, peer_id, is_admin, is_auth)
    if hook_funcs[hooks.onPlayerLeave] then
        for _, f in ipairs(hook_funcs[hooks.onPlayerLeave]) do
            f(steam_id, name, peer_id, is_admin, is_auth)
        end
    end
end

function onVehicleSpawn(vehicle_id, peer_id, x, y, z, cost)
    if hook_funcs[hooks.onVehicleSpawn] then
        for _, f in ipairs(hook_funcs[hooks.onVehicleSpawn]) do
            f(vehicle_id, peer_id, x, y, z, cost)
        end
    end
end

function onVehicleLoad(vehicle_id)
    if hook_funcs[hooks.onVehicleLoad] then
        for _, f in ipairs(hook_funcs[hooks.onVehicleLoad]) do
            f(vehicle_id)
        end
    end
end

function onVehicleDespawn(vehicle_id, peer_id)
    if hook_funcs[hooks.onVehicleDespawn] then
        for _, f in ipairs(hook_funcs[hooks.onVehicleDespawn]) do
            f(vehicle_id, peer_id)
        end
    end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, ...)
    local args = {...}
    if hook_funcs[hooks.onCustomCommand] then
        for _, f in ipairs(hook_funcs[hooks.onCustomCommand]) do
            f(full_message, user_peer_id, is_admin, is_auth, command, args)
        end
    end
end