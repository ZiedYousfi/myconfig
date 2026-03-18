#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()
#MaxThreadsPerHotkey 4

Persistent
CoordMode "Mouse", "Screen"

; Make the taskbar transparent
WinSetTransparent 0, "ahk_class Shell_TrayWnd"

HOLD_THRESHOLD := 400  ; ms

homeRowActive      := false
disabledModeActive := false
valoModeActive     := false

keyStates := Map()

A_TrayMenu.Delete()
A_TrayMenu.Add("Home Row Mods : OFF", ToggleHomeRow)
A_TrayMenu.Add("Disabled Mode : OFF", ToggleDisabledMode)
A_TrayMenu.Add("Valo Mode : OFF", ToggleValoMode)
A_TrayMenu.Add()
A_TrayMenu.Add("Quitter", (*) => ExitApp())

ToggleHomeRow(*) {
    global homeRowActive, disabledModeActive, valoModeActive
    if disabledModeActive {
        disabledModeActive := false
        A_TrayMenu.Rename("Disabled Mode : ON ✅", "Disabled Mode : OFF")
        SetDisabledModeHotkeys("Off")
    }
    if valoModeActive {
        valoModeActive := false
        A_TrayMenu.Rename("Valo Mode : ON ✅", "Valo Mode : OFF")
        SetValoModeHotkeys("Off")
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
    global homeRowActive, disabledModeActive, valoModeActive
    if homeRowActive {
        homeRowActive := false
        A_TrayMenu.Rename("Home Row Mods : ON ✅", "Home Row Mods : OFF")
        SetHomeRowHotkeys("Off")
    }
    if valoModeActive {
        valoModeActive := false
        A_TrayMenu.Rename("Valo Mode : ON ✅", "Valo Mode : OFF")
        SetValoModeHotkeys("Off")
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

ToggleValoMode(*) {
    global homeRowActive, disabledModeActive, valoModeActive
    if homeRowActive {
        homeRowActive := false
        A_TrayMenu.Rename("Home Row Mods : ON ✅", "Home Row Mods : OFF")
        SetHomeRowHotkeys("Off")
    }
    if disabledModeActive {
        disabledModeActive := false
        A_TrayMenu.Rename("Disabled Mode : ON ✅", "Disabled Mode : OFF")
        SetDisabledModeHotkeys("Off")
    }
    valoModeActive := !valoModeActive
    if valoModeActive {
        A_TrayMenu.Rename("Valo Mode : OFF", "Valo Mode : ON ✅")
        SetValoModeHotkeys("On")
    } else {
        A_TrayMenu.Rename("Valo Mode : ON ✅", "Valo Mode : OFF")
        SetValoModeHotkeys("Off")
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
        hotkeyName := "*$" . key
        HotKey(hotkeyName, "Off")
        SendEvent("{" . key . "}")
        HotKey(hotkeyName, "On")
    }

    keyStates.Delete(key)
}

; Tap envoie tapKey, Hold envoie modDown/modUp
HandleModTapCustom(key, tapKey, modDown, modUp, waitKey := "") {
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
        SendEvent(tapKey)
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
        "z",     ["{LWin Down}", "{LWin Up}"],
        "a",     ["{LAlt Down}", "{LAlt Up}"],
        "s",     ["{LCtrl Down}", "{LCtrl Up}"],
        "w",     ["{LShift Down}", "{LShift Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey(
            "*$" . key,
            ((k, md, mu) => (*) => HandleModTap(k, md, mu))(key, modDown, modUp),
            state
        )
        HotKey("*$c", (*) => SendEvent("{F17}"), state)
        HotKey("*$v", (*) => SendEvent("{F18}"), state)
    }
}

SetValoModeHotkeys(state) {
    for key, cfg in Map(
        "2",  ["{e}",  "{q Down}", "{q Up}"],
        "1",  ["{.}",  "{b Down}", "{b Up}"],
        "q",  ["{=}",  "{g Down}", "{g Up}"],
        "F1", ["{i}",  "{f Down}", "{f Up}"],
        "3",  ["{v}",  "{r Down}", "{r Up}"],
        "z",  ["{c}",  "{n Down}", "{n Up}"]
    ) {
        tapKey := cfg[1], modDown := cfg[2], modUp := cfg[3]
        HotKey(
            "*$" . key,
            ((k, t, md, mu) => (*) => HandleModTapCustom(k, t, md, mu))(key, tapKey, modDown, modUp),
            state
        )
    }

    HotKey("*$s", (*) => SendEvent("{d}"), state)
}

; --- Global shortcuts ---

; Helper
pwsh(cmd) {
    Run 'pwsh.exe -NoProfile -Command "' cmd '"', , "Hide"
}

; --- Toggle shortcuts ---
!i:: pwsh("komorebic toggle-shortcuts")

; --- Focus ---
!h::
!Left:: pwsh("komorebic focus left")

!l::
!Right:: pwsh("komorebic focus right")

!k::
!Up:: pwsh("komorebic focus up")

!j::
!Down:: pwsh("komorebic focus down")

; --- Move windows --
!+h::
!+Left:: pwsh("komorebic move left")

!+j::
!+Down:: pwsh("komorebic move down")

!+k::
!+Up:: pwsh("komorebic move up")

!+l::
!+Right:: pwsh("komorebic move right")

; --- Focus workspace ---
!1:: pwsh("komorebic focus-workspace 0")
!2:: pwsh("komorebic focus-workspace 1")
!3:: pwsh("komorebic focus-workspace 2")
!4:: pwsh("komorebic focus-workspace 3")
!5:: pwsh("komorebic focus-workspace 4")
!6:: pwsh("komorebic focus-workspace 5")
!7:: pwsh("komorebic focus-workspace 6")
!8:: pwsh("komorebic focus-workspace 7")
!9:: pwsh("komorebic focus-workspace 8")
!0:: pwsh("komorebic focus-workspace 9")

; --- Move window to workspace ---
!+1:: pwsh("komorebic move-to-workspace 0")
!+2:: pwsh("komorebic move-to-workspace 1")
!+3:: pwsh("komorebic move-to-workspace 2")
!+4:: pwsh("komorebic move-to-workspace 3")
!+5:: pwsh("komorebic move-to-workspace 4")
!+6:: pwsh("komorebic move-to-workspace 5")
!+7:: pwsh("komorebic move-to-workspace 6")
!+8:: pwsh("komorebic move-to-workspace 7")
!+9:: pwsh("komorebic move-to-workspace 8")
!+0:: pwsh("komorebic move-to-workspace 9")

; --- Close window ---
!q:: pwsh("komorebic close")

; --- Mnimize window ---
!m:: pwsh("komorebic minimize")

; --- Open terminal ---
!+t:: Run 'pwsh.exe -NoProfile -Command "Start-Process wezterm -WindowStyle Hidden"', , "Hide"

; --- Restart Komorebi ---
!+r:: pwsh("komorebic stop --whkd; komorebic start --whkd")

; --- Toggle floating ---
!+Space:: pwsh("komorebic toggle-float")

$F17::Send("{WheelUp}")
$F18::Send("{WheelDown}")
$F19::Send("#{Tab}")
