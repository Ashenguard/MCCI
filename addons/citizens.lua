local logging = require("logging")
local utils   = require("utils")

local colony  = require("addons.colony")

local citizens = {}

local function sort_citizens(a, b)
    if a.age ~= b.age then
        return b.age == "child"
    end
    if #a.tags ~= #b.tags then
        return #a.tags > #b.tags
    end
    if a.job ~= b.job then
        return a.job < b.job
    end
    return a.name < b.name
end

function citizens.scan(data, force)
    local now = os.time()
    if not force and (now < 5 or now > 19.5) then
        return
    end
    
    logging.log("Citizens", "Scan started at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")

    local general_list = {}
    for _, citizen in ipairs(colony.getCitizens()) do
        citizen.tags = {}
        local ht = 0
        
        citizen.job = "Unemployed"
        citizen.gender = citizen.gender:sub(1, 1):upper()

        if citizen.work then
            citizen.job = citizen.work.job:gsub(".*%.", "")
            citizen.job = citizen.job:sub(1, 1):upper() .. citizen.job:sub(2):lower()

            local work_distance = utils.distance(citizen.bedPos, citizen.work.location)
            -- This is bugged (Bed position is sent as 0, 0, 0)
            if false and work_distance > 50 then
                local tag = {name="[Long work distance]", color=colors.yellow}
                ht = math.max(ht, 1)
                if work_distance > 100 then
                    tag.color = colors.orange
                    ht = math.max(ht, 2)
                end
                if work_distance > 200 then
                    tag.color = colors.red
                    ht = math.max(ht, 3)
                end
                table.insert(citizen.tags, tag)
            end
        end
        
        if citizen.health < 0.75 * citizen.maxHealth then
            local tag = {name="[Harmed]", color=colors.yellow}
            ht = math.max(ht, 1)
            if citizen.health < 0.5 * citizen.maxHealth then
                tag.color = colors.orange
                ht = math.max(ht, 2)
            end
            if citizen.health < 0.25 * citizen.maxHealth then
                tag.color = colors.red
                ht = math.max(ht, 3)
             end
            table.insert(citizen.tags, tag)
        end

        if citizen.saturation < 10 then
            local tag = {name="[Hungry]", color=colors.yellow}
            ht = math.max(ht, 1)
            if citizen.saturation < 7.5 then
                tag.color = colors.orange
                ht = math.max(ht, 2)
            end
            if citizen.saturation < 4 then
                tag.color = colors.red
                ht = math.max(ht, 3)
            end
            table.insert(citizen.tags, tag)
        end

        if citizen.state == "Sick" then
            table.insert(citizen.tags, {name="[Sick]", color=colors.red})
            ht = math.max(ht, 3)
            citizen.state = nil   -- Just to avoid dup
        end

        citizen.color = colors.lightBlue
        if ht == 1 then citizen.color = colors.yellow end
        if ht == 2 then citizen.color = colors.orange end
        if ht == 3 then citizen.color = colors.red end

        table.insert(general_list, citizen)
    end

    table.sort(general_list, sort_citizens)


    -- Time to save data!
    for k in pairs(data) do data[k] = nil end

    for _, citizen in pairs(general_list) do
        table.insert(data, {
            {x="left" , t=string.format("[%s%s] %s - %s ", citizen.gender, citizen.age == "child" and "C" or " ", citizen.job, citizen.name), fg=citizen.color},
            {x="right", t=citizen.state, fg=colors.lightGray}
        })
        local line = {}
        local tag_space = 0
        for _, tag in ipairs(citizen.tags) do
            table.insert(line, 1, {x="right", t=tag.name .. string.rep(" ", tag_space), fg=tag.color})
            tag_space = tag_space + #tag.name + 1
        end
        if #line > 0 then table.insert(data, line) end
    end

    if #general_list == 0 then
        table.insert(data, {{x="center", t="No citizens found", fg=colors.white, bg=colors.red}})
	end

    logging.log("Citizens", "Scan completed at", textutils.formatTime(os.time(), false) .. " (" .. os.time() ..").")
end

return citizens