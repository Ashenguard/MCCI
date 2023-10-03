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
    if scan == "work" or scan == "all" or scan == nil then
        works.scan(scanner.data.works, force)
    end
    if scan == "builds" or scan == "all" or scan == nil then
        builds.scan(scanner.data.builds, force)
    end
    if scan == "researches" or scan == "all" or scan == nil then
        researches.scan(scanner.data.researches, force)
    end
    if scan == "citizens" or scan == "all" or scan == nil then
        citizens.scan(scanner.data.citizens, force)
    end
    if scan == "rs" or scan == "all" or scan == nil then
        rs.scan(scanner.data.rs, force)
    end
    
    local monitors = require("monitors")
    monitors.update_all()
end

return scanner