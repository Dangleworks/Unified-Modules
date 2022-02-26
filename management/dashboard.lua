require("base")
require("tracking.player_tracking")
require("util.json")
require("util.url")

last_report_time = 0
dashboard_port = 3002

function Dashboard()
    AddHook(hooks.onCustomCommand, DashboardLogCommand)
    AddHook(hooks.onCreate, DashboardSetup)
    AddHook(hooks.onTick, ReportData)
    AddHook(hooks.httpReply, DashboardReply)
end

function DashboardSetup(is_world_create)
end

function DashboardLogCommand(full_message, user_peer_id, is_admin, is_auth, command, args)

end

function ReportData(game_ticks)
    local ctime = server.getTimeMillisec()
    if ctime - data_report_timer >= 1000 then
        last_report_time = ctime
        local report = {}
        report.players = server.getPlayers()
        report.settings = server.getGameSettings()
        report.tps = tps
        report.tps_avg = tps_avg
        report.vehicles = vehicle_list
        report.uptime = ctime
        server.httpGet(dashboard_port, string.format("/game/dashboard?key=%s&data=%s"), urlencode(json.stringify(report)))
    end
end

function DashboardReply(port, request, reply)
    if port ~= dashboard_port then return end
    if string.match(request, "^/game/dashboard.+") then
        local data = json.parse(reply)
        if data.error then
            debug.log("[DEBUG] ERROR DashboardReply: "..data)
            return
        end
    end
end