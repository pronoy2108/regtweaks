@echo off & Title Automatic PPPoE connection & mode con cols=82 lines=13 & color 17
(Net session >nul 2>&1)&&(cd /d "%~dp0")||(PowerShell start """%~0""" -verb RunAs & Exit /B)

Set "Folder=%ProgramData%\Scripts\PPPoE"
If not exist "%Folder%" (mkdir "%Folder%")
COPY "Auto-connect.vbs" "%Folder%\Auto-connect.vbs"
Cls
echo.
echo      The script is creating a scheduled task of starting the PPPoE connection.
echo      Please wait for a while.
echo.

Set "Pop-up=%Folder%\Pop-up.ps1"
If exist "%Pop-up%" (del "%Pop-up%")
(
echo [reflection.assembly]::loadwithpartialname^("System.Windows.Forms"^)
echo [reflection.assembly]::loadwithpartialname^("System.Drawing"^)
echo $X = new-object system.windows.forms.notifyicon
echo $X.icon = [System.Drawing.SystemIcons]::Information
echo $X.visible = $true
echo $X.showballoontip^(10,"", "PPPoE connection has failed.",[system.windows.forms.tooltipicon]::None^)
echo $X.dispose^(^)
)> "%Pop-up%"

Set "【VBS】=%temp%\Task.vbs"
If exist "%【VBS】%" (Del "%【VBS】%")
Set "【XML】=%temp%\PPPoE.xml"
IF EXIST "%【XML】%" (DEL "%【XML】%")

echo Set X=CreateObject("Scripting.FileSystemObject") >> "%【VBS】%"
echo Set Z=X.CreateTextFile("%【XML】%",True,True)>> "%【VBS】%"
Set "W=echo Z.writeline "
(
%W%"<?xml version=""1.0"" encoding=""UTF-16""?>"
%W%"<Task version=""1.4"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">"
%W%"<RegistrationInfo>"
%W%"<Author>Matthew Wai</Author>"
%W%"<Description>Automatically start the PPPoE connection on Windows startup, after Windows wakes up (from sleep or hibernation), when any user logs on, and when the network cable is plugged in.</Description>"
%W%"</RegistrationInfo>"
%W%"<Triggers>"
%W%"<LogonTrigger>"
%W%"<Enabled>true</Enabled>"
%W%"</LogonTrigger>"
%W%"<EventTrigger>"
%W%"<Enabled>true</Enabled>"
%W%"<Subscription>&lt;QueryList&gt;&lt;Query Id=""0"" Path=""System""&gt;&lt;Select Path=""System""&gt;*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>"
%W%"</EventTrigger>"
%W%"<EventTrigger>"
%W%"<Enabled>true</Enabled>"
%W%"<Subscription>&lt;QueryList&gt;&lt;Query Id=""0"" Path=""Microsoft-Windows-NetworkProfile/Operational""&gt;&lt;Select Path=""Microsoft-Windows-NetworkProfile/Operational""&gt;*[System[Provider[@Name='Microsoft-Windows-NetworkProfile'] and EventID=4001]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>"
%W%"</EventTrigger>"
%W%"</Triggers>"
%W%"<Principals>"
%W%"<Principal id=""Author"">"
%W%"<GroupId>S-1-1-0</GroupId>"
%W%"<RunLevel>LeastPrivilege</RunLevel>"
%W%"</Principal>"
%W%"</Principals>"
%W%"<Settings>"
%W%"<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>"
%W%"<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>"
%W%"<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>"
%W%"<AllowHardTerminate>true</AllowHardTerminate>"
%W%"<StartWhenAvailable>false</StartWhenAvailable>"
%W%"<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>"
%W%"<IdleSettings>"
%W%"<StopOnIdleEnd>true</StopOnIdleEnd>"
%W%"<RestartOnIdle>false</RestartOnIdle>"
%W%"</IdleSettings>"
%W%"<AllowStartOnDemand>true</AllowStartOnDemand>"
%W%"<Enabled>true</Enabled>"
%W%"<Hidden>false</Hidden>"
%W%"<RunOnlyIfIdle>false</RunOnlyIfIdle>"
%W%"<DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>"
%W%"<UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>"
%W%"<WakeToRun>false</WakeToRun>"
%W%"<ExecutionTimeLimit>PT72H</ExecutionTimeLimit>"
%W%"<Priority>7</Priority>"
%W%"</Settings>"
%W%"<Actions Context=""Author"">"
%W%"<Exec>"
%W%"<Command>wscript.exe</Command>"
%W%"<Arguments>""%Folder%\Auto-connect.vbs""</Arguments>"
%W%"</Exec>"
%W%"</Actions>"
%W%"</Task>"
)>> "%【VBS】%"
echo Z.Close >> "%【VBS】%" & "%【VBS】%"
Del "%【VBS】%"

Schtasks /create /xml "%【XML】%" /tn "PPPoE"
If %errorlevel%==1 (DEL "%【XML】%" & echo.
echo   ============================================================================
echo           The script has failed to create the task "PPPoE".
echo           The task might already exist in "Task Scheduler Library".
echo           Press any key to close this message.
echo   ============================================================================
pause > nul & Exit) else (DEL "%【XML】%" & echo.
echo   ============================================================================
echo           The task "PPPoE" is in "Task Scheduler Library".
echo           The PPPoE connection will be started automatically.
echo           You may edit/disable/delete the task if need be.
echo           Please press any key to close this message.
echo   ============================================================================
pause > nul & Exit)

