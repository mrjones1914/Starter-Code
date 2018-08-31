' List a specific set of folders

strComputer = "."
set objWMIService = GetObject("winmgmts:" _
	& "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set colFoles = objWMIService.ExecQuery _
	("Select * from Win32_Directory where Hidden = True")
	
For Each objFile in colFiles
	WScript.Echo objFile.name
Next
