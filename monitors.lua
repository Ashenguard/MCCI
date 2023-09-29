local config = require("config")
local logging = require("logging")
local monitors = {}

local connected_monitors = {peripheral.find("monitor")}
print(#connected_monitors, "monitors found!")

local savefile = fs.open("monitors.save", "r")
local saved_monitors = {}
if savefile then
    saved_monitors.work = savefile.readLine()
    saved_monitors.research = savefile.readLine()
    saved_monitors.build = savefile.readLine()
    savefile.close()
end

local function wrap_monitor(name)
    if not name then return nil end
    return peripheral.wrap(name)
end

if config.work.enable then
    monitors.work = wrap_monitor(config.work.monitor)
    if monitors.work then
        logging.log("Monitors", "Monitor for work requests found from config")
    else
        monitors.work = wrap_monitor(saved_monitors.work)
        if monitors.work then
            logging.log("Monitors", "Monitor for work requests found from saved file")
        end
    end
end

if config.research.enable then
    monitors.research = wrap_monitor(config.research.monitor)
    if monitors.research and (not monitors.work or monitors.research ~= monitors.work) then
        logging.log("Monitors", "Monitor for researches found from config")
    else
        monitors.research = wrap_monitor(saved_monitors.research)
        if monitors.research and (not monitors.work or monitors.research ~= monitors.work) then
            logging.log("Monitors", "Monitor for researches found from saved file")
        else
            monitors.research = nil
        end
    end
end

if config.buildings.enable then
    monitors.buildings = wrap_monitor(config.build.monitor)
    if monitors.buildings and (not monitors.work or monitors.buildings ~= monitors.work) and not (monitors.research or monitors.buildings ~= monitors.research) then
        logging.log("Monitors", "Monitor for buildings found from config")
    else
        monitors.buildings = wrap_monitor(saved_monitors.buildings)
        if monitors.buildings and (not monitors.work or monitors.buildings ~= monitors.work) and not (monitors.research or monitors.buildings ~= monitors.research) then
            logging.log("Monitors", "Monitor for buildings found from saved file")
        else
            monitors.buildings = nil
        end
    end
end

-- Try find and claim a monitor for missing ones
if config.work.enable and not monitors.work then
    for _, monitor in pairs(connected_monitors) do
        if monitor and monitor ~= monitors.research and monitor ~= monitors.buildings then
            monitors.work = monitor
            logging.log("Monitors", "Monitor for work requests has been claimed from available monitors")
            break
        end
    end
    if not monitors.work then
        config.work.enable = false
        logging.log("Monitors", "Unable to find monitor for work requests, disabling...")
    end
end
if config.research.enable and not monitors.research then
    for _, monitor in pairs(connected_monitors) do
        if monitor and monitor ~= monitors.work and monitor ~= monitors.buildings then
            monitors.research = monitor
            logging.log("Monitors", "Monitor for researches has been claimed from available monitors")
            break
        end
    end
    if not monitors.research then
        config.research.enable = false
        logging.log("Monitors", "Unable to find monitor for researches, disabling...")
    end
end
if config.buildings.enable and not monitors.buildings then
    for _, monitor in pairs(connected_monitors) do
        if monitor and monitor ~= monitors.research and monitor ~= monitors.work then
            monitors.buildings = monitor
            logging.log("Monitors", "Monitor for buildings has been claimed from available monitors")
            break
        end
    end
    if not monitors.buildings then
        config.buildings.enable = false
        logging.log("Monitors", "Unable to find monitor for buildings, disabling...")
    end
end

-- Saving what you got...
local savefile = fs.open("monitors.save", "w")
if monitors.work      then savefile.writeLine(peripheral.getName(monitors.work))      else savefile.writeLine("") end
if monitors.research  then savefile.writeLine(peripheral.getName(monitors.research))  else savefile.writeLine("") end
if monitors.buildings then savefile.writeLine(peripheral.getName(monitors.buildings)) else savefile.writeLine("") end
savefile.close()

-- Functions you may now come in!
local function initialize(monitor)
    if not monitor then return end

    monitor.setTextScale(0.5)
    monitor.setCursorPos(1, 1)
    monitor.setCursorBlink(false)

    monitor.row = 4

    function monitor.print(row, align, text, ...)
        local w, h = monitor.getSize()
        local fg = monitor.getTextColor()
        local bg = monitor.getBackgroundColor()
        
        local pos = 1
        if align == "left"   then pos = 1 end
        if align == "center" then pos = math.floor((w - #text) / 2) end
        if align == "right"  then pos = w - #text end
    
        if #arg > 0 then monitor.setTextColor(arg[1]) end
        if #arg > 1 then monitor.setBackgroundColor(arg[2]) end

        monitor.setCursorPos(pos, row)
        monitor.write(text)

        monitor.setTextColor(fg)
        monitor.setBackgroundColor(bg)
    end

    function monitor.reset()
        monitor.row = 3
        monitor.clear()
    end
end

initialize(monitors.work)
initialize(monitors.research)
initialize(monitors.buildings)

return monitors