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