option explicit
on error resume next
const DriveType = 4 '3 for fixed disk; 2 for removable; 4 for Network; 5 for CD
Dim colDrives
dim drive

set colDrives = _
GetObject("winmgmts:").ExecQuery _ 
	("select DeviceID from Win32_LogicalDisk where DriveType = " & DriveType)
	
For Each drive in colDrives
	WScript.Echo drive.DeviceID
Next
