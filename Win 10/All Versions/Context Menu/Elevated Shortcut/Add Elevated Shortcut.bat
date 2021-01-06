@echo off & Title Add [Elevated Shortcut] into the context menu & mode con cols=93 lines=14 & color 17
(Net session >nul 2>&1)||(PowerShell start """%~0""" -verb RunAs & Exit /B)

cd /d "%~dp0"
Set "【Item】=Elevated Shortcut"
Set "【Name】=Create_an_elevated_shortcut"
Set "【Path】=%ProgramData%\Elevated Shortcut\Create_an_elevated_shortcut.cmd"
If not exist "%ProgramData%\Elevated Shortcut\" (mkdir "%ProgramData%\Elevated Shortcut\")

(REG ADD "HKCR\Elevated_lnk" /T REG_SZ /D "%【Item】%" /F)
(REG ADD "HKCR\.lnk_elevated" /T REG_SZ /D "Elevated_lnk" /F)
(REG ADD "HKCR\.lnk_elevated\ShellNew" /V "Command" /T REG_SZ /D "schtasks /run /tn ""Apps\%【Name】%""" /F)
(REG ADD "HKCR\.lnk_elevated\ShellNew" /V "IconPath" /T REG_SZ /D "%WinDir%\System32\imageres.dll,73" /F)
(REG ADD "HKCR\.lnk_elevated\ShellNew\Config" /V "BeforeSeparator" /F)
Cls
If errorlevel 1 (echo.
echo ====================================================================
echo.
echo          The script has failed to perform the operations.
echo          Press any key to exit.
echo.
echo ====================================================================
pause > nul & EXIT)
echo.
echo          The script is creating a new task with highest privileges.
echo          Please wait for a while.
echo.

IF exist "%【Path】%" (DEL "%【Path】%")
(

echo @echo off ^& Title Create an elevated shortcut without a UAC prompt ^& mode con cols=90 lines=22 ^& color 17
echo ^(Net session ^>nul 2^>^&1^)^|^|^(PowerShell start """%%~0""" -verb RunAs ^& Exit /B^)

echo cd /d "%%~dp0"
echo @ECHO OFF ^& setlocal
echo echo. ^& echo.
echo SET /P "【Name】= --> Please key in the name (without special characters) of the application you want to        run as an administrator (for example Elevated command prompt) and then press [Enter]:     "
echo echo. ^& echo.
echo Set "✉=    Please do not leave a space before or after the file path."
echo :Enter_the_path
echo SET /P "【Path】= --> Please key in (or copy and paste) the full path (without quotation marks) of the          application file (for example %windir%\System32\cmd.exe) and then press [Enter]:        "
echo.
echo Set "❤️=""%%【Path】%%"""
echo Set "(❤️)=%%❤️: ""=""%%"
echo Set "[❤️]=%%❤️:"" =""%%"
echo If not "%%❤️%%"=="%%(❤️)%%" ^(Echo. ^& Echo %%✉%% ^& Echo. ^& Goto Enter_the_path^)
echo If not "%%❤️%%"=="%%[❤️]%%" ^(Echo. ^& Echo %%✉%% ^& Echo. ^& Goto Enter_the_path^)
echo echo.
echo echo       The script is creating an elevated task with highest privileges.
echo echo       Please wait for a while.
echo echo.

echo For /f "tokens=*" %%%%I in ^('WhoAmI /user'^) Do ^(for %%%%A in ^(%%%%~I^) Do ^(set "【SID】=%%%%A"^)^)
echo Set "【Task_name】=%%【Name】: =_%%"
echo IF EXIST "%%temp%%\%%【Task_name】%%.xml" ^(DEL "%%temp%%\%%【Task_name】%%.xml"^)
echo IF EXIST "%%temp%%\Task.vbs" ^(DEL "%%temp%%\Task.vbs"^)
echo.
echo echo Set X=CreateObject^("Scripting.FileSystemObject"^) ^>^> "%%temp%%\Task.vbs"
echo echo Set Z=X.CreateTextFile^("%%temp%%\%%【Task_name】%%.xml",True,True^)^>^> "%%temp%%\Task.vbs"
echo Set "W=echo Z.writeline "
echo (
echo %%W%%"<?xml version=""1.0"" encoding=""UTF-16""?>"
echo %%W%%"<Task version=""1.4"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">"
echo %%W%%"<RegistrationInfo>"
echo %%W%%"<Author>%%username%%</Author>"
echo %%W%%"<Description>To run the application/CMD script as an administrator with no UAC prompt.</Description>"
echo %%W%%"</RegistrationInfo>"
echo %%W%%"<Triggers />"
echo %%W%%"<Principals>"
echo %%W%%"<Principal id=""Author"">"
echo %%W%%"<UserId>%%【SID】%%</UserId>"
echo %%W%%"<LogonType>InteractiveToken</LogonType>"
echo %%W%%"<RunLevel>HighestAvailable</RunLevel>"
echo %%W%%"</Principal>"
echo %%W%%"</Principals>"
echo %%W%%"<Settings>"
echo %%W%%"<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>"
echo %%W%%"<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>"
echo %%W%%"<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>"
echo %%W%%"<AllowHardTerminate>true</AllowHardTerminate>"
echo %%W%%"<StartWhenAvailable>false</StartWhenAvailable>"
echo %%W%%"<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>"
echo %%W%%"<IdleSettings>"
echo %%W%%"<StopOnIdleEnd>true</StopOnIdleEnd>"
echo %%W%%"<RestartOnIdle>false</RestartOnIdle>"
echo %%W%%"</IdleSettings>"
echo %%W%%"<AllowStartOnDemand>true</AllowStartOnDemand>"
echo %%W%%"<Enabled>true</Enabled>"
echo %%W%%"<Hidden>false</Hidden>"
echo %%W%%"<RunOnlyIfIdle>false</RunOnlyIfIdle>"
echo %%W%%"<DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>"
echo %%W%%"<UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>"
echo %%W%%"<WakeToRun>false</WakeToRun>"
echo %%W%%"<ExecutionTimeLimit>PT72H</ExecutionTimeLimit>"
echo %%W%%"<Priority>7</Priority>"
echo %%W%%"</Settings>"
echo %%W%%"<Actions Context=""Author"">"
echo %%W%%"<Exec>"
echo %%W%%"<Command>""%%【Path】%%""</Command>"
echo %%W%%"</Exec>"
echo %%W%%"</Actions>"
echo %%W%%"</Task>"
echo ^)^>^> "%%temp%%\Task.vbs"
echo echo Z.Close ^>^> "%%temp%%\Task.vbs"
echo "%%temp%%\Task.vbs"
echo Del "%%temp%%\Task.vbs"
echo schtasks /create /xml "%%temp%%\%%【Task_name】%%.xml" /tn "Apps\%%【Task_name】%%"
echo If errorlevel 1 ^(DEL "%%temp%%\%%【Task_name】%%.xml" ^& echo.
echo echo  =======================================================================================
echo echo     The script has failed to create the task. You may have entered a name already
echo echo     used in Task Scheduler or a name containing special characters/punctuation marks.
echo echo     Otherwise, you may have entered a file path that contains special characters or
echo echo     path. Press any key to close this message.
echo echo  =======================================================================================
echo pause ^> nul ^& Exit^) else ^(DEL "%%temp%%\%%【Task_name】%%.xml"^)
echo.
echo IF EXIST "%%temp%%\Shortcut.vbs" ^(DEL "%%temp%%\Shortcut.vbs"^)
echo (echo Set A = CreateObject^^^("WScript.Shell"^^^) ^& echo Desktop = A.SpecialFolders^^^("Desktop"^^^) ^& echo Set B = A.CreateShortcut^^^(Desktop ^^^& "\%%【Name】%%.lnk"^^^) ^& echo B.IconLocation = "%%【Path】%%" ^& echo B.TargetPath = "%%windir%%\System32\schtasks.exe" ^& echo B.Arguments = "/run /tn ""Apps\%%【Task_name】%%""" ^& echo B.Save ^& echo WScript.Quit^)^> "%%temp%%\Shortcut.vbs"
echo "%%temp%%\Shortcut.vbs"
echo.
echo If errorlevel 1 ^(Del "%%temp%%\Shortcut.vbs" ^& echo.
echo echo  ====================================================================================
echo echo      The script has failed to complete the operation.
echo echo      Please press any key to close this message.
echo echo  ====================================================================================
echo pause ^> nul ^& Exit^) else ^(Del "%%temp%%\Shortcut.vbs" ^& echo.
echo echo  ====================================================================================
echo echo      The shortcut "%%【Name】%%" has been created on the desktop.
echo echo      You may double-click on it to run the application.
echo echo      Please press any key to close this message.
echo echo  ====================================================================================
echo pause ^> nul ^& Exit^)
)> "%【Path】%"


For /f "tokens=*" %%I in ('WhoAmI /user') Do (for %%A in (%%~I) Do (set "【SID】=%%A"))
IF EXIST "%temp%\%【Name】%.xml" (DEL "%temp%\%【Name】%.xml")
IF EXIST "%temp%\Task.vbs" (DEL "%temp%\Task.vbs")

echo Set X=CreateObject("Scripting.FileSystemObject") >> "%temp%\Task.vbs"
echo Set Z=X.CreateTextFile("%temp%\%【Name】%.xml",True,True)>> "%temp%\Task.vbs"
Set "W=echo Z.writeline "
(
%W%"<?xml version=""1.0"" encoding=""UTF-16""?>"
%W%"<Task version=""1.4"" xmlns=""http://schemas.microsoft.com/windows/2004/02/mit/task"">"
%W%"<RegistrationInfo>"
%W%"<Author>Matthew Wai</Author>"
%W%"<Description>To run the application/CMD script as an administrator with no UAC prompt.</Description>"
%W%"</RegistrationInfo>"
%W%"<Triggers />"
%W%"<Principals>"
%W%"<Principal id=""Author"">"
%W%"<UserId>%【SID】%</UserId>"
%W%"<LogonType>InteractiveToken</LogonType>"
%W%"<RunLevel>HighestAvailable</RunLevel>"
%W%"</Principal>"
%W%"</Principals>"
%W%"<Settings>"
%W%"<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>"
%W%"<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>"
%W%"<StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>"
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
%W%"<Command>""%【Path】%""</Command>"
%W%"</Exec>"
%W%"</Actions>"
%W%"</Task>"
)>> "%temp%\Task.vbs"
echo Z.Close >> "%temp%\Task.vbs"
"%temp%\Task.vbs"
Del "%temp%\Task.vbs"
schtasks /create /xml "%temp%\%【Name】%.xml" /tn "Apps\%【Name】%"

If %errorlevel%==1 (DEL "%temp%\%【Name】%.xml" & echo.
echo     ====================================================================================
echo          The script has failed to create the task "%【Name】%".
echo          The task might already exist in "Task Scheduler Library"--^>"Apps".
echo          Press any key to close this message.
echo     ====================================================================================
pause > nul & Exit) else (DEL "%temp%\%【Name】%.xml"
echo     ====================================================================================
echo          The item "Elevated Shortcut" has been added into the context menu.
echo          The item will appear when you hover the cursor over the item "New".
echo          All the scheduled tasks will be in "Task Scheduler Library"--^>"Apps".
echo          You may edit/disable/delete the tasks if need be.
echo          Please press any key to close this message.
echo     ====================================================================================
pause > nul & Exit)
