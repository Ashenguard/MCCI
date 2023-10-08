local scanners = {
    works      = require("addons.works"),
    builds     = require("addons.builds"),
    citizens   = require("addons.citizens"),
    researches = require("addons.researches"),
    rs         = require("addons.rs"),
}

local scanner = {
    data = {
        works = {},
        builds = {},
        researches = {},
        citizens = {},
        rs = {},
        settings = {}
    }
}

local scans = {{"works", true}, {"builds", false}, {"researches", false}, {"citizens", false}, {"rs", false}}
local function sub_scan(monitors, scan, force)
    scanners[scan].scan(scanner.data[scan], force)
    monitors.update_all(scan)
end


function scanner.scan(scan, force)
    local monitors = require("monitors")

    if scan ~= nil and scan ~= "all" then
        sub_scan(monitors, scan, force)
        return
    end

    local list = {}
    for _, s in ipairs(scans) do
        local mons = monitors.find(s[1])
        if #mons > 0 or s[2] or force then
            local function temp()
                sub_scan(monitors, s[1], force)
            end
            table.insert(list, temp)
        end
    end

    parallel.waitForAll(unpack(list))
end

return scanner