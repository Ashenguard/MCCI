local scanner = require("scanner")
local config  = require("config")
local logging = require("logging")

settings = {
    data = {}
}

-- Inherit data for monitors -- Todo a better solution
scanner.data.settings = settings.data

-- Daytime alarms
local functions = {}

function functions.daytime_alarm_activate()
    logging.debug("ACTIVATING")
    config.daytime_alarm = true
    config.save()

    settings.data[1][2] = {x="right", t="[x]", fg=colors.green, a=functions.daytime_alarm_deactivate}

end
function functions.daytime_alarm_deactivate()
    logging.debug("DEACTIVATING")
    config.daytime_alarm = false
    config.save()

    settings.data[1][2] = {x="right", t="[ ]", fg=colors.red, a=functions.daytime_alarm_activate}
end

table.insert(settings.data, {
    {x="left", t="Daytime Alarm:"},
    {x="right", t="..."}
})

if config.daytime_alarm then
    settings.data[1][2] = {x="right", t="[x]", fg=colors.green, a=functions.daytime_alarm_deactivate}
else
    settings.data[1][2] = {x="right", t="[ ]", fg=colors.red, a=functions.daytime_alarm_activate}
end

return settings