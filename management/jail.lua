
require("base")

function Jail()
    AddHook(hooks.onCustomCommand)
end

function JailCommand(full_message, user_peer_id, is_admin, is_auth, command, args)
end