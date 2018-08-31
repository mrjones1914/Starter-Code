On Error Resume Next
WScript.Echo "WSH Version: " & WScript.Version
Wscript.Echo "VBScript Version: " & ScriptEngineMajorVersion _
    & "." & ScriptEngineMinorVersion
strComputer = "."
Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" & strComputer _
        & "\root\cimv2")
Set colWMISettings = objWMIService.ExecQuery _
    ("Select * from Win32_WMISetting")
For Each objWMISetting in colWMISettings
    Wscript.Echo "WMI Version: " & objWMISetting.BuildVersion
Next
Set objShell = CreateObject("WScript.Shell")
strAdsiVersion = objShell.RegRead _
("HKLM\SOFTWARE\Microsoft\" &_
"Active Setup\Installed Components\" &_
"{E92B03AB-B707-11d2-9CBD-0000F87A369E}\Version")
If strAdsiVersion = vbEmpty Then
    strAdsiVersion = objShell.RegRead _
    ("HKLM\SOFTWARE\Microsoft\ADs\Providers\LDAP\")
    If strAdsiVersion = vbEmpty Then
        strAdsiVersion = "ADSI is not installed."
    Else
        strAdsiVersion = "2.0"
    End If
End If
WScript.Echo "ADSI Version: " & strAdsiVersion