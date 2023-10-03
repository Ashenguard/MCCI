local config   = require("config")

local works      = require("addons.works")
local builds     = require("addons.builds")
local citizens   = require("addons.citizens")
local researches = require("addons.researches")
local rs         = require("addons.rs")

local scanner = {
    data = {
        works = {},
        builds = {},
        researches = {},
        citizens = {},
        rs = {}
    }
}

function scanner.scan(scan, force)
    local monitors = require("monitors")

    if scan == "works" or scan == "all" or scan == nil then
        works.scan(scanner.data.works, force)
        monitors.update_all("works")
    end
    if scan == "builds" or scan == "all" or scan == nil then
        builds.scan(scanner.data.builds, force)
        monitors.update_all("builds")
    end
    if scan == "researches" or scan == "all" or scan == nil then
        researches.scan(scanner.data.researches, force)
        monitors.update_all("researches")
    end
    if scan == "citizens" or scan == "all" or scan == nil then
        citizens.scan(scanner.data.citizens, force)
        monitors.update_all("citizens")
    end
    if scan == "rs" or scan == "all" or scan == nil then
        rs.scan(scanner.data.rs, force)
        monitors.update_all("rs")
    end
end

return scanner