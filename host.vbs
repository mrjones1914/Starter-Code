' This script displays various Computer Names by reading the registry

Option Explicit
On Error Resume Next

Dim objShell
Dim regActiveComputerName, regComputerName, regHostname
Dim ActiveComputerName, ComputerName, Hostname


regActiveComputerName = "HKLM\SYSTEM\CurrentControlSet" & _
	"\Control\ComputerName\ActiveComputerName\ComputerName"
regComputerName = "HKLM\SYSTEM\CurrentControlSet\Control" & _
	"\ComputerName\ComputerName\ComputerName"
regHostname = "HKLM\SYSTEM\CurrentControlSet\Services" & _
	"\Tcpip\Parameters\Hostname"

Set objShell = CreateObject("WScript.Shell")
ActiveComputerName = objShell.RegRead(regActiveComputerName)
ComputerName = objShell.RegRead(regComputerName)
Hostname = objShell.RegRead(regHostname)

' To make dialog boxes you can use WScript.Echo and then tell it what you want it to say.

WScript.Echo activecomputername & " is active computer name"
WScript.Echo ComputerName & " is computer name"
WScript.Echo Hostname & " is host name"