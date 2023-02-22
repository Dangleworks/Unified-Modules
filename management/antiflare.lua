require("base")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.help")
require("util.notify")

lastRefObjectId = 0
nextRefObjectId = 0
objectSpawnTimer = 0

function AntiFlare()
    AddHook(hooks.onTick, AntiFlareTick)
    AddHook(hooks.onCreate, AntiFlareCreate)
end

function AntiFlareCreate(is_world_create)
    local zones = server.getZones("ref_object_area")
	if zones[1] ~= nil then
		object_spawn_area = zones[1]
	end
end

local banned_obj_types = {57,62,63,68}

function AntiFlareTick(game_ticks)
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
                    OBJECT_DATA = server.getObjectData(i)
					if OBJECT_DATA ~= nil then
                        for _, v in ipairs(banned_obj_types) do
                            if OBJECT_DATA.object_type == v then
                                server.despawnObject(i, true)
                                count = count + 1
                            end
                        end
					end
                end
                if count > 0 then
                    notifyAdmins("Anti-Flare", string.format("Despawned %d flares", count))
                end
            end
            lastRefObjectId = oid
            server.despawnObject(oid, true)
        end
    end
end