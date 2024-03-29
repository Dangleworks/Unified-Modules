require("base")
require("tracking.player_tracking")

function Jail()
    AddHook(hooks.onCustomCommand, JailCommand)
    AddHook(hooks.onCreate, JailCreate)
    AddHook(hooks.onTick, JailTick)
end

function JailCreate(is_world_create)
    local zones = server.getZones("jail")
	if zones[1] ~= nil then
		jail_zone = zones[1]
	end
	
	 zones = server.getZones("release")
     if zones[1] ~= nil then
		release_zone = zones[1]
	end
end

function JailTick(game_ticks)
    for pid, player in pairs(player_list) do
        if player.jailed then
            local ploc, ok = server.getPlayerPos(pid)
            if ok then
                in_zone, _ = server.isInZone(ploc, "Jail Zone")
                if not in_zone then
                    server.setPlayerPos(pid, jail_zone.transform)
                end
            end
        end
    end
end

function JailCommand(full_message, user_peer_id, is_admin, is_auth, command, args)
    if not is_admin then return end
    command = string.lower(command)
    local release = false
    
    if command == "?jail" or command == "?j" then
        release = false
    elseif command == "?release" or command == "?r" then
        release = true
    else
        return
    end

    local targ_pid = tonumber(args[1])
    if targ_pid == nil then
    	server.announce("[JAIL]", "Please provide a valid peer ID", user_peer_id)
        return
    end

    local player = GetPlayerByPeerId(targ_pid)
    if not player then
        server.announce("[JAIL]", "Player not found", user_peer_id)
		return
    end

    if not release then
        if not player.jailed then
            player.jailed = true
            server.announce("[Server]", string.format("%s has been thrown in jail!", player.name), -1)
        else
            server.announce("[JAIL]", "Player is already in jail", user_peer_id)
        end
    else
        if not player.jailed then
            server.announce("[JAIL]", "Player is not in jail", user_peer_id)
        else
            player.jailed = false
            server.setPlayerPos(player.peer_id, release_zone.transform)
            server.announce("[JAIL]", "Player has been released from jail", user_peer_id)
            server.announce("[JAIL]", "You have been released from jail. Please be mindful of your behavior.", player.peer_id)
        end
    end
end
