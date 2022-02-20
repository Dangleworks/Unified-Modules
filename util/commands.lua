require("base")

function Commands()
    AddHook(hooks.onCustomCommand, UtilCommands)
end

function UtilCommands(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if command == "?goto" then
    elseif command == "?sudoku" or command == "?die" then
    end
end

function CommandGoTo()
end

function CommandSuicide()
end

function CommandWhisper()
end