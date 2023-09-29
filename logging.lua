local logging = {}

logging.filename = "logging.log"

function logging.log(category, message, ...)
    if #arg > 0 then
        for s in arg do
            message = message .. " " .. arg
        end
    end

    print("[" .. category .. "] " .. message)

    local file = fs.open(logging.filename, 'a')
    file.writeLine(textutils.formatTime(os.time(), false) .. " - [" .. category .. "] " .. message)
    file.close()
end


return logging