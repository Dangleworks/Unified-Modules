require("base")
require("tracking.player_tracking")

function Commands()
    AddHook(hooks.onCustomCommand, UtilCommands)
end

function UtilCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if command == "?sudoku" or command == "?die" or command == "?suicide" then
        CommandSuicide(user_peer_id)
    end
end

---@param user_peer_id number
function CommandSuicide(user_peer_id)
    local id, ok = server.getPlayerCharacterID(user_peer_id)
    if ok then
        server.killCharacter(id)
    end
end