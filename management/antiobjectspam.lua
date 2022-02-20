require("base")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.help")
require("util.notify")

lastRefObjectId = 0
nextRefObjectId = 0
objectSpawnTimer = 0

function AntiObjectSpam()
    AddHook(hooks.onTick, AntiObjectSpamTick)
    AddHook(hooks.onCreate, AntiObjectSpamCreate)
end

function AntiObjectSpamCreate(is_world_create)
    local zones = server.getZones("ref_object_area")
	if zones[1] ~= nil then
		object_spawn_area = zones[1]
	end
end


function AntiObjectSpamTick(game_ticks)
    objectSpawnTimer = objectSpawnTimer + 1
    if objectSpawnTimer > 30 then
        objectSpawnTimer = 0
        -- spawn a pencil
        local oid, ok = server.spawnObject(object_spawn_area.transform, 48)
        if ok then
            if lastRefObjectId == 0 then lastRefObjectId = oid end

            if oid - lastRefObjectId > 5 then
                local count = 0
                for i = lastRefObjectId, oid, 1 do
                    if server.despawnObject(i, true) then
                        count = count + 1
                    end
                end
                notifyAdmins("Anti-Object Spam", string.format("Despawned %d objects", count))
            end
            lastRefObjectId = oid
            server.despawnObject(oid, true)
        end
    end
end