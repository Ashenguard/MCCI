local config  = require("config")
local logging = require("logging")

local rs = {
    enabled = true
}

-- Might messup these so better to skip them (Add if you found more)
local ignore_match_list = {
	{"desc", "Tool of class"},
	{"name", "Hoe"},
	{"name", "Shovel"},
	{"name", "Axe"},
	{"name", "Pickaxe"},
	{"name", "Bow"},
	{"name", "Sword"},
	{"name", "Shield"},
	{"name", "Helmet"},
	{"name", "Leather Cap"},
	{"name", "Chestplate"},
	{"name", "Tunic"},
	{"name", "Pants"},
	{"name", "Leggings"},
	{"name", "Boots"}
}
local ignore_exact_list = {
	"Rallying Banner",
	"Crafter",
	"Compostable",
	"Fertilizer",
	"Flowers",
	"Food",
	"Fuel",
	"Smeltable Ore",
	"Stack List"
}

local bridge = peripheral.find("rsBridge")
if not bridge then
    rs.enabled = false
    logging.warn("Setup", "RS Bridge not found.")
else
    rs.bridge = bridge
    logging.log("Setup", "Refined storage initiated")
end

function rs.handle_request(request)
    if bridge == nil then
        return "DISABLED"
    end

    local use_rs = true
    for _, temp in pairs(ignore_match_list) do
        if temp[1] == "desc" and string.find(request.desc, temp[2]) then use_rs = false
        elseif temp[1] == "name" and string.find(request.name, temp[2]) then use_rs = false end
    end
    for _, temp in pairs(ignore_exact_list) do
        if request.name == temp then use_rs = false end
    end
    
    if use_rs then
        local provided = 0
        local item_name = request.items[1].name
        
        -- NBTs might fail...
        if not request.items[1].nbt then
            local stored = bridge.getItem({name=item_name}).amount
            provided = math.min(stored, request.count)
            bridge.exportItemToPeripheral({name=item_name, count=provided}, config.export_to)
        end
        
        if provided < request.count then
            if bridge.isItemCrafting({name=request.items[1].name}) then
                logging.log("RS", "Following item is being crafted:", item_name)
                return "CRAFTING"
            elseif bridge.craftItem({name=item_name, count=request.count - provided}) then
                logging.log("RS", "Following crafting has been requested:", request.count - provided, "x", item_name)
                return "SCHEDULED"
            else
                logging.log("RS", "Failed to craft following item:", item_name)
                return "FAILED"
            end
        else
            return "DONE"
        end
    else
        logging.log("RS", "Skipped", request.name)
        return "SKIPPED"
    end
end

return rs