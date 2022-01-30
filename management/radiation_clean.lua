require("base")

rc_interval = 60
rc_counter = 0

function RadiationClean()
    AddHook(hooks.onTick, CleanRadiation)
end

function CleanRadiation(game_ticks)
    rc_counter = rc_counter+1
    if rc_counter > rc_interval then
        rc_counter = 0
        server.clearRadiation()
    end
end