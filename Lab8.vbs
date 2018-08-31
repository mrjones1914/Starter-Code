'==========================================================================
'
' VBScript Source File -- Created with SAPIEN Technologies PrimalSCRIPT(TM)
'
' NAME: <Lab8Solution.vbs>
'
' AUTHOR: ed wilson , mred
' DATE  : 6/15/2003
'
' COMMENT: <The following concepts are presented>
'1. assigning wmi connection To wmiRoot
'2. assigning wmi query To wmiQuery variable
'3. For Each
'4. ReDim
'5. Use of Array FILTER command**
'6. Working with UBOUND and using for outputting info
'7. Line concatenation
'==========================================================================
Option Explicit
'On Error Resume Next
Dim computer ' means this computer
Dim wmiRoot ' holds connection To wmi namespace
Dim objWMIService ' holds connection for wmi
Dim wmiQuery ' the SQL like query issued To wmi
Dim colServices ' the result of our query as collection
Dim objService ' each individual result
Dim array1()
Dim array2
Dim a ' counter used for array2 population
Dim b ' counter used for array2 enumeration
Dim i ' counter used for array1
Dim numServices ' used To add 1 To for zero based UBOUND command
Dim numProcesses ' same thing

a=0
i=0



computer = "."
wmiRoot = "winmgmts:\\" & Computer & "\root\cimv2"
Set objWMIService = GetObject(wmiRoot)
wmiQuery = "Select * from Win32_Service Where State <> 'Stopped'"
Set colServices = objWMIService.ExecQuery _
      (wmiQuery)
For Each objService In colServices
	ReDim Preserve array1(i)
	array1(i) = objService.ProcessID
	i = i+1
Next
For Each objService In colServices
	array2 = Filter(array1,objService.processID, true)
	a = a+1
Next

For b = 0 To UBound(array2)
	wmiQuery = "Select * from Win32_Service Where ProcessID = '" & _
        array2(b) & "'"
Set colServices = objWMIService.ExecQuery _
        (wmiQuery)
         WScript.Echo "Process ID: " & array2(b)
     For Each objService In colServices
    WScript.Echo VbTab & objService.DisplayName
    Next
Next

numServices = UBound(array1) + 1 ' due To being zero based
numProcesses = UBound(array2) + 1 ' same reason
WScript.Echo("there are " & numServices & " Services" & _
        " running inside " & numProcesses & " Processes")

