@echo off & mode con cols=88 lines=8 & color 17
(Net session >nul 2>&1)||(PowerShell start """%~0""" -verb RunAs & Exit /B)

cd /d "%~dp0"
Reg delete "HKCR\Elevated_lnk" /f
Reg delete "HKCR\.lnk_elevated" /f
Schtasks /delete /tn "Apps\Create_an_elevated_shortcut" /f
Del "%ProgramData%\Elevated Shortcut\Create_an_elevated_shortcut.cmd"
RmDir "%ProgramData%\Elevated Shortcut\"

Echo     Please press a key to close this message.
Pause>nul
Exit
