local logging = require("logging")

local colony  = require("addons.colony")

local rs      = require("addons.rs")

local works = {
    data = {}
}

local color_map = {
    DISABLED  = colors.red,
    FAILED    = colors.red,
    SKIPPED   = colors.blue,
    CRAFTING  = colors.orange,
    SCHEDULED = colors.yellow,
    DONE      = colors.green
}

function works.scan(data, force)
    local now = os.time()
    if not force and (now < 5 or now > 19.5) then
        return
    end
    
    logging.log("Work requests", "Scan started at" .. textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

    local builder_list = {}
    local nonbuilder_list = {}
    local equipment_list = {}

    for _, request in pairs(colony.getRequests()) do
        local name = request.name
        local item = request.items[1].name
        local target = request.target
        local desc = request.desc
        local needed = request.count
		
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
		
        -- Handle request by rs or me
		local rs_result, provided, crafted = rs.handle_request(request)
        
        local color = color_map[rs_result]

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

    -- Time to save data!
    for k in pairs(data) do data[k] = nil end
	local no_request = true

    local header_1 = false
    for _, equipment in pairs(equipment_list) do
        if not header_1 then
            table.insert(data, {
                {x="center", t="Equipments"}
            })
            header_1 = true
			no_request = false
        end
        table.insert(data, {
            {x="left" , t=string.format("%d %s", equipment.needed, equipment.name), fg=equipment.color},
            {x="right", t=equipment.target                                        , fg=equipment.color}
        })
    end
    if header_1 then
        table.insert(data, {})
    end

    local header_2 = false
    for _, builder in pairs(builder_list) do
        if not header_2 then
            table.insert(data, {
                {x="center", t="Builders' Requests"}
            })
            header_2 = true
			no_request = false
        end
        table.insert(data, {
            {x="left" , t=string.format("%d/%s", builder.provided, builder.name), fg=builder.color},
            {x="right", t=builder.target                                        , fg=builder.color}
        })
    end
    if header_2 then
        table.insert(data, {})
    end

    local header_3 = false
    for _, nonbuilder in pairs(nonbuilder_list) do
        if not header_3 then
            table.insert(data, {
                {x="center", t="Nonbuilders' Requests"}
            })
            header_3 = true
			no_request = false
        end
        local text = string.format("%d %s", nonbuilder.needed, nonbuilder.name)
        if nonbuilder.name:match("^%d+") then
            text = string.format("%d/%s", nonbuilder.provided, nonbuilder.name)
        end
        table.insert(data, {
            {x="left" , t=text             , fg=nonbuilder.color},
            {x="right", t=nonbuilder.target, fg=nonbuilder.color}
        })
    end
    if header_3 then
        table.insert(data, {})
    end

    if no_request then
        table.insert(data, {{x="center", t="No open requests", fg=colors.white, bg=colors.green}})
	end
	
	logging.log("Work requests", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

return works