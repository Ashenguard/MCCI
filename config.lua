local config = {}

local path = fs.combine(shell.getRunningProgram():gsub("(.*)startup%.lua$", ""), "config.ini")
do
    for line in io.lines(path) do
        if line:match("(.+)%s+=%s+(.+)") then
            local key, value = line:match("(.+)%s+=%s+(.+)")
            if value:match("^%d+$") then
                value = tonumber(value)
            end

            config[key] = value
        end
    end
end


function config.save()
    local lines = {}
    for line in io.lines(path) do
        if line:match("^(.+)%s+=%s+(.+)$") then
            local key, _ = line:match("^(.+)%s+=%s+(.+)$")
            if config[key] ~= nil then
                line = key .. " = " .. tostring(config[key])
            end
        end
        lines:insert(line)
    end
    
    local file = fs.open(path, "w")
    for _, line in ipairs(lines) do
        file.writeLine(line)
    end
    file.close()
end

return config
