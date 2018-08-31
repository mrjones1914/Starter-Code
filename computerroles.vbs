Option Explicit
On Error Resume Next

Dim strComputer
Dim wmiRoot
Dim wmiQuery
Dim objWMIService
Dim colComputers
Dim objComputer
Dim strComputerRole

strComputer = "."
wmiRoot = "winmgmts:\\" & strComputer & "\root\cimv2"
wmiQuery = "Select DomainRole from Win32_ComputerSystem"
Set objWMIService = GetObject(wmiRoot)
Set colComputers = objWMIService.ExecQuery _
	(wmiQuery)
For Each objComputer In colComputers
	Select Case objComputer.DomainRole
		Case 0
			strComputerRole = "Standalone Workstation"
		Case 1
			strComputerRole = "Member Workstation"
		Case 2
			strComputerRole = "Standalone Server"
		Case 3
			strComputerRole = "Member Server"
		Case 4
			strComputerRole = "Backup Domain Controller"
		Case 5
			strComputerRole = "Primary Domain Controller"
	End Select
	WScript.Echo strComputerRole
Next