local logging = require("logging")
local scanner = require("scanner")
local timer   = nil                 -- Avoiding require loop by initializing it in runtime

local monitors = {}

local tabs = {"Requests", "Buildings", "Citizens", "Researches", "Refined Storage", "Settings"}
local tabs_nick = {"works", "builds", "citizens", "researches", "rs", "settings"}
local tabs_width = 0
for _, tab in ipairs(tabs) do
    tabs_width = math.max(tabs_width, #tab)
end

local function tab_name(i)
    local name = tabs[i]
    return "<= " .. string.rep(" ", math.floor((tabs_width - #name) / 2)) .. name .. string.rep(" ", math.ceil((tabs_width - #name) / 2)) .. " =>"
end

local function touched(x0, x1, range)
    for i = x1, x1 + range do
        if x0 == i then
            return true
        end
    end
    return false
end

monitors.all = {peripheral.find("monitor")}
logging.log("Monitors", #monitors.all, "monitors found!")

monitors.wrap = {}
for i, monitor in ipairs(monitors.all) do
    local w, h = monitor.getSize()

    monitor.clear()
    monitor.setTextScale(0.5)
    monitor.setCursorBlink(false)
    
    monitor.row  = 1
    monitor.tab  = (i - 1) % #tabs + 1
    monitor.prev = math.floor((w - tabs_width - 6) / 2)
    monitor.next = monitor.prev + tabs_width + 3
    monitor.data = {}
    
    monitor.actions = {}

    monitors.wrap[peripheral.getName(monitor)] = monitor

    function monitor.print(row, pos, text, fg, bg, fill, action)
        if text == nil or pos == nil then
            return
        end

        local pw, _ = monitor.getSize()
        local dfg = monitor.getTextColor()
        local dbg = monitor.getBackgroundColor()
        
        if fill then fill = 0 else fill = 2 end
        if pos == "left"   then pos = 1 end
        if pos == "center" then pos = math.floor((pw - #text - fill) / 2) end
        if pos == "right"  then pos = pw - #text - fill end
    
        if fg ~= nil then monitor.setTextColor(fg) end
        if bg ~= nil then monitor.setBackgroundColor(bg) end

        if type(action) ~= "function" then
            action = nil
        end
        
        monitor.actions[row] = {}
        for i = pos, math.min(pos + #text, pw) do
            monitor.actions[row][i] = action
        end

        monitor.setCursorPos(pos, row)
        monitor.write(text)
        monitor.setTextColor(dfg)
        monitor.setBackgroundColor(dbg)
    end

    function monitor.print_data()
        monitor.clear()
    
        local pw, ph = monitor.getSize()
        monitor.print(2, "center", tab_name(monitor.tab))

        if monitor.data == nil or next(monitor.data) == nil then
            monitor.print(4, "center", "No data found!", colors.white, colors.red)
            return
        end

        for ui = 1, h - 3 do
            local line = monitor.data[ui + monitor.row - 1]
            
            monitor.setCursorPos(1, ui + 3)
            monitor.clearLine()

            if line ~= nil then
                for _, state in ipairs(line) do
                    monitor.print(ui + 3, state.x, state.t, state.fg, state.bg, false, state.a)
                end
            end
        end

        if monitor.row > 1 then monitor.print(4, pw - 2, "^", nil, nil, true) end
        if #monitor.data > ph - 3 then monitor.print(ph, pw - 2, "v", nil, nil, true) end
    end

    function monitor.update()
        local uw, uh = monitor.getSize()

        monitor.data = scanner.data[tabs_nick[monitor.tab]]
        monitor.prev = math.floor((uw - tabs_width - 6) / 2)
        monitor.next = monitor.prev + tabs_width + 3

        monitor.row = math.min(monitor.row, #monitor.data - uh + 1)
        monitor.row = math.max(1, monitor.row)

        monitor.print_data()
        if timer == nil then timer = require("timer") end
        timer.display(monitor)
    end

    function monitor.call_touch(x, y)
        -- Tabs change
        if y == 2 then
            if touched(x, monitor.prev, 3) then
                monitor.tab = monitor.tab - 1
                if monitor.tab < 1 then monitor.tab = #tabs end
                monitor.update()
                return true
            end
            if touched(x, monitor.prev + 3, tabs_width) then
                scanner.scan(tabs_nick[monitor.tab], true)
                monitor.update()
                return true
            end
            if touched(x, monitor.next, 3) then
                monitor.tab = monitor.tab + 1
                if monitor.tab > #tabs then monitor.tab = 1 end
                monitor.update()
                return true
            end
        end

        -- Scrolling
        local tw, th = monitor.getSize()
        if y == 4 and touched(x, tw - 2, 3) then
            monitor.scroll(-1)
            return true
        end
        if y == th and touched(x, tw - 2, 3) then
            monitor.scroll(1)
            return true
        end

        local action_line = monitor.actions[y]
        if action_line ~= nil then
            local action = action_line[x]
            if action ~= nil then
                local v, e = pcall(action, monitor)
                if v then
                    monitor.update()
                else
                    logging.warn("Touch", e)
                end
            end
        end
    end

    function monitor.scroll(size)
        local _, sh = monitor.getSize()
        local previous = monitor.row

        monitor.row = math.max(1, monitor.row + size)
        if #monitor.data - monitor.row < sh - 4 then
            monitor.row = #monitor.data - sh + 4
        end

        if previous ~= monitor.row then
            monitor.print_data()
        end
    end
end

function monitors.update_all()
    logging.log("Monitors", "Updating all monitors")

    for _, monitor in pairs(monitors.all) do
        monitor.update()
    end
end

function monitors.run()
    while true do
        local _, m, x, y = os.pullEvent("monitor_touch")
        local monitor = monitors.wrap[m]

        if monitor then
            monitor.call_touch(x, y)
        end
    end
end

return monitors