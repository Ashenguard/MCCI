-- RSConfig.lua
-- Author: Ashenguard
-- Original author: Scott Adkins <adkinss@gmail.com> (Zucanthor)
-- Published: September 2023
-- Minecraft Version: 1.20.X

-- Need help, Find me on discord and servers below (Probably should ping me there!) :)
-- ID: 00ashenguard
-- 
-- Minecolonies discord: https://discord.gg/minecolonies-139070364159311872
-- Computercraft discord: https://discord.gg/minecraft-computer-mods-477910221872824320
-- Advanced peripheral discord: https://discord.gg/Jf7n7s5TCk
-- My own server: https://discord.gg/vgka549UJW

-- Read "Readme.md" for more info and tutorial


-- This is a config file you can use to customize the RSWarehouse
local config = {}

-- The storage mod
--    Possible values: "RS", "AE"
--    Note: AE is not implemented yet so...
config.storage_mod = "RS"
-- Storage container connected to warehouse or entangled block location
config.export_to = "right"
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
config.buildings.enable = false
-- Monitor name to check first, If not found will find and use an unused monitor
config.buildings.monitor = nil


return config