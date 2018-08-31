Option Explicit
On Error Resume Next
Const ONE_HOUR = 3600000
Dim objWMIService
Dim objProcess
Dim i

Set objWMIService = GetObject("winmgmts:") _
	& .ExecQuery _
	("SELECT * FROM Win32_Process")
	
For i = 1 To 8
	For Each objProcess In objWMIService
		WScript.Echo Now
		WScript.Echo ""
		WScript.Echo "Process: " & objProcess.Name
		WScript.Echo "Process ID: " & objProcess.ProcessID
		WScript.Echo "Thread Count: " & objProcess.ThreadCount
		WScript.Echo "Page File Size: " & objProcess.PageFileUsage
		WScript.Echo "Page Faults: " & objProcess.PageFaults
		WScript.Echo "Working Set Size: " & objProcess.WorkingSetSize
	Next
	WScript.Echo "******PASS COMPLETE**********"
	WScript.Sleep ONE_HOUR
Next