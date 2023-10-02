local logging  = require("logging")

local monitors = require("monitors")
local timer    = require("timer")
local scanner  = require("scanner")


logging.reset()
parallel.waitForAll(timer.run, monitors.run, scanner.run)
