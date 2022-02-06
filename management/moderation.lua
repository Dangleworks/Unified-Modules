require("base")
require("tracking.vehicle_tracking")
require("tracking.player_tracking")
require("util.json")
require("util.url")
require("util.help")

moderation_port = 3002
-- IMPORTANT: Replace this value with your actual API key
key = "potato"

function Moderation()
    AddHook(hooks.onCustomCommand, ModerationCommands)
    AddHook(hooks.onPlayerJoin, CheckPlayerBanned)
    AddHook(hooks.httpReply, ModerationHttpResponse)
    AddHelpEntry("moderation", {
        {"?gban peer_id [[temp] time] [reason]", "Temp ban player - ex: ?gban 4 temp 5h Spamming and trolling", true},
        {"?gban peer_id [reason]", "Perma ban player - ex: ?gban 4 Spawning lag bombs", true},
    })
end

function ModerationCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if not is_admin then return end
    if not (command == "?gban" or command =="?deauth") then return end
    if not args[1] or not tonumber(args[1]) then
        server.announce("[MODERATION]", "Please provide a peer id", user_peer_id)
        return
    end
    local peer_id = tonumber(args[1])
    if command == "?gban" then
        local player = GetPlayerByPeerId(peer_id)
        if not player then
            server.announce("[MODERATION]", "Player not found", user_peer_id)
            return
        end

        local issuer = GetPlayerByPeerId(user_peer_id).steam_id
        local steam_id = player.steam_id
        local temp = false
        local time = ""
        local reason = "Unspecified"
        local reasonStart = 0
        -- ?gban <peer_id> temp <time> [reason]
        if args[2] and args[2] == "temp" and args[3] then
            temp = true
            time = args[3]
            reasonStart = 4
        -- ?gban <peer_id> [reason]
        else
            reasonStart = 2
        end
        if #args >= reasonStart then
            reason = ""
            for i=reasonStart, #args do
                reason = reason.." "..args[i]
            end
        end
        GlobalBanPlayer(steam_id, temp, time, reason, issuer)
        return
    end

    if command == "?deauth" then
        
    end
end

function CheckPlayerBanned(steam_id, name, peer_id, is_admin, is_auth)
    GetPlayerRequest(steam_id, true)
end

function GlobalBanPlayer(steam_id, temp, time, reason, issuer)
    local reqString = ""
    if temp then
        reqString = string.format("/ban?steam_id=%s&issuer=%s&time=%s&reason=%s&key=%s", steam_id, issuer, time, urlencode(reason), key)
    else
        reqString = string.format("/ban?steam_id=%s&issuer=%s&permanent=true&reason=%s&key=%s", steam_id, issuer, urlencode(reason), key)
    end
    server.httpGet(moderation_port, reqString)
end

function UpdatePlayerRequest(steam_id, name)
    local reqString = string.format("/player/update?steam_id=%s&username=%s&key=%s", steam_id, urlencode(name), key)
    server.httpGet(moderation_port, reqString)
end
--- Submit request for player object from api
---@param steam_id string
---@param only_active_bans boolean
function GetPlayerRequest(steam_id, only_active_bans)
    local reqString = string.format("/player?steam_id=%s&key=%s&only_active_bans=%s", steam_id, key, tostring(only_active_bans))
    server.httpGet(moderation_port, reqString)
end

function CreatePlayerRequest(steam_id, name)
    local reqString = string.format("/player/create?steam_id=%s&username=%s&key=%s", steam_id, urlencode(name), key)
    server.httpGet(moderation_port, reqString)
end

function ModerationHttpResponse(port, request, reply)
    if port ~= moderation_port then return end
    if string.match(request, "^/ban%?steam_id.+") then
        local qparams = parseurl(request)
        local data = json.parse(reply)
        if data.error then
            if qparams.issuer then
                local issuer = GetPlayerBySteamId(qparams.issuer)
                server.announce("[MODERATION]", "Error submitting global ban: "..data.error.msg, issuer.peer_id)
            end
            return
        end

        local issuer = GetPlayerBySteamId(data.issuer)
        local player = GetPlayerBySteamId(data.player)
        server.announce("[MODERATION]", "Global ban successful", issuer.peer_id)
        if player then
            server.kickPlayer(player.peer_id)
        end
        return
    end

    if string.match(request, "^/player%?steam_id.+") then
        local data = json.parse(reply)
        local qparams = parseurl(request)
        if data.error then
            if data.error.statusCode == 404 then
                local player = GetPlayerBySteamId(qparams.steam_id)
                if player then
                    CreatePlayerRequest(player.steam_id, player.name)
                end
            end
            return
        end

        local player = GetPlayerBySteamId(data.steamid)
        -- player probably left before reply came back
        if not player then return end

        if data.username ~= player.name then
            UpdatePlayerRequest(data.steamid, player.name)
        end

        -- if request was only for active bans, and there is a bans result...then player is banned!
        if qparams.only_active_bans == "true" and data.bans then
            server.kickPlayer(player.peer_id)
        end
    end
end