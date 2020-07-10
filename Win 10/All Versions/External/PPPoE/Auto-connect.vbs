Set X=CreateObject("WScript.Shell") : Do : Return=X.Run _
("Rasdial ""Connection name"" ""User name"" ""Password""",0,True)

'This script will make 5 attempts to start the connection.
If Return = 0 then WScript.Quit
Attempts = Attempts + 1 : Loop until Attempts = 4

'If all attempts have failed, a message will pop up.
Path = split(wscript.scriptFullName, wscript.scriptname)(0)
Item = Path & "Pop-up.ps1"
X.run ("powershell -executionpolicy bypass -file " & """" & Item & """"),0,true
WScript.Quit
