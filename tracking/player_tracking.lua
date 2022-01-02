-- player tracking
require("base")

player_list = {}

function PlayerTracking()
    AddHook(hooks.onPlayerJoin, TrackPlayer)
    AddHook(hooks.onPlayerLeave, UntrackPlayer)
    AddHook(hooks.onCreate, PopulatePlayerList)
end

function TrackPlayer(steam_id, name, peer_id, is_admin, is_auth)
    player_list[peer_id] = {
        peer_id = peer_id,
        steam_id=tostring(steam_id),
        name=name,
        is_admin=is_admin,
        is_auth=is_auth
    }
end

function PopulatePlayerList()
    player_list = {}
    local players = server.getPlayers()
    for _, player in ipairs(players) do
        TrackPlayer(player.steam_id, player.name, player.id, player.admin, player.auth)
    end
end

function UntrackPlayer(peer_id)
    player_list[peer_id] = nil
end

function GetPlayerByPeerId(peer_id)
    return player_list[peer_id]
end

function GetPlayerBySteamId(steam_id)
    local sid = steam_id
    if type(steam_id) ~= "string" then
        sid = tostring(steam_id)
    end

    for pid, p in pairs(player_list) do
        if p.steam_id == sid then
            return p
        end
    end

    return nil
end