#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Scroll ---
F17::WheelUp
F18::WheelDown

; --- F19 → Win+Tab ---
F19::Send("#{Tab}")