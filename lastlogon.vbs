Const HKEY_LOCAL_MACHINE = &H80000002

strComputer = "D005727"
 
Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
 
strKeyPath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI"
strValueName = "LastLoggedOnUser"

objRegistry.GetStringValue HKEY_LOCAL_MACHINE, strKeyPath, strValueName, strValue

Wscript.Echo strValue