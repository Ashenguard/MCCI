local config  = require("config")
local logging = require("logging")
local utils   = require("utils")

local rs = {
    enabled = true,
    data = {}
}

local color_map = {colors.red, colors.orange, colors.yellow, colors.green}

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
    table.insert(rs.data, {
        {x="center", t="Unable to connect to refined storage", fg=colors.white, bg=colors.red}
    })
    logging.warn("Setup", "RS Bridge not found.")
else
    rs.bridge = bridge
    logging.log("Setup", "Refined storage initiated")
end

local function sort_items(method)
    if method == "name" then
        return function (a, b)
            return a.name < b.name
        end
    end
    if method == "name dec" then
        return function (a, b)
            return a.name > b.name
        end
    end

    return function (a, b)
        return a.amount > b.amount
    end
end

function rs.handle_request(request)
    if bridge == nil then
        return "DISABLED", 0, 0
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
        if request.items[1].nbt == nil or next(request.items[1].nbt) == nil then
            local stored = math.min(bridge.getItem({name=item_name}).amount, request.count)
            if stored > 0 then
                local export = bridge.exportItemToPeripheral({name=item_name, count=stored}, config.export_to)
                if type(export) == "number" then
                    provided = export
                else
                    logging.warn("RS", "Unable to export items due", export)
                end
            end
        end
        
        if provided < request.count then
            if bridge.isItemCrafting({name=request.items[1].name}) then
                logging.log("RS", "Following item is being crafted:", item_name)
                return "CRAFTING", provided, 0
            elseif bridge.craftItem({name=item_name, count=request.count - provided}) then
                logging.log("RS", "Following crafting has been requested:", request.count - provided, "x", item_name)
                return "SCHEDULED", provided, request.count - provided
            else
                logging.log("RS", "Failed to provide or craft following item:", item_name)
                return "FAILED", provided, 0
            end
        else
            logging.log("RS", "Request has been handled:", request.count, "x", item_name)
            return "DONE", provided, 0
        end
    else
        logging.log("RS", "Skipped", request.name)
        return "SKIPPED", 0, 0
    end
end

function rs.scan()
    if not rs.enabled then
        return
    end

    logging.log("RS", "Scan started at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

    local energy = "Energy: " .. bridge.getEnergyStorage() .. "/" .. bridge.getMaxEnergyStorage() .. "( " .. bridge.getEnergyUsage() .. "Fe/t)"
    local energy_color = color_map[math.floor(bridge.getEnergyStorage() * 3 / bridge.getMaxEnergyStorage() + 0.05) + 1]

    rs.data = {
        {
            {x="left", t=energy, fg=energy_color},
            {x="right", t="[           ", fg=energy_color},
            {x="right", t=string.rep(" ", math.floor(bridge.getEnergyStorage() * 10 / bridge.getMaxEnergyStorage() + 0.5)) .. " ", bg=energy_color},
            {x="right", t="]", fg=energy_color}
        },
        {}
    }

    local items = {}
    for _, item in ipairs(bridge.listItems()) do
        item = bridge.getItem(item)
        if bridge.isItemCrafting(item) then
            item.tag = "P"
            item.color = colors.lightBlue
        elseif bridge.isItemCraftable(item) then
            item.tag = "C"
            item.color = colors.combine(colors.lightBlue, colors.blue)
        else
            item.tag = " "
            item.color = colors.pink
        end

        item.mod = item.name:sub(1, item.name:find(":") - 1)
        item.mod = item.mod:sub(1, 1):upper() .. item.mod:sub(2):lower()
        item.name = item.name:sub(item.name:find(":") + 1)
        item.name = item.name:sub(1, 1):upper() .. item.name:sub(2):lower()

        table.insert(items, item)
    end
    table.sort(items, sort_items())

    for _, item in pairs(items) do
        table.insert(rs.data, {
            {x="left" , t=string.format("[%s] %s", item.tag, item.displayName), fg=item.color},
            {x="right", t=string.format("%s %-4s", item.mod, utils.format_number(item.amount)), fg=colors.lightGray}
        })
    end

    logging.log("RS", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

return rs