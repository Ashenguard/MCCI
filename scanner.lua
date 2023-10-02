local config = require("config")

local works      = require("addons.works")
local builds     = require("addons.builds")
local citizens   = require("addons.citizens")
local researches = require("addons.researches")
local rs         = require("addons.rs")

local scanner = {
    data = {}
}

function scanner.run()
    local TIMER = os.startTimer(0.5)
    while true do
        local _, t = os.pullEvent("timer")
        if TIMER == t then
            works.scan()
            scanner.data.works = works.data

            builds.scan()
            scanner.data.builds = builds.data

            researches.scan()
            scanner.data.researches = researches.data

            citizens.scan()
            scanner.data.citizens = citizens.data

            rs.scan()
            scanner.data.rs = rs.data

            TIMER = os.startTimer(config.internal)
        end
    end
end

return scanner