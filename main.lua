local config   = require("config")
local logging  = require("logging")
local utils    = require("Utils")

local monitors = require("monitors")
local timer    = require("Timer")

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

----------------------------------------------------------------------------
-- Initialize everything!
----------------------------------------------------------------------------
local rs = peripheral.find("rsBridge")
if not rs then logging.error("Setup", "RS Bridge not found.") end
logging.log("Setup", "Refined storage initiated")

local colony = peripheral.find("colonyIntegrator")
if not colony then logging.error("Setup", "Colony Integrator not found.") end
if not colony.isInColony then logging.error("Setup", "Colony Integrator is not in a colony.") end
logging.log("Setup", "Colony Integrator initiated")

----------------------------------------------------------------------------
-- Functions, the essence!
----------------------------------------------------------------------------
function Scan()
	if config.work.enable then Scan_works() end
	if config.research.enable then Scan_researches() end
	if config.buildings.enable then Scan_builds() end
end

function Scan_works()
    logging.log("Work requests", "Scan started at" .. textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

    local builder_list = {}
    local nonbuilder_list = {}
    local equipment_list = {}

    local items = rs.listItems()
    local item_array = {}
    for _, item in ipairs(items) do
        if not item.nbt then
            item_array[item.name] = item.amount
        end
    end

    local requests = colony.getRequests()
    for _, request in pairs(requests) do
        local name = request.name
        local item = request.items[1].name
        local target = request.target
        local desc = request.desc
        local needed = request.count
        local provided = 0
		local stored = 0
		
		-- Remove middle name (Made by Adkins, Not tweaked yet...)
        local target_words = {}
        local target_length = 0
        for word in target:gmatch("%S+") do
            table.insert(target_words, word)
            target_length = target_length + 1
        end

		local target_name = target
        if target_length >= 3 then
			 target_name = target_words[target_length-2] .. " " .. target_words[target_length]
		end

        local target_type = ""
        local target_count = 1
        repeat
            if target_type ~= "" then target_type = target_type .. " " end
            target_type = target_type .. target_words[target_count]
            target_count = target_count + 1
        until target_count > target_length - 3
		
		-- Skip specified items
        local use_rs = true
		for _, temp in pairs(ignore_match_list) do
			if temp[1] == "desc" and string.find(desc, temp[2]) then use_rs = false
			elseif temp[1] == "name" and string.find(name, temp[2]) then use_rs = false end
		end
		for _, temp in pairs(ignore_exact_list) do
			if name == temp then use_rs = false end
		end
		
		-- Manage and sort items
        local color = colors.blue
        if use_rs then
            if item_array[item] then
                stored = rs.getItem({name=item}).amount
				provided = math.min(stored, needed)
				rs.exportItemToPeripheral({name=item, count=provided}, config.export_to)
            end

            color = colors.green
            if provided < needed then
                if rs.isItemCrafting({name=item}) then
                    color = colors.yellow
                    logging.log("RS", "Following item is being crafted:", item)
                elseif rs.craftItem({name=item, count=needed - provided}) then
					color = colors.yellow
					logging.log("RS", "Following crafting has been requested:", needed - provided, "x", item)
				else
					color = colors.red
					logging.log("RS", "Failed to craft following item:", item)
				end
            end
        else
            logging.log("RS", "Skipped", name, "for", target)
        end

        if string.find(desc, "of class") then
            local level = "Any Level"
            if string.find(desc, "with maximal level:Leather") 		then level = "Leather" end
            if string.find(desc, "with maximal level:Gold") 		then level = "Gold" end
            if string.find(desc, "with maximal level:Chain") 		then level = "Chain" end
            if string.find(desc, "with maximal level:Wood or Gold") then level = "Wood or Gold" end
            if string.find(desc, "with maximal level:Stone") 		then level = "Stone" end
            if string.find(desc, "with maximal level:Iron") 		then level = "Iron" end
            if string.find(desc, "with maximal level:Diamond") 		then level = "Diamond" end
            if level == "Any Level" then name = name .. " of any level" else name = level .. " " .. name end
			
            table.insert(equipment_list, {name=name, target=target_type .. " " .. target_name, needed=needed, provided=provided, color=color})
        else
			-- Remove anoying numbers before the name
			name = string.format("%-3d %s", needed, name:gsub("^1%-(%d+) ", ""):gsub("^1 ", ""))

			if string.find(target, "Builder") then
				table.insert(builder_list, {name=name, item=item, target=target_name, needed=needed, provided=provided, color=color})
			else
				local new_target = target_type .. " " .. target_name
				if target_length < 3 then
					new_target = target
				end
				if new_target:match("postbox$") then
					new_target = "Postbox"
				end
				table.insert(nonbuilder_list, {name=name, target=new_target, needed=needed, provided=provided, color=color})
			end
		end
    end

    -- Time to monitorize!
	monitors.work.reset()
	local no_request = true

    local header_shown = false
    for _, equipment in pairs(equipment_list) do
        if not header_shown then
            monitors.work.print(monitors.work.row, "center", "Equipment")
            monitors.work.row = monitors.work.row + 1
            header_shown = true
			no_request = false
        end
        local text = string.format("%d %s", equipment.needed, equipment.name)
        monitors.work.print(monitors.work.row, "left", text, equipment.color)
        monitors.work.print(monitors.work.row, "right", " " .. equipment.target, equipment.color)
        monitors.work.row = monitors.work.row + 1
    end

    local header_shown = false
    for _, builder in pairs(builder_list) do
        if not header_shown then
			if monitors.work.row > 3 then monitors.work.row = monitors.work.row + 1 end
            monitors.work.print(monitors.work.row, "center", "Builder Requests")
            monitors.work.row = monitors.work.row + 1
            header_shown = true
			no_request = false
        end
        local text = string.format("%d/%s", builder.provided, builder.name)
        monitors.work.print(monitors.work.row, "left", text, builder.color)
        monitors.work.print(monitors.work.row, "right", " " .. builder.target, builder.color)
        monitors.work.row = monitors.work.row + 1
    end

    local header_shown = false
    for _, nonbuilder in pairs(nonbuilder_list) do
        if not header_shown then
			if monitors.work.row > 3 then monitors.work.row = monitors.work.row + 1 end
            monitors.work.print(monitors.work.row, "center", "Nonbuilder Requests")
            monitors.work.row = monitors.work.row + 1
            header_shown = true
			no_request = false
        end
        local text = string.format("%d %s", nonbuilder.needed, nonbuilder.name)
        if nonbuilder.name:match("^%d+") then
            text = string.format("%d/%s", nonbuilder.provided, nonbuilder.name)
        end
        monitors.work.print(monitors.work.row, "left", text, nonbuilder.color)
        monitors.work.print(monitors.work.row, "right", " " .. nonbuilder.target, nonbuilder.color)
        monitors.work.row = monitors.work.row + 1
    end

    if no_request then 
		monitors.work.print(monitors.work.row, "center", "No Open Requests") 
		monitors.work.row = monitors.work.row + 1
	end
	
	logging.log("Work requests", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

function Scan_researches()
	logging.log("Researches", "Scan started at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

	local not_started_list = {}
	local in_progress_list = {}
	local not_fulfilled_list = {}
	
	local function handle_research_list(category, list, depth)
		if not list then return end
		for _, research in pairs(list) do
			research.category = category
			research.depth = depth
			
			research.time = 0.5 * math.pow(2, depth)
			
			if research.status == "IN_PROGRESS" then
				-- Temp act to calcualte percentage
				research.progress = research.progress / research.time / 3

				table.insert(in_progress_list, research)
			elseif research.status == "NOT_STARTED" then
				local fulfilled = true
				if research.requirements then
					for _, requirement in pairs(research.requirements) do
						fulfilled = fulfilled and requirement.fulfilled
					end
				end
				if fulfilled then
					table.insert(not_started_list, research)
				else
					table.insert(not_fulfilled_list, research)
				end
			elseif research.status == "FINISHED" then
				handle_research_list(category, research.children, depth + 1)
			end
		end
	end
	
	local researches = colony.getResearch()
	for category, research_list in pairs(researches) do
		category = category:sub(category:find(":") + 1)
		category = category:sub(1,1):upper() .. category:sub(2)
		handle_research_list(category, research_list, 0)
	end
	
    -- Time to monitorize!
	monitors.research.reset()
	local no_request = true

	local header_shown = false
    for _, research in pairs(in_progress_list) do
        if not header_shown then
            monitors.research.print(monitors.research.row, "center", "Researches")
            monitors.research.row = monitors.research.row + 1
            header_shown = true
			no_request = false
        end
		
		local color = colors.yellow
		if research.progress > 75 then color = colors.green end
		
		local bar = string.rep("#", math.floor(research.progress / 10)) .. string.rep(" ", 10 - math.floor(research.progress / 10))
		
        monitors.research.print(monitors.research.row, "left", string.format("[%s] %s", research.category, research.name) .. " ", color)
        monitors.research.print(monitors.research.row, "right", " " .. string.format("[%s]%3d%%", bar, research.progress), color)
        monitors.research.row = monitors.research.row + 1
    end
	
	local header_shown = false
    for _, research in pairs(not_started_list) do
		if not header_shown then
			if monitors.research.row > 3 then monitors.research.row = monitors.research.row + 1 end
            monitors.research.print(monitors.research.row, "center", "Researches (Ready)")
            monitors.research.row = monitors.research.row + 1
            header_shown = true
			no_request = false
        end
		
        monitors.research.print(monitors.research.row, "left", string.format("[%s - %3.1fh] %s", research.category, research.time, research.name), colors.lightBlue)
		monitors.research.row = monitors.research.row + 1
		
		if config.research.description then
			for _, effect in pairs(research.researchEffects) do
				monitors.research.print(monitors.research.row, "left", "  - " .. effect, colors.lightBlue)
				monitors.research.row = monitors.research.row + 1		
			end
		end
    end

	local header_shown = false
    for _, research in pairs(not_fulfilled_list) do
		if not header_shown then
			if monitors.research.row > 3 then monitors.research.row = monitors.research.row + 1 end
            monitors.research.print(monitors.research.row, "center", "Researches (Requirements not met)")
            monitors.research.row = monitors.research.row + 1
            header_shown = true
			no_request = false
        end
		
        monitors.research.print(monitors.research.row, "left", string.format("[%s - %3.1fh] %s", research.category, research.time, research.name), colors.red)
		monitors.research.row = monitors.research.row + 1
		
		if config.research.description then
			for _, effect in pairs(research.researchEffects) do
				monitors.research.print(monitors.research.row, "left", "  - " .. effect, colors.red)
				monitors.research.row = monitors.research.row + 1		
			end
		end
    end

	if no_request then 
		monitors.research.print(monitors.research.row, "center", "No researches available") 
		monitors.research.row = monitors.research.row + 1
	end
	
	logging.log("Researches", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

function Scan_builds()
end

----------------------------------------------------------------------------
-- MAIN
----------------------------------------------------------------------------
local tick = config.internal
Scan()
timer.display(tick)

local TIMER = os.startTimer(1)
while true do
    local e = {os.pullEvent()}
    if e[1] == "timer" and e[2] == TIMER then
        local now = os.time()
        if now >= 5 and now < 19.5 then
            tick = tick - 1
            if tick <= 0 then
                Scan()
                tick = config.internal
            end
        end

        timer.display(tick)
        TIMER = os.startTimer(1)
    elseif e[1] == "monitor_touch" then
        os.cancelTimer(TIMER)
        Scan()
        tick = config.internal
        timer.display(tick)
        TIMER = os.startTimer(1)
    end
end