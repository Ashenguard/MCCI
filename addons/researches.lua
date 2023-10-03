local config  = require("config")
local logging = require("logging")

local colony  = require("addons.colony")

local researches = {
    data = {}
}

function researches.scan(data, force)
    local now = os.time()
    if not force and (now < 5 or now > 19.5) then
        return
    end

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
				research.progress = math.ceil(research.progress / research.time / 3)

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
	
	for category, research_list in pairs(colony.getResearch()) do
		category = category:sub(category:find(":") + 1)
		category = category:sub(1,1):upper() .. category:sub(2)
		handle_research_list(category, research_list, 0)
	end
	
    -- Time to save data!
	for k in pairs(data) do data[k] = nil end
	local no_request = true

    local header_1 = false
    for _, research in pairs(in_progress_list) do
        if not header_1 then
            table.insert(data, {
                {x="center", t="Researches (In progress)"}
            })
            header_1 = true
			no_request = false
        end
        local color = colors.orange
        if research.progress > 25 then color = colors.yellow end
        if research.progress > 50 then color = colors.lightBlue end
		if research.progress > 75 then color = colors.green end

		local bar = string.rep("#", math.floor(research.progress / 10)) .. string.rep(" ", 10 - math.floor(research.progress / 10))

        table.insert(data, {
            {x="left" , t=string.format("[%s] %s", research.category, research.name), fg=color},
            {x="right", t=string.format("[%s]%3d%%", bar, research.progress)        , fg=color}
        })
    end
    if header_1 then
        table.insert(data, {})
    end

    local shown = {line = 0, value = {}, list = {}}
    local function hide_info(monitor)
        if shown.line == 0 then
            return
        end

        logging.debug(shown.line)

        data[shown.line] = shown.value
        table.sort(shown.list, function (a, b) return a > b end)
        for _, l in ipairs(shown.list) do
            logging.debug(l, textutils.serialise(data[l]))
            table.remove(data, l)
        end

        shown = {line = 0, value = {}, list = {}}
    end

    local header_2 = false
    for _, research in pairs(not_started_list) do
        if not header_2 then
            table.insert(data, {
                {x="center", t="Researches (Can be researched)"}
            })
            header_2 = true
			no_request = false
        end
        
        local cost_line = #data + 2
        local function show_info(monitor)
            hide_info()

            shown.line = cost_line - 1
            shown.value = data[shown.line]

            data[cost_line - 1] = {
                {x="left" , t=string.format("    [%s - %3.1fh] %s", research.category, research.time, research.name), fg=colors.lightBlue},
                {x="left" , t="[-]", fg=colors.red, a=hide_info}
            }
            for i, item in pairs(research.cost) do
                table.insert(shown.list, cost_line + i - 1)
                table.insert(data, cost_line, {
                    {x="left" , t="  - " .. item.count .. "x " .. item.displayName:sub(2, -2), fg=colors.lightGray}
                })
            end
        end

        table.insert(data, {
            {x="left" , t=string.format("    [%s - %3.1fh] %s", research.category, research.time, research.name), fg=colors.lightBlue},
            {x="left" , t="[+]", fg=colors.green, a=show_info}
        })

		for _, effect in pairs(research.researchEffects) do
            table.insert(data, {
                {x="left" , t="  - " .. effect, fg=colors.lightGray}
            })
		end
    end
    if header_2 then
        table.insert(data, {})
    end

    local header_3
    for _, research in pairs(not_fulfilled_list) do
        if not header_3 then
            table.insert(data, {
                {x="center", t="Researches (Not unlocked)"}
            })
            header_3 = true
			no_request = false
        end

        table.insert(data, {
            {x="left" , t=string.format("[%s - %3.1fh] %s", research.category, research.time, research.name), fg=colors.red}
        })

        for _, requirement in ipairs(research.requirements) do
            table.insert(data, {
                {x="left" , t=" [" .. (requirement.fulfilled and "X" or " ") .. "] " .. requirement.desc, fg=requirement.fulfilled and colors.green or colors.pink}
            })
        end

        for _, effect in pairs(research.researchEffects) do
            table.insert(data, {
                {x="left" , t="  - " .. effect, fg=colors.pink}
            })
        end
    end
    if header_3 then
        table.insert(data, {})
    end
	
	if no_request then
        table.insert(data, {x="center", t="No researches found", fg=colors.white, bg=colors.green})
	end
	
	logging.log("Researches", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

return researches