' argComputerService.vbs

Option Explicit
' On Error Resume Next
Dim computerName
Dim serviceName
Dim wmiRoot
Dim wmiQuery
Dim objWMIService
Dim colServices
Dim oservice
Dim colNamedArguments

Set colNamedArguments = WScript.Arguments.Named
computerName = colNamedArguments("computer")
serviceName = colNamedArguments("service")
wmiRoot = "winmgmts:\\" & computerName & "\root\cimv2"
Set objWMIService = GetObject(wmiRoot)
wmiQuery = "Select * from Win32_Service" &_
	" where name = " & "'" & ServiceName & "'"
Set colServices = objWMIService.ExecQuery _
	(wmiQuery)
For Each oservice In colServices
	WScript.Echo (serviceName) & " Is: "&_
	oservice.Status & (" on: ") & computerName
Next

