local scanner = require("scanner")
local config  = require("config")
local logging = require("logging")

local settings = {
    data = {}
}
local functions = {}

-- Inherit data for monitors -- Todo a better solution
scanner.data.settings = settings.data

-- Internal
function functions.internal_increase()
    config.internal = math.min(config.internal + 1, 60)
    config.save()

    settings.data[1][3].t = string.format(" %2d    ", config.internal)
end
function functions.internal_decrease()
    config.internal = math.max(config.internal - 1, 5)
    config.save()

    settings.data[1][3].t = string.format(" %2d    ", config.internal)
end

table.insert(settings.data, {
    {x="left", t="Internal:"},
    {x="right", t="[+]       ", fg=colors.green, a=functions.internal_increase},
    {x="right", t=string.format(" %2d    ", config.internal), fg=colors.lightBlue},
    {x="right", t="[-]", fg=colors.red, a=functions.internal_decrease}
})

-- Daytime alarms
function functions.daytime_alarm_activate()
    config.daytime_alarm = true
    config.save()

    settings.data[2][2] = {x="right", t="[x]", fg=colors.green, a=functions.daytime_alarm_deactivate}

end
function functions.daytime_alarm_deactivate()
    config.daytime_alarm = false
    config.save()

    settings.data[2][2] = {x="right", t="[ ]", fg=colors.red, a=functions.daytime_alarm_activate}
end

table.insert(settings.data, {
    {x="left", t="Daytime Alarm:"},
    {x="right", t="..."}
})

if config.daytime_alarm then
    settings.data[2][2] = {x="right", t="[x]", fg=colors.green, a=functions.daytime_alarm_deactivate}
else
    settings.data[2][2] = {x="right", t="[ ]", fg=colors.red, a=functions.daytime_alarm_activate}
end

return settings