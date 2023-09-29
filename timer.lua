local monitors = require("monitors")

local timer = {}

local function print_header(monitor, time_value, time_color, timer_value, timer_color)
    if monitor then
        monitor.print(1, "left", time_value, time_color)
        monitor.print(1, "right", timer_value, timer_color)
    end
end

function timer.display(tick)
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
	
	local time_value  = string.format("Time: %s [%s]              ", textutils.formatTime(now, false), cycle)
	local timer_value = string.format("             Updates in %ss", tick)
    local timer_color = colors.white
	if cycle == "Night" then
		timer_value = "Updates stopped temporally!"
		timer_color = colors.red
	else
		if tick < 15 then timer_color = colors.yellow end
		if tick < 5 then timer_color = colors.orange end
	end

    for _, monitor in pairs(monitors) do
        print_header(monitor, time_value, time_color, timer_value, timer_color)
    end
end

return timer