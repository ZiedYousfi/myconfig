#Requires AutoHotkey v2.0
#SingleInstance Force

; --- Scroll ---
F17::WheelUp
F18::WheelDown

; --- F19 → Alt+Tab spam ---
F19::
{
    Send "{Alt down}{Tab}"  ; Premier Tab
    Sleep 1000               ; Délai avant le spam
    
    ; Tant que F19 est maintenue, on envoie Tab en boucle
    while GetKeyState("F19", "P")
    {
        Send "{Tab}"
        Sleep 300           ; Vitesse du spam (ajuste si besoin)
    }
    
    Send "{Alt up}"         ; Relâche Alt quand tu lâches F19
}