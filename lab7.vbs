'
Option Explicit
Dim objWMIService
Dim colServices
Dim objService
Dim objIdDictionary
Dim colProcessIDs
Dim i
Dim strComputer
Dim wmiRoot
Dim wmiQuery
Dim colComputers
Dim computer

If WScript.Arguments.UnNamed.Count = 0 Then
	WScript.Echo("You must enter a computer name.")
Else

Set objIdDictionary = CreateObject("Scripting.Dictionary")
strComputer = WScript.Arguments(0)
colComputers = Split(strComputer, ",")

For Each computer In colComputers
	wmiRoot = "winmgmts:\\" & Computer & "\root\cimv2"
	Set objWMIService = GetObject(wmiRoot)
	wmiQuery = "Select * from Win32_Service Where State <> 'Stopped'"
	Set colServices = objWMIService.ExecQuery _
		(wmiQuery)
		For Each objService In colServices
			If objIdDictionary.Exists(objService.ProcessID) Then
		Else
        objIdDictionary.Add objService.ProcessID, objService.ProcessID
		End If
	Next
colProcessIDs = objIdDictionary.Items
	For i = 0 To objIdDictionary.Count - 1
	wmiQuery = "Select * from Win32_Service Where ProcessID = '" & _
				colProcessIDs(i) & "'"
		Set colServices = objWMIService.ExecQuery _
			(wmiQuery)
		WScript.Echo "Process ID: " & colProcessIDs(i)
		For Each objService In colServices
			WScript.Echo VbTab & objService.DisplayName
		Next
    Next
Next
WScript.Echo "Finished!"
End If

'Next:
' try to figure out how to separate the results by computer name using something like:
' WScript.Echo "Running against remote computer: " & strComputer