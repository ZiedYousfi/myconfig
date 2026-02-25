#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
#MaxThreadsPerHotkey 4

HOLD_THRESHOLD := 400  ; ms

homeRowActive      := false
disabledModeActive := false

keyStates := Map()

A_TrayMenu.Delete()
A_TrayMenu.Add("Home Row Mods : OFF", ToggleHomeRow)
A_TrayMenu.Add("Disabled Mode : OFF", ToggleDisabledMode)
A_TrayMenu.Add()
A_TrayMenu.Add("Quitter", (*) => ExitApp())

ToggleHomeRow(*) {
    global homeRowActive, disabledModeActive
    if disabledModeActive {
        disabledModeActive := false
        A_TrayMenu.Rename("Disabled Mode : ON ✅", "Disabled Mode : OFF")
        SetDisabledModeHotkeys("Off")
    }
    homeRowActive := !homeRowActive
    if homeRowActive {
        A_TrayMenu.Rename("Home Row Mods : OFF", "Home Row Mods : ON ✅")
        SetHomeRowHotkeys("On")
    } else {
        A_TrayMenu.Rename("Home Row Mods : ON ✅", "Home Row Mods : OFF")
        SetHomeRowHotkeys("Off")
    }
}

ToggleDisabledMode(*) {
    global homeRowActive, disabledModeActive
    if homeRowActive {
        homeRowActive := false
        A_TrayMenu.Rename("Home Row Mods : ON ✅", "Home Row Mods : OFF")
        SetHomeRowHotkeys("Off")
    }
    disabledModeActive := !disabledModeActive
    if disabledModeActive {
        A_TrayMenu.Rename("Disabled Mode : OFF", "Disabled Mode : ON ✅")
        SetDisabledModeHotkeys("On")
    } else {
        A_TrayMenu.Rename("Disabled Mode : ON ✅", "Disabled Mode : OFF")
        SetDisabledModeHotkeys("Off")
    }
}

HandleModTap(key, modDown, modUp, waitKey := "") {
    global keyStates, HOLD_THRESHOLD

    wk := (waitKey != "") ? waitKey : key

    if keyStates.Has(key)
        return
    keyStates[key] := true

    startTime := A_TickCount
    isHold := false

    while GetKeyState(wk, "P") {
        if (A_TickCount - startTime >= HOLD_THRESHOLD) {
            isHold := true
            break
        }
        Sleep(10)
    }

    if (isHold) {
        SendEvent(modDown)
        KeyWait(wk)
        SendEvent(modUp)
    } else {
        ; Désactive brièvement SEULEMENT pour le tap
        hotkeyName := "*$" . key
        HotKey(hotkeyName, "Off")
        SendEvent("{" . key . "}")
        HotKey(hotkeyName, "On")
    }

    keyStates.Delete(key)
}

SetHomeRowHotkeys(state) {
    for key, mods in Map(
        "a", ["{LWin Down}", "{LWin Up}"],
        "s", ["{LAlt Down}", "{LAlt Up}"],
        "d", ["{LCtrl Down}", "{LCtrl Up}"],
        "f", ["{LShift Down}", "{LShift Up}"],
        "j", ["{RShift Down}", "{RShift Up}"],
        "k", ["{RCtrl Down}", "{RCtrl Up}"],
        "l", ["{RAlt Down}", "{RAlt Up}"],
        ";", ["{RWin Down}", "{RWin Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey(
            "*$" . key,
            ((k, md, mu) => (*) => HandleModTap(k, md, mu))(key, modDown, modUp),
            state
        )
    }
}

SetDisabledModeHotkeys(state) {
    for key, mods in Map(
        "SC056", ["{LWin Down}", "{LWin Up}"],  ; ou "vkE2"
        "a",     ["{LAlt Down}", "{LAlt Up}"],
        "q",     ["{LCtrl Down}", "{LCtrl Up}"],
        "w",     ["{LShift Down}", "{LShift Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey(
            "*$" . key,
            ((k, md, mu) => (*) => HandleModTap(k, md, mu))(key, modDown, modUp),
            state
        )
    }
}

$F17::Send("{WheelUp}")
$F18::Send("{WheelDown}")
$F19::Send("#{Tab}")
