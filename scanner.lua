local config = require("config")

local works      = require("addons.works")
local builds     = require("addons.builds")
local researches = require("addons.researches")

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

            TIMER = os.startTimer(config.internal)
        end
    end
end

return scanner