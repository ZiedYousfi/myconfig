-- /etc/libinput/plugins/10-mouse-sensitivity.lua

local version = libinput:register({1})

libinput:log_info("mouse sensitivity plugin loaded")

-- > 1 is faster/< 1 is slower
local SENSITIVITY = 2.0

libinput:connect("new-evdev-device", function (device)
    local usages = device:usages()

    if not usages[evdev.REL_X] or not usages[evdev.REL_Y] then
        return
    end

    libinput:log_info("sensitivity enabled for " .. device:name())

    device:connect("evdev-frame", function (device, frame, timestamp)
        local changed = false

        for _, event in ipairs(frame) do
            if event.usage == evdev.REL_X or event.usage == evdev.REL_Y then
                event.value = math.floor(event.value * SENSITIVITY)
                changed = true
            end
        end

        if changed then
            return frame
        end

        return nil
    end)
end

)
