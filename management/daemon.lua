require("base")
require("tracking.player_tracking")
require("tracking.vehicle_tracking")
require("util.json")
require("util.url")
require("util.notify")
require("util.table")

last_report_time = 0
daemon_port = 8080

admins = {}
mods = {}

function Daemon()
    AddHook(hooks.onCreate, DaemonSetup)
    AddHook(hooks.onTick, DaemonCheckin)
    AddHook(hooks.httpReply, DaemonCheckinReply)
    AddHook(hooks.onChatMessage, LogChat)
    AddHook(hooks.onPlayerJoin, LogJoin)
    AddHook(hooks.onPlayerLeave, LogLeave)
    AddHook(hooks.onCustomCommand, DaemonProcessCommand)
end

function DaemonSetup(is_world_create)
end

function LogChat(user_peer_id, sender_name, message)
    local player = GetPlayerByPeerId(user_peer_id)
    server.httpGet(daemon_port, string.format("/chat?key=%s&message=%s&sender=%s&sender_name=%s", key, urlencode(message), player.steam_id, urldecode(sender_name)))
end

function LogJoin(steam_id, name, peer_id, is_admin, is_auth)
    server.httpGet(daemon_port, string.format("/player/join?key=%s&steam_id=%s&name=%s&peer_id=%s&is_admin=%s&is_auth=%s", key, steam_id, name, peer_id, is_admin, is_auth))
end

function LogLeave(steam_id, name, peer_id, is_admin, is_auth)
    server.httpGet(daemon_port, string.format("/player/leave?key=%s&steam_id=%s&name=%s&peer_id=%s&is_admin=%s&is_auth=%s", key, steam_id, name, peer_id, is_admin, is_auth))
end

function DaemonProcessCommand(full_message, user_peer_id, is_admin, is_auth, command, args)
    if command == "?report" then
        if not is_auth then
            server.announce("[ERROR]", "You must be authorized to use this command.", user_peer_id)
            return
        end
        server.httpGet(
            daemon_port, 
            string.format(
                "/player-report?key=%s&player=%s&details=%s", 
                key, 
                user_peer_id,
                TableSlice(args, 1)
            )
        )
        return
    end
    -- All commands after this point require admin
    if is_admin == false then
        server.announce("[ERROR]", "You must be an admin to use this command.", user_peer_id)
        return
    end
    if command == "?pban" then
        local player = args[1]
        local reason = table.concat(TableSlice(args, 2), " ")
        server.httpGet(
            daemon_port,
            string.format(
                "/ban/add?key=%s&player=%s&submitter=%s&reason=%s",
                key,
                player,
                user_peer_id,
                urlencode(reason)
            )
        )
        return
    end

    if command == "?tban" then
        local player = args[1]
        local duration = args[2]
        local reason = table.concat(TableSlice(args, 3), " ")
        server.httpGet(
            daemon_port, 
            string.format(
                "/ban/add?key=%s&player=%s&submitter=%s&reason=%s&duration=%s", 
                key, 
                player, 
                user_peer_id, 
                urlencode(reason),
                duration
            )
        )
        return
    end

    if command == "?warn" then
        local player = args[1]
        local reason = table.concat(TableSlice(args, 2), " ")
        server.httpGet(
            daemon_port, 
            string.format(
                "/warn/add?key=%s&player=%s&submitter=%s&reason=%s", 
                key, 
                player, 
                user_peer_id, 
                urlencode(reason)
            )
        )
        return
    end

    server.httpGet(
        daemon_port, 
        string.format(
            "/moderation-log/add?key=%s&player=%s&action=%s&details=%s", 
            key, 
            user_peer_id, 
            "command", 
            urlencode(full_message)
        )
    )
end

function DaemonCheckin(game_ticks)
    local ctime = server.getTimeMillisec()
    if ctime - last_report_time >= 5000 then
        last_report_time = ctime
        local report = {}
        --report.players = server.getPlayers()
        --report.settings = server.getGameSettings()
        report.tps = tps
        report.tps_avg = tps_avg
        --report.vehicles = vehicle_list
        report.uptime = ctime
        local data = urlencode(json.stringify(report))
        server.httpGet(daemon_port, string.format("/checkin?key=%s&data=%s", key, data))
    end
end

function DaemonCheckinReply(port, request, reply)
    if daemon_port ~= port then return end

    local data = json.parse(reply)
    if data == nil then return end
    if data.error ~= nil then
        debug.log("[DEBUG] ERROR: Received error in daemon response: "..data.error)
        return
    end

    if data.action == "checkin" then
        admins = data.admins
        mods = data.moderators
        return
    end
end