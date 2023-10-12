#Persistent
#NoEnv
APP_NAME := "QRScreenReader"
VERSION := "1.1.0"

SendMode Input
SetWorkingDir %A_ScriptDir%
#SingleInstance, force
#Include lib\WinRun.ahk

If ( !A_IsCompiled ) {
    ; If not compiled, use the local icon
    Menu, Tray, Icon, qrcode.ico
}

Menu, tray, NoStandard
Menu, tray, add, %APP_NAME% %VERSION%,Reload
Menu, tray, add,
Menu, tray, add, About,About
Menu, tray, add, Quit, Exit
Menu, tray, tip, %APP_NAME% %VERSION%

CHECKFORUPDATES := readConfig("checkforupdates", 0)
NOTIFICATIONS := readConfig("notifications", 1)
; Monitor the clipboard
OnClipboardChange("ClipChanged")

; Hotkey to trigger the screen capture and QR code decoding
F1::ScanDesktopAndDecodeQRCode()
^F1::ScanClipboardAndDecodeQRCode()
return

ClipChanged(Type) {
    if(Type == 2){
        Notify("Image Found In Clipboard, Hit Ctrl-F1 to scan for QR codes.")
    }
}

ScanClipboardAndDecodeQRCode() {
    global
    if DllCall("IsClipboardFormatAvailable", "Uint", 2){
        curr_clip := clipboard
        command = lib\clipjpg.exe
        response := CMDRun(command)
        if(clipboard != curr_clip)
        {
            ; Use ZBar to scan and decode the QR code from the screenshot
            RunWait, cmd /c %A_SCRIPTDIR%\lib\ZBar\zbarimg %Clipboard% > output.txt, , Hide

            ; Read the result and put it into clipboard
            FileRead, qrResult, output.txt
            if (ErrorLevel == 0 && qrResult != "")
            {
                StringReplace, qrResult, qrResult, `n, , All ; remove new lines
                Clipboard := qrResult
                ToolTip, QR Code Detected: %qrResult% ; Optionally show a tooltip with the detected content
                Sleep, 2000
                ToolTip ; Hide the tooltip after 2 seconds
            }
            else
            {
                Notify("No QR Code Detected")
                Sleep, 2000
                ToolTip ; Hide the tooltip after 2 seconds
            }

            ; Cleanup
            FileDelete, %Clipboard%
            FileDelete, output.txt
        }
    }
    else{
        Notify("No Image Detected in Clipboard")
    }
}

ScanDesktopAndDecodeQRCode() {
    ; Capture the whole screen
    RunWait, %A_SCRIPTDIR%\lib\nircmd.exe savescreenshotfull screen.png

    ; Use ZBar to scan and decode the QR code from the screenshot
    RunWait, cmd /c %A_SCRIPTDIR%\lib\ZBar\zbarimg screen.png > output.txt, , Hide

    ; Read the result and put it into clipboard
    FileRead, qrResult, output.txt
    if (ErrorLevel == 0 && qrResult != "")
    {
        StringReplace, qrResult, qrResult, `n, , All ; remove new lines
        Clipboard := qrResult
        ToolTip, QR Code Detected: %qrResult% ; Optionally show a tooltip with the detected content
        Sleep, 2000
        ToolTip ; Hide the tooltip after 2 seconds
    }
    else
    {
        Notify("No QR Code Detected")
        Sleep, 2000
        ToolTip ; Hide the tooltip after 2 seconds
    }

    ; Cleanup
    FileDelete, screen.png
    FileDelete, output.txt
}

readConfig(name, default=""){
    global
    RegRead, RegKeyValue, HKEY_CURRENT_USER\Software\%APP_NAME%, %name%
    if(RegKeyValue == ""){
        writeConfig(name, default)
        return default
    }

    return RegKeyValue
}

writeConfig(name, value){
    global
    RegWrite, REG_SZ, HKEY_CURRENT_USER\Software\%APP_NAME%, %name%, %value%
    return
}

Notify(message){
    global
    if(NOTIFICATIONS != 1)
    { 
        return 
    }
    goSub RemoveTrayTip
    TrayTip, %APP_NAME%, %message%
    SetTimer, RemoveTrayTip, 2500
    return
}

About:
    Run, https://www.github.com/smugzombie/qrscreenreader
return

RemoveTrayTip:
SetTimer, RemoveTrayTip, Off
TrayTip
return

Exit:
Shutdown:
ExitApp

Reload:
Reload