@echo off & title Undo everything. & mode con cols=78 lines=6 & color 17
(Net session >nul 2>&1)||(PowerShell start """%~0""" -verb RunAs & Exit /B)

Echo.
Schtasks /delete /tn "PPPoE" /f
RmDir /s /q "%ProgramData%\Scripts\PPPoE\"
RmDir "%ProgramData%\Scripts\">nul 2>&1
Echo.
Echo         The script for starting the PPPoE connection has been removed.
Echo         Please press a key to close this message.
Pause>nul
Exit
