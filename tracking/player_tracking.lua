-- player tracking
require("base")
require("util.debug")
require("util.help")

-- TODO: Add a function to store persistant player data in g_savedata and return it in the player object from GetPlayerByPeerId and GetPlayerBySteamId
-- perhaps accesed through a table ref like player.data.somefield
player_list = {}

function PlayerTracking()
    AddHook(hooks.onPlayerJoin, TrackPlayer)
    AddHook(hooks.onPlayerLeave, UntrackPlayer)
    AddHook(hooks.onCreate, PopulatePlayerList)
    AddHook(hooks.onCustomCommand, PlayerTrackingCommands)
    AddHelpEntry("player_tracking", {
        {"?playerlist", "Prints a list of players", true},
        {"?player [peer_id]", "Prints all data for the specified peer id", true}
    })
end

function PlayerTrackingCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    if is_admin and string.lower(command) == "?playerlist" then
        for pid, player in pairs(player_list) do
            server.announce("[PLAYER LIST]", string.format("%d - %s", pid, player.name), user_peer_id)
        end
        return
    end
    if is_admin and string.lower(command) == "?player" and args[1] and tonumber(args[1]) then
        local player = GetPlayerByPeerId(tonumber(args[1]))
        for key, val in pairs(player) do
            if type(val) == "table" then
                server.announce("[PLAYER] "..key, debugutils.DumpTable(val), user_peer_id)
            else
                server.announce("[PLAYER] "..key, tostring(val), user_peer_id)
            end
        end
    end
end

function TrackPlayer(steam_id, name, peer_id, is_admin, is_auth)
    steam_id = tostring(steam_id)
    player_list[peer_id] = {
        peer_id = peer_id,
        steam_id=steam_id,
        name=name,
        is_admin=is_admin,
        is_auth=is_auth
    }

    if not g_savedata.player_tracking[steam_id] then
        g_savedata.player_tracking[steam_id] = {}
    end

    player_list[peer_id].savedata = g_savedata.player_tracking[steam_id]
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

--- Returns stormworks player and addon data
---@param steam_id string
---@return Player
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
