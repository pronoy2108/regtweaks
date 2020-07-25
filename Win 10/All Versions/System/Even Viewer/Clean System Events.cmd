@echo off
:: Start as Admin

:: Clean all event viewer and hidden logs
:: PS: wevtutil el | Foreach-Object {wevtutil cl “$_”}

::Apps
:: wevtutil cl application

:: System Logs
:: wevtutil cl system

:: Setup logs
:: wevtutil cl setup

:: Security Logs
:: wevtutil cl security

FOR /F "USEBACKQ DELIMS=" %%L IN (`WEVTUTIL EL`) DO WEVTUTIL CL "%%L"

echo.
echo.
echo Done
echo Press any key to exit.
pause >nul
