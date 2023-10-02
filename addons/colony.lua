local logging = require("logging")
local config  = require("config")

local colony = peripheral.find("colonyIntegrator")
if not colony then logging.error("Setup", "Colony Integrator not found.") end
if not colony.isInColony then logging.error("Setup", "Colony Integrator is not in a colony.") end
logging.log("Setup", "Colony Integrator initiated")

return colony