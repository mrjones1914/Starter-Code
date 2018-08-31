Option Explicit
' On Error Resume Next

Dim strComputer
Dim wmiRoot
Dim wmiQuery
Dim objWMIService
Dim colComputers
Dim objComputer
Dim strComputerRole
Dim colNetAdapters
Dim objNetAdapters
Dim DHCPEnabled

strComputer = "."
wmiRoot = "winmgmts:\\" & strComputer & "\root\cimv2"
wmiQuery = "Select * from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE"
Set objWMIService = GetObject(wmiRoot)
Set colNetAdapters = objWMIService.ExecQuery (wmiQuery)
For Each objNetAdapters In colNetAdapters
	DHCPEnabled = objNetAdapters.EnableDHCP()
		If DHCPEnabled = 0 Then
			WScript.Echo "DHCP has been enabled."
		Else
			WScript.Echo "DHCP could not be enabled."
		End If
Next