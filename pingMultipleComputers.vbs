' Ping multiple machines _
' via list given as a cmdline argument _
' separated by a semicolon (s1;s2)

If WScript.Arguments.Count = 0 Then
	WScript.Echo("You must enter a computer to ping")
Else
	strMachines = WScript.Arguments.Item(0) 'arguments are zero-based
	'If Multiple arguments are needed do: strMachines = WScript.Arguments.Item(1)
	aMachines = Split(strMachines, ";")

	For Each machine In aMachines
		Set objPing = GetObject("winmgmts:")._
		ExecQuery("select * from Win32_PingStatus where address = '" _
			& machine & "'")
		For Each objStatus In objPing
			If IsNull(objStatus.StatusCode) Or objStatus.StatusCode <> 0 Then
				WScript.Echo("machine " & machine & " is not reachable")
			Else
				WScript.Echo("reply from " & machine)
			End If
		Next
	Next
End If
