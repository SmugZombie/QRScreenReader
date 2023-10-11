#Persistent
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%
Menu, Tray, Icon, qrcode.ico

; Hotkey to trigger the screen capture and QR code decoding
F1::ScanAndDecodeQRCode()

ScanAndDecodeQRCode() {
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
        ToolTip, No QR Code Detected
        Sleep, 2000
        ToolTip ; Hide the tooltip after 2 seconds
    }

    ; Cleanup
    FileDelete, screen.png
    FileDelete, output.txt
}

return
