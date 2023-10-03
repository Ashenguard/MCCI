local config   = require("config")
local monitors = require("monitors")
local scanner  = require("scanner")

local timer = {}

timer.data = {time = "00:00", time_color = colors.red, timer = "Paused", timer_color = colors.red, cycle = "Night"}
timer.ticks = 0

function timer.display(monitor)
    if monitor ~= nil then
        monitor.setCursorPos(1, 1)
        monitor.clearLine()

        monitor.print(1, "left", timer.data.time, timer.data.time_color, nil, true)
        monitor.print(1, "right", timer.data.timer, timer.data.timer_color, nil, true)
    end
end

local scanning, force

local function countdown()
    monitors.update_all()
    local TIMER = os.startTimer(1)
    while true do
        local _, t = os.pullEvent("timer")
        if TIMER == t then
            TIMER = os.startTimer(1)
            local now = os.time()
            if now >= 4 and now < 6 then
                timer.data.cycle = "Sunrise"
                timer.data.time_color = colors.orange
            elseif now >= 6 and now < 18 then
                timer.data.cycle = "Day"
                timer.data.time_color = colors.yellow
            elseif now >= 18 and now < 19.5 then
                timer.data.cycle = "Sunset"
                timer.data.time_color = colors.orange
            else
                timer.data.cycle = "Night"
                timer.data.time_color = colors.red
            end
            timer.data.time  = string.format("Time: %s [%s]", textutils.formatTime(now, false), timer.data.cycle)
            
            if scanning then
                timer.ticks = timer.ticks + 1
                timer.data.timer = string.format("Updating%-3s (%ss)", string.rep(".", timer.ticks % 4), timer.ticks)
            else
                timer.ticks = timer.ticks - 1
                timer.data.timer = string.format("Updates in %ss", timer.ticks)
            end
            if timer.ticks < 5 then timer.data.timer_color = colors.orange
            elseif timer.ticks < 15 then timer.data.timer_color = colors.yellow
            else timer.data.timer_color = colors.white end

            for _, monitor in ipairs(monitors.all) do
                timer.display(monitor)
            end

            if not scanning and timer.ticks <= 0 then
                scanning = true
            end
        end
    end
end

local function scan()
    while true do
        if scanning then
            scanner.scan("all", force)
            force = false
            scanning = false
            timer.ticks = config.internal
        end
        sleep(1)
    end
end

function timer.run()
    scanning = true
    force = true
    
    parallel.waitForAll(countdown, scan)
end

return timer
