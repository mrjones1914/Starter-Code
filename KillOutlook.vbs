' KillOutlook.vbs
' Sample VBScript kill process
' This script will prompt for a computer name on which to kill an instance of "Outlook.exe"
' and then tell you when it's finished
'this one works, too
' ------------------------ ----------------------------------------------------------------'
Option Explicit
Dim objWMIService, objProcess, colProcess
Dim strComputer, strProcessKill, strInput
strProcessKill = "'Outlook.exe'"

' Input Box to get name of machine to run the process
Do
    strComputer = (InputBox(" ComputerName to Run Script",_
    "Computer Name"))
    If strComputer <> "" Then
    strInput = True
    End if
Loop until strInput = True


Set objWMIService = GetObject("winmgmts:" _
& "{impersonationLevel=impersonate}!\\" _
& strComputer & "\root\cimv2")

Set colProcess = objWMIService.ExecQuery _
("Select * from Win32_Process Where Name = " & strProcessKill )
For Each objProcess in colProcess
    objProcess.Terminate()
Next
WSCript.Echo "Just killed process " & strProcessKill _
& " on " & strComputer
WScript.Quit

 