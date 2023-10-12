local logging  = require("logging")

local monitors = require("monitors")
local timer    = require("timer")

local settings = require("settings")

logging.reset()
parallel.waitForAll(timer.run, monitors.run)
