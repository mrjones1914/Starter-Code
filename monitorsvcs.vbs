'=================================
' Check to see if a service is running
'=================================

'Declare Variables
Dim objWMIService, objProcess, colProcess, Status, strComputer, strService
 
'Assign Arguments
strComputer = WScript.Arguments(0)
strService = WScript.Arguments(1) 
Status= false
 
'Check For Arguments - Quit If None Found
If Len(strService) < 1 Then
    Wscript.echo "No Arguments Entered - Exiting Script"
    WScript.Quit
End If
 
'Setup WMI Objects
Set objWMIService = GetObject("winmgmts:"& "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2") 
Set colProcess = objWMIService.ExecQuery ("SELECT DisplayName, Status, State FROM Win32_Service WHERE DisplayName = '" & strService & "'")
 
'Check For Running Service
For Each objProcess in colProcess
    If InStr(objProcess.DisplayName,strService) > 0 And objProcess.State = "Running" Then
	Status = true
    End If
Next
 
If Status = true Then
    Wscript.echo "Service: " & UCase(strComputer) & " " & strService & " Running"
    'Perform Some Pass Logic Here
Else
    Wscript.echo "Service: " & UCase(strComputer) & " " & strService & " Not Running"
    'Perform Some Failed Logic Here
End If