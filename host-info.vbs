' This script displays host info by reading the registry

Option Explicit
On Error Resume Next

Dim objShell
Dim regLogonUserName, regExchangeDomain, regGPServer
Dim regLogonServer, regDNSdomain
Dim LogonIserName, ExchangeDomain, GPServer
Dim LogonServer, DNSdomain

' Find the correct values for W7/srv2008, 'cause these ain't right
regLogonUserName = "HKEY_CURRENT_USER\Software\Microsoft\" & _
	"Windows\CurrentVersion\Explorer\Logon User Name"
regExchangeDomain = "HKEY_CURRENT_USER\Software\Microsoft\" & _
	"Exchange\LogonDomain"
regGPServer = "HKEY_CURRENT_USER\Software\Microsoft\Windows\" & _
	"CurrentVersion\Group Policy\History\DCName"
regLogonServer = "HKEY_CURRENT_USER\Volatile Environment\" & _
	"LOGONSERVER"
regDNSdomain = "HKEY_CURRENT_USER\Volatile Environment\" & _
	"USERDNSDOMAIN"

Set objShell = CreateObject("WScript.Shell")
ActiveComputerName = objShell.RegRead(regActiveComputerName)
ComputerName = objShell.RegRead(regComputerName)
Hostname = objShell.RegRead(regHostname)

' To make dialog boxes you can use WScript.Echo and then tell it what you want it to say.

WScript.Echo activecomputername & " is active computer name"
WScript.Echo ComputerName & " is computer name"
WScript.Echo Hostname & " is host name"