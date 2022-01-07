-- Debug Library
debugutils = {}

debugutils.DumpTable = function (O)
    if type(O) == 'table' then
        local s = '{ '
        for k,v in pairs(O) do
                if type(k) ~= 'number' then k = '"'..k..'"' end
                s = s .. '['..k..'] = ' .. debugutils.DumpTable(v) .. ','
        end
        return s .. '} '
    else
        return tostring(O)
    end
end

debugutils.Log = function(O)
    for _, player in pairs(server.getPlayers()) do
        if player.admin then
            server.announce("[DEBUG]", debugutils.DumpTable(O))
        end
    end
end