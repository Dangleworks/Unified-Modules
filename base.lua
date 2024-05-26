-- base addon module
hooks = {
    onTick="onTick",
    onCreate="onCreate",
    onDestroy="onDestroy",
    onCustomCommand="onCustomCommand",
    onChatMessage="onChatMessage",
    onPlayerJoin="onPlayerJoin",
    onPlayerSit="onPlayerSit",
    onCharacterSit="onCharacterSit",
    onPlayerRespawn="onPlayerRespawn",
    onPlayerLeave="onPlayerLeave",
    onToggleMap="onToggleMap",
    onPlayerDie="onPlayerDie",
    onVehicleSpawn="onVehicleSpawn",
    onVehicleLoad="onVehicleLoad",
    onVehicleTeleport="onVehicleTeleport",
    onVehicleDespawn="onVehicleDespawn",
    onVehicleUnload="onVehicleUnload",
    onVehicleDamaged="onVehicleDamaged",
    onSpawnAddonComponent="onSpawnAddonComponent",
    httpReply="httpReply",
    onFireExtinguished="onFireExtinguished",
    onForestFireSpawned="onForestFireSpawned",
    onForestFireExtinguished="onForestFireExtinguished",
    onButtonPress="onButtonPress",
    onObjectLoad="onObjectLoad",
    onObjectUnload="onObjectUnload",
    onGroupSpawn="onGroupSpawn"
}

hook_funcs = {}

function AddHook(hook, func)
    if not hook_funcs[hook] then hook_funcs[hook] = {} end
    table.insert(hook_funcs[hook], func)
end
