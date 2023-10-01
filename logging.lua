local logging = {}

logging.filename = "logging.log"

function logging.log(category, message, ...)
    for i, s in pairs(arg) do
        if i ~= "n" then message = message .. " " .. s end
    end

    local file = fs.open(logging.filename, 'a')
    file.writeLine(textutils.formatTime(os.time(), false) .. " - [" .. category .. "] " .. message)
    file.close()

    print("[" .. category .. "] " .. message)
end

function logging.error(category, message, ...)
    for i, s in pairs(arg) do
        if i ~= "n" then message = message .. " " .. s end
    end

    local file = fs.open(logging.filename, 'a')
    file.writeLine(textutils.formatTime(os.time(), false) .. " - [" .. category .. "] " .. message)
    file.close()

    error("[" .. category .. "] " .. message)
end

-- Clean the log file!
function logging.reset()
    local file = fs.open("logging.log", "w")
    file.writeLine("Logging started at " .. textutils.formatTime(os.time(), false) .. " (" .. os.time() .. ").")
    file.close()
end

return logging