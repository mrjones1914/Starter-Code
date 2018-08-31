' This script shows some stuff about the currently logged in user
' and domain by reading the registry

Option Explicit
On Error Resume Next
Dim objShell

Dim regLogonUserName, regMachineDomain, regGPServer
Dim regLogonServer, regDNSdomain
Dim LogonUserName, MachineDomain, GPServer
Dim LogonServer, DNSdomain

regLogonUserName = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\" & _
	"Windows\CurrentVersion\Authentication\LogonUI\LastLoggedOnUser"
	
regMachineDomain = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\" & _
	"Windows\CurrentVersion\Group Policy\History\MachineDomain"
regGPServer = "HKEY_CURRENT_USER\Software\Microsoft\Windows\" & _
	"CurrentVersion\Group Policy\History\DCName"
regLogonServer = "HKEY_CURRENT_USER\Volatile Environment\" & _
	"LOGONSERVER"
regDNSdomain = "HKEY_CURRENT_USER\Volatile Environment\" & _
	"USERDNSDOMAIN"

Set objShell = CreateObject("WScript.Shell")
LogonUserName = objShell.RegRead(regLogonUserName)
MachineDomain= objShell.RegRead(regMachineDomain)
GPServer = objShell.RegRead(regGPServer)
LogonServer = objShell.RegRead(regLogonServer)
DNSdomain = objShell.RegRead(regDNSdomain)

' To make dialog boxes you can use WScript.Echo and then tell it what you want it to say.

WScript.Echo LogonUserName & " is currently Logged on"
WScript.Echo MachineDomain & " is the current logon domain"
WScript.Echo GPServer & " is the current Group Policy Server"
WScript.Echo LogonServer & " is the current logon server"
WScript.Echo DNSdomain & " is the current DNS domain"
