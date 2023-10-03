-- Read the "readme.md" first!
-- https://github.com/Ashenguard/MCCI

-- This is a config file you can use to customize the RSWarehouse
local config = {}

-- The storage mod
--    Possible values: "RS", "AE"
--    Note: AE is not implemented yet so...
config.storage_mod = "RS"
-- Storage container connected to warehouse or entangled block location
config.export_to = "entangled:tile_2"
-- Time between checks in seconds
config.internal = 30


-- Configs related to work requests
config.work = {}

-- Enable work requests scan
config.work.enable = true
-- Details shown at the right side of work requests
--    Possible values: "Builder", "Stock"
config.work.details = "Builder"
-- Monitor name to check first, If not found will find and use an unused monitor
config.work.monitor = nil


-- Config related to researches
config.research = {}

-- Enable research scan
config.research.enable = true
-- Show description of researches waiting to be done
config.research.description = true
-- Show required materials for research (Might need wider monitor)
config.research.materials = false
-- Monitor name to check first, If not found will find and use an unused monitor
config.research.monitor = nil


-- Config related to buildings (WIP)
config.buildings = {}
-- Enable buildings scan
config.buildings.enable = true
-- Monitor name to check first, If not found will find and use an unused monitor
config.buildings.monitor = nil


return config