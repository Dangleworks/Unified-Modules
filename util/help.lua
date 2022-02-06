require("base")

-- NOTE: This module must be included in the script.lua modules list to function

help_entries = {}

--- Adds an entry to the help command
--- module_name the display name and search slug for the module
--- commands argument is a table of commands and their help strings
--- an option boolean value can be added to notate an admin only command
--- FORMAT EXAMPLE:
--- {
---     {"?command arg1 arg2", "Command help text"},
---     {"?command2", "Command help test", true}
--- }
---@param module_name string
---@param commands table
function AddHelpEntry(module_name, commands)
    help_entries[module_name]=commands
end

function Help()
    AddHook(hooks.onCustomCommand, HelpCommand)
    AddHelpEntry("help", {{"?help", "list available help topics"}})
end

function HelpCommand(full_message, user_peer_id, is_admin, is_auth, command, args)
    command = string.lower(command)
    if command ~= "?help" then return end

    if not args[1] then
        server.announce("[HELP]", "--------------------", user_peer_id)
        server.announce("[HELP]", "Specify a topic for detailed help (example ?help vehicles)", user_peer_id)
        server.announce("[HELP]", "AVAILABLE HELP TOPICS:", user_peer_id)
        for slug, entry in pairs(help_entries) do
            local show = is_admin or hasAvailableCommands(slug)
            if show then
                server.announce("[HELP]", string.format("-> %s", slug), user_peer_id)
            end
        end
        server.announce("[HELP]", "--------------------", user_peer_id)
    else
        local entry = help_entries[args[1]]
        if not entry or not hasAvailableCommands(entry) then
            server.announce("[HELP]", "Topic not found. Type ?help for a list of topics", user_peer_id)
            return
        end

        server.announce("[HELP]", "--------------------", user_peer_id)
        server.announce("[HELP]", "HELP TOPIC: "..args[1], user_peer_id)
        for _, cmd in ipairs(entry) do
            if not cmd[3] or is_admin then
                server.announce("[HELP]", string.format("%s - %s", cmd[1], cmd[2]), user_peer_id)
            end
        end
        server.announce("[HELP]", "--------------------", user_peer_id)
    end
end

function hasAvailableCommands(entry)
    -- if there is any entry available to non-admins, return true
    for _, cmd in ipairs(entry) do
        if not cmd[3] then return true end
    end
    return false
end