local logging = require("logging")

local colony  = require("addons.colony")

local builds = {}

local function sort_builds(a, b)
    if a.level == b.level then
        return a.name < b.name
    end

    return a.level < b.level
end

function builds.scan(data, force)
    local now = os.time()
    if not force and (now < 5 or now > 19.5) then
        return
    end
    
    logging.log("Builds", "Scan started at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

    local working_list = {}
    local not_built_list = {}
    local unguarded_list = {}
    local built_list = {}
    local built_count = 0

    for _, build in pairs(colony.getBuildings()) do
        build.name = build.name:gsub("^.*%.", "")
        build.name = build.name:sub(1, 1):upper() .. build.name:sub(2):lower()

        if build.isWorkingOn then
            -- Will be read in orders
        elseif build.built then
            if build.guarded then
                built_count = built_count + 1
                if built_list[build.name] == nil then
                    built_list[build.name] = {}
                    built_list[build.name][build.level] = {count = 1, maxLevel = build.maxLevel}
                else
                    if built_list[build.name][build.level] == nil then
                        built_list[build.name][build.level] = {count = 1, maxLevel = build.maxLevel}
                    else
                        built_list[build.name][build.level]["count"] = built_list[build.name][build.level]["count"] + 1
                    end
                end
            else
                table.insert(unguarded_list, build)
            end
        elseif build.maxLevel > 1 then
            table.insert(not_built_list, build)
        end
    end

    local built_list_sorted = {}
    for name, temp in pairs(built_list) do
        for level, data in pairs(temp) do
            table.insert(built_list_sorted, {name=name, level=level, count=data.count, maxLevel=data.maxLevel})
        end
    end
    table.sort(built_list_sorted, sort_builds)

    for _, build in pairs(colony.getWorkOrders()) do
        build.name = build.buildingName:gsub("^.*%.", ""):gsub("^.*[/\\]", "")
        build.name = build.name:sub(1, 1):upper() .. build.name:sub(2):lower()
        if build.type:match("Building$") then
            if not build.isClaimed then
                build.progress = "Not Claimed"
            else
                local needed = 0
                local delive = 0
                local availa = 0

                local resources = colony.getWorkOrderResources(build.id)
                for _, resource in pairs(resources) do
                    needed = needed + resource.needed
                    delive = delive + resource.delivering
                    availa = availa + math.min(resource.available, resource.needed)
                end
                build.progress = string.format("%d%s/%d", availa, "(+" .. delive .. ")", needed)
            end
            if build.name:match("Tavern") then
                build.maxLevel = 3
            else
                build.maxLevel = 5
            end

            table.insert(working_list, build)
        end
    end

    logging.log("Builds", "Found", #working_list, "under construction buildings")
    logging.log("Builds", "Found", #unguarded_list, "unguarded buildings")
    logging.log("Builds", "Found", #not_built_list, "abondoned buildings")
    logging.log("Builds", "Found", built_count, "other buildings")

    -- Time to save data!
    for k in pairs(data) do data[k] = nil end
	local no_request = true

    local header_1 = false
    for _, build in pairs(working_list) do
        if not header_1 then
            table.insert(data, {
                {x="center", t="Ordered Buildings"},
                {x="right", t="Resources"}
            })
            header_1 = true
			no_request = false
        end
        local color = colors.yellow
        if build.progress == "Not Claimed" then color = colors.red end

        table.insert(data, {
            {x="left" , t=string.format("[%d/%d] %s", build.targetLevel, build.maxLevel, build.name), fg=color},
            {x="right", t=build.progress                                                            , fg=color}
        })
    end
    if header_1 then
        table.insert(data, {})
    end

    local header_2 = false
    for _, build in pairs(not_built_list) do
        if not header_2 then
            table.insert(data, {
                {x="center", t="Abondoned Buildings"}
            })
            header_2 = true
			no_request = false
        end

        table.insert(data, {
            {x="left" , t=string.format("[%d/%d] %s", build.level, build.maxLevel, build.name)              , fg=colors.orange},
            {x="right", t=string.format("At %d %d %d", build.location.x, build.location.y, build.location.z), fg=colors.orange}
        })
    end
    if header_2 then
        table.insert(data, {})
    end

    local header_3 = false
    for _, build in pairs(unguarded_list) do
        if not header_3 then
            table.insert(data, {
                {x="center", t="Unguarded Buildings"}
            })
            header_3 = true
			no_request = false
        end

        table.insert(data, {
            {x="left" , t=string.format("[%d/%d] %s", build.level, build.maxLevel, build.name)              , fg=colors.red},
            {x="right", t=string.format("At %d %d %d", build.location.x, build.location.y, build.location.z), fg=colors.red}
        })
    end
    if header_3 then
        table.insert(data, {})
    end

    local header_4 = false
    for _, build in pairs(built_list_sorted) do
        if not header_4 then
            table.insert(data, {
                {x="center", t="Other Buildings"}
            })
            header_4 = true
			no_request = false
        end

        table.insert(data, {
            {x="left" , t=string.format("[%d/%d] %dx %s", build.level, build.maxLevel, build.count, build.name), fg=colors.lightBlue}
        })
    end
    if header_4 then
        table.insert(data, {})
    end
	
	if no_request then 
        table.insert(data, {{x="center", t="No buildings... How?", fg=colors.white, bg=colors.red}})
	end

    logging.log("Builds", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

return builds