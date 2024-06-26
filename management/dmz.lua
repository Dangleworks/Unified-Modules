require("base")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")

dmz_default_settings = {
    radius = 1000
}

zone_check_delay = 0

function DMZ()
    AddHook(hooks.onCreate, SetupDMZ)
    AddHook(hooks.onTick, ProcessZones)
    AddHook(hooks.onPlayerJoin, DMZPlayerJoin)
end

function DMZPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	addDMZZones(peer_id)
end

function addDMZZones(peer_id)
	for _, zone in pairs(dmz_zones) do
		local x,y,z = matrix.position(zone.transform)
		server.addMapObject(peer_id, dmz_uiid, 0, 8, x, z, 0, 0, 0, 0, "No PvP Zone", g_savedata.dmz.radius, "NO PVP IN GREEN ZONE", 0, 255, 0, 255)
	end
end

function SetupDMZ(world_create)
    dmz_uiid = server.getMapID()
    dmz_zones = server.getZones("dmz")
    if not g_savedata.dmz then
        g_savedata.dmz = dmz_default_settings
    end

    for pid, player in pairs(player_list) do
        player.dmz = {}
        player.dmz.in_zone = false
    end
end

function ProcessZones(game_ticks)
    if zone_check_delay < 60 then
        zone_check_delay = zone_check_delay + 1
        return
    end
    zone_check_delay = 0
    -- TODO: Only run every 1 second (60 ticks)
    for pid, player in pairs(player_list) do
        local ppos, ok = server.getPlayerPos(pid)
        if ok then
            local in_zone = false
            for _, zone in pairs(dmz_zones) do
                if matrix.distance(ppos, zone.transform) < g_savedata.dmz.radius then
                    in_zone = true
                end
            end

            if not player.dmz then player.dmz = {} end
            if player.dmz.in_zone == nil then player.dmz.in_zone = false end

            --if in_zone then
            --    local cid = server.getPlayerCharacterID(player.peer_id)
            --    local cd = server.getCharacterData(cid)
            --    if cd.hp < 100 then
            --        server.setCharacterData(cid, 100, true, false)
            --    end
            --    if cd.incapacitated then
            --        server.reviveCharacter(cid)
            --    end
            --end

            if in_zone and not player.dmz.in_zone then
                server.notify(pid, "DMZ", "You are now in a DMZ - PvP is not allowed in this zone", 9)
                server.setPopupScreen(pid, dmz_uiid, "pvp", true, "You are in a DMZ\n\nNo PvP is allowed in this zone", 0.88, -0.7)
                player.dmz.in_zone = true
            elseif not in_zone and player.dmz.in_zone then
                server.notify(pid, "DMZ", "You have left the DMZ and are clear to engage all targets outside of the zone", 2)
                server.removePopup(pid, dmz_uiid)
                player.dmz.in_zone = false
            end
        end
    end

    for vid, vehicle in pairs(vehicle_list) do
        local in_zone = false
        local vpos, ok = server.getVehiclePos(vid,0,0,0)
        if ok then
            for _, zone in pairs(dmz_zones) do
               if matrix.distance(vpos, zone.transform) < g_savedata.dmz.radius then
                   in_zone = true
               end
            end

            local data, _ = server.getVehicleData(vid)
            if in_zone and not data.invulnerable then
                server.setVehicleInvulnerable(vid, true)
            elseif not in_zone and data.invulnerable then
                server.setVehicleInvulnerable(vid, false)
            end
        end
    end
end