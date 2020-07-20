Set WshShell = CreateObject("WScript.Shell")
strComputer = "."
Set objWMIService = GetObject _
    ("winmgmts:\\" & strComputer & "\root\cimv2")

Set colOperatingSystems = objWMIService.ExecQuery _
    ("Select * from Win32_OperatingSystem")
For Each objOperatingSystem in colOperatingSystems
	strBasekey = "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify\"
	If instr(objOperatingSystem.Caption,"XP") Then	
		strBasekey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TrayNotify\"
    end if
Next

'Clear the Customize Notifications dialog
On Error resume next
WshShell.Regdelete strBasekey & "IconStreams"
WshShell.Regdelete strBasekey & "PastIconsStream"
On Error goto 0

'Get curr. user name
Set colItems = objWMIService.ExecQuery("Select * From Win32_ComputerSystem")
For Each objItem in colItems
	strCurrentUserName = objItem.UserName
Next

'Restart user shell
Set colProcessList = objWMIService.ExecQuery _
    ("Select * from Win32_Process Where Name = 'Explorer.exe'")
For Each objProcess in colProcessList
	colProperties = objProcess.GetOwner(strNameOfUser,strUserDomain)
	If strUserDomain & "\" & strNameOfUser = strCurrentUserName then
		objProcess.Terminate()
	end if
Next
strWelcome = "Taskbar notification preferences have been cleared!"
Msgbox "Completed!" & Chr(10) & Chr(10) & strWelcome & Chr(10),64, "Done"