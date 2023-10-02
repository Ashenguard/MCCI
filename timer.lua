local config   = require("config")
local monitors = require("monitors")

local timer = {}

timer.data = {time = "00:00", time_color = colors.red, timer = "Paused", timer_color = colors.red}

function timer.display(monitor)
    if monitor ~= nil then
        monitor.setCursorPos(1, 1)
        monitor.clearLine()

        monitor.print(1, "left", timer.data.time, timer.data.time_color, nil, true)
        monitor.print(1, "right", timer.data.timer, timer.data.timer_color, nil, true)
    end
end

function timer.run()
    local ticks = 1
    local TIMER = os.startTimer(1)
    while true do
        local _, t = os.pullEvent("timer")
        if TIMER == t then
            ticks = ticks - 1

            local now = os.time()

            local cycle = "Night"
            local time_color = colors.red
            if now >= 4 and now < 6 then
                cycle = "Sunrise"
                time_color = colors.orange
            elseif now >= 6 and now < 18 then
                cycle = "Day"
                time_color = colors.yellow
            elseif now >= 18 and now < 19.5 then
                cycle = "Sunset"
                time_color = colors.orange
            end

            local time_value  = string.format("Time: %s [%s]", textutils.formatTime(now, false), cycle)
            local timer_value = string.format("Updates in %ss", ticks)
            local timer_color = colors.white
            if cycle == "Night" then
                timer_value = "Paused"
                timer_color = colors.red
            else
                if ticks < 15 then timer_color = colors.yellow end
                if ticks < 5 then timer_color = colors.orange end
            end

            timer.data = {time = time_value, time_color = time_color, timer = timer_value, timer_color = timer_color}
            for _, monitor in ipairs(monitors.all) do
                timer.display(monitor)
            end

            if ticks == 0 then
                ticks = config.internal
                monitors.update_all()
            end

            TIMER = os.startTimer(1)
        end
    end
end

return timer
