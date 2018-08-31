' reads crash recovery information from the registry

Option Explicit
On Error Resume Next

Dim objShell
Dim regAutoReboot, regMiniDumpdir, regHostname, regLogEvent, regDumpFile
Dim AutoReboot, MiniDumpdir, Hostname, LogEvent, DumpFile
Dim fso

' strLogFile = ".\CrashRecovery.log"

regAutoReboot = "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\AutoReboot"
regMiniDumpdir = "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\MinidumpDir"
regHostname = "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Hostname"
regLogEvent = "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\LogEvent"
regDumpFile = "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl\DumpFile"

Set objShell = CreateObject("WScript.Shell")
AutoReboot = objShell.RegRead(regAutoReboot)
MiniDumpdir = objShell.RegRead(regMiniDumpdir)
Hostname = objShell.RegRead(regHostname)
LogEvent = objShell.RegRead(regLogEvent)
DupmFile = objShell.RegRead(DumpFile)

' pipe output into a log file
' Wscript.Echo AutoReboot, MiniDumpdir, Hostname, LogEvent, DumpFile & >> strLogFile
Set fso = WSript.CreateObject("Scripting.Filesystemobject")
Set f = fso.OpenTextFile(".\CrashRecovery.log", 2)
f.WriteLine AutoReboot, MiniDumpdir, Hostname, LogEvent, DumpFile

f.close
WScript.Quit

