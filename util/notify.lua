--- Sent notification to admins
---@param title string
---@param message string
function notifyAdmins(title, message)
    for i, player in ipairs(server.getPlayers()) do
        if player.admin then
            server.notify(player.id, title, message, 10)
        end
    end
end

---@param from string
---@param message string
function messageAdmins(from, message)
    for i, player in ipairs(server.getPlayers()) do
        if player.admin then
            server.announce(from, message, player.id)
        end
    end
end

NOTIFICATION_TYPE = {
    NEW_MISSION = 0,
    NEW_MISSION_CRITICAL = 1,
    FAILED_MISSION = 2,
    FAILED_MISSION_CRITICAL = 3,
    COMPLETE_MISSION = 4,
    NETWORK_CONNECT = 5,
    NETWORK_DISCONNECT = 6,
    NETWORK_INFO = 7,
    CHAT_MESSAGE = 8,
    REWARDS = 9,
    NETWORK_INFO_CRITICAL = 10,
    RESEARCH_COMPLETE = 11
}