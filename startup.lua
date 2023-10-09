local logging  = require("logging")

local monitors = require("monitors")
local timer    = require("timer")

logging.reset()
parallel.waitForAll(timer.run, monitors.run)
