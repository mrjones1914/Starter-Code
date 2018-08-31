' Ping

strMachines = "s004207;s004208"
aMachines = Split(strMachines, ";")

For Each machine In aMachines
	Set objPing = GetObject("winmgmts:")._
	ExecQuery("select * from Win32_PingStatus where address = '" _
		& machine & "'")
	For Each objStatus In objPing
		If IsNull(objStatus.StatusCode) Or objStatus.StatusCode<>0 Then
		WScript.Echo("machine " & machine & " is not reachable")
		Else
		WScript.Echo("reply from " & machine)
		End If
	Next
Next