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

HandleModTap(key, modDown, modUp) {
    global keyStates, HOLD_THRESHOLD

    if keyStates.Has(key)
        return
    keyStates[key] := { tick: A_TickCount, modSent: false }

    ih := InputHook("L0 T" . (HOLD_THRESHOLD / 1000))
    ih.KeyOpt("{" . key . "}", "S")
    ih.Start()

    released := KeyWait(key, "T" . (HOLD_THRESHOLD / 1000))
    ih.Stop()

    if keyStates.Has(key) {
        state := keyStates[key]
        keyStates.Delete(key)

        if released {
            SendEvent("{Blind}{" . key . "}")
        } else {
            SendEvent(modDown)
            KeyWait(key)
            SendEvent(modUp)
        }
    }
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
        "x", ["{LWin Down}", "{LWin Up}"],
        "d", ["{LAlt Down}", "{LAlt Up}"],
        "e", ["{LCtrl Down}", "{LCtrl Up}"],
        "f", ["{LShift Down}", "{LShift Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey(
            "*$" . key,
            ((k, md, mu) => (*) => HandleModTap(k, md, mu))(key, modDown, modUp),
            state
        )
    }
}

F17::WheelUp
F18::WheelDown
F19::Send("#{Tab}")
