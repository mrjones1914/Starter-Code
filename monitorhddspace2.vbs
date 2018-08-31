Option Explicit
On Error Resume Next

Const FIVE_SEC = 5000
Const LOCAL_HARD_DISK = 3
Dim colMonitoredDisks
Dim objWMIService
Dim objDiskChange
Dim i

Set objWMIService = GetObject("winmgmts:" _
	& "{impersonationLevel=impersonate}").ExecQuery _
	("SELECT * FROM Win32_Process")

Set colMonitoredDisks = objWMIService.ExecNotificationQuery _
	("Select * from __instancemodificationevent within 30 where " _
	& "TargerInstance isa 'Win32_LogicalDisk'")
	
i=0
Do While i=0
	Set objDiskChange = colMonitoredDisks.NextEvent
	If objDiskChange.TargetInstance.DriveType = _
		LOCAL_HARD_DISK Then
		If objDiskChange.TargetInstance.Size < 100000000 Then
			WScript.Echo _
				"Hard disk space is below 100000000 bytes>"
			WScript.Sleep(FIVE_SEC)
		End If
	End If
Loop
