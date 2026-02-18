#Requires AutoHotkey v2.0
#SingleInstance Force
InstallKeybdHook()

; ─────────────────────────────────────────
;  CONFIG
; ─────────────────────────────────────────
HOLD_THRESHOLD := 150  ; ms

homeRowActive      := false
disabledModeActive := false

; Map pour tracker le temps de pression de chaque touche
keyTimers := Map()

; ─────────────────────────────────────────
;  TRAY MENU
; ─────────────────────────────────────────
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

; ─────────────────────────────────────────
;  UTILITAIRE TAP/HOLD via KeyDown + KeyUp
;  KeyDown : on note l'heure, on bloque
;  KeyUp   : on décide tap ou hold
; ─────────────────────────────────────────
OnKeyDown(key) {
    global keyTimers
    ; On ignore les répétitions auto (touche déjà dans le map)
    if keyTimers.Has(key)
        return
    keyTimers[key] := A_TickCount
}

OnKeyUp(key, modDown, modUp) {
    global keyTimers, HOLD_THRESHOLD
    if !keyTimers.Has(key)
        return
    elapsed := A_TickCount - keyTimers[key]
    keyTimers.Delete(key)

    if (elapsed < HOLD_THRESHOLD) {
        ; Tap → envoie le caractère
        Send("{Blind}{" key "}")
    } else {
        ; Hold → le mod a déjà été envoyé au down, on le relâche
        Send(modUp)
    }
}

OnKeyDownMod(key, modDown) {
    global keyTimers, HOLD_THRESHOLD
    if keyTimers.Has(key)
        return
    keyTimers[key] := A_TickCount
    ; On attend le seuil en arrière-plan via SetTimer
    SetTimer(() => CheckHold(key, modDown), -HOLD_THRESHOLD)
}

CheckHold(key, modDown) {
    global keyTimers, HOLD_THRESHOLD
    if !keyTimers.Has(key)
        return
    if (A_TickCount - keyTimers[key] >= HOLD_THRESHOLD) {
        if GetKeyState(key, "P")  ; toujours appuyée ?
            Send(modDown)
    }
}

; ─────────────────────────────────────────
;  HOME ROW MODS — ISO QWERTY
;  A=Super  S=Alt  D=Ctrl  F=Shift
;  J=Shift  K=Ctrl  L=Alt  ;=Super
; ─────────────────────────────────────────
SetHomeRowHotkeys(state) {
    for key, mods in Map(
        "a", ["{LWin Down}", "{LWin Up}"],
        "s", ["{Alt Down}", "{Alt Up}"],
        "d", ["{Ctrl Down}", "{Ctrl Up}"],
        "f", ["{Shift Down}", "{Shift Up}"],
        "j", ["{Shift Down}", "{Shift Up}"],
        "k", ["{Ctrl Down}", "{Ctrl Up}"],
        "l", ["{Alt Down}", "{Alt Up}"],
        ";", ["{LWin Down}", "{LWin Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey("$" key, ((k, md) => (*) => OnKeyDownMod(k, md))(key, modDown), state)
        HotKey("$" key " up", ((k, md, mu) => (*) => OnKeyUp(k, md, mu))(key, modDown, modUp), state)
    }
}

; ─────────────────────────────────────────
;  DISABLED MODE — ISO QWERTY
;  X=Super  D=Alt  E=Ctrl  3=Shift
; ─────────────────────────────────────────
SetDisabledModeHotkeys(state) {
    for key, mods in Map(
        "x", ["{LWin Down}", "{LWin Up}"],
        "d", ["{Alt Down}", "{Alt Up}"],
        "e", ["{Ctrl Down}", "{Ctrl Up}"],
        "3", ["{Shift Down}", "{Shift Up}"]
    ) {
        modDown := mods[1], modUp := mods[2]
        HotKey("$" key, ((k, md) => (*) => OnKeyDownMod(k, md))(key, modDown), state)
        HotKey("$" key " up", ((k, md, mu) => (*) => OnKeyUp(k, md, mu))(key, modDown, modUp), state)
    }
}

; ─────────────────────────────────────────
;  SCRIPT DE BASE
; ─────────────────────────────────────────
F17::WheelUp
F18::WheelDown
F19::Send("#{Tab}")
