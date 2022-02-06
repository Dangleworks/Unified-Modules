require("base")
require("tracking.player_tracking")

function AutoAuth()
    AddHook(hooks.onPlayerJoin, AuthOnJoin)
end

function AuthOnJoin(steam_id, name, peer_id, is_admin, is_auth)
    local player = GetPlayerByPeerId(peer_id)
    if (not player.savedata or not player.savedata.no_auth) and not is_auth then
        server.addAuth(peer_id)
    end
end