' Read a list of servers from a file
' and services from a file or an array
' and restart the services on the server list
'=================================================
If LCase(Right(Wscript.FullName, 11)) = "wscript.exe" Then
    strPath = Wscript.ScriptFullName
    strCommand = "%comspec% /k cscript  """ & strPath & """"
    Set objShell = CreateObject("Wscript.Shell")
    objShell.Run(strCommand), 1, True
    Wscript.Quit
End If
 
Dim objFSO : Set objFSO = CreateObject("Scripting.FileSystemObject")
 
strInputFile = "servers.txt"
ServicesFile = "C:\ServiceList.txt"
strDateTime = Year(Now) & Right("0" & Month(Now), 2) & Right("0" & Day(Now), 2) & "_" & Right("0" & Hour(Now), 2) & Right("0" & Minute(Now), 2) & Right("0" & Second(Now), 2)
OutputFile = "C:\ServiceReport_" & strDateTime & ".txt"
 
arrServices = Array("Print Spooler","Windows Audio","VNC Server")
'To read services from a text file, comment the above and uncomment the next line
'arrServices = Split(objFSO.OpenTextFile(ServicesFile).ReadAll, vbNewLine)
 
Const intForReading = 1
Set objInputFile = objFSO.OpenTextFile(strInputFile, intForReading, False)
Set objOutputFile = objFSO.CreateTextFile (OutputFile)
 
While Not objInputFile.AtEndOfStream
      strServer1 = objInputFile.ReadLine
      objOutputFile.WriteLine "Checking " & strServer1 & "..."
      If Ping(strServer1) = True Then
            objOutputFile.WriteLine vbTab & "...responds to PING"
            objOutputFile.WriteLine vbTab & "...checking service(s)..."
            For Each strService In arrServices
            	On Error Resume Next
				Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" _
					& strServer1 & "\root\cimv2")
				Set colListOfServices = objWMIService.ExecQuery _
					("Select * from Win32_Service Where DisplayName='"& strService & "'")
				If Err.Number = 0 Then
					'On Error Resume Next
					For Each objService In colListOfServices
						If Err.Number = 0 Then
							On Error GoTo 0
							If objService.State = "Running" Then
								objOutputFile.WriteLine vbTab & vbTab & objService.Name & " is running."
							Else
								objOutputFile.WriteLine vbTab & vbTab & objService.Name & " is NOT running."
								objService.StopService()
								WScript.Echo ""
								WScript.Echo strService & " service stopped on " & strServer1
								WScript.Sleep 5000
								objService.StartService()
								If Err.Number <> 0 Then
									objOutputFile.WriteLine vbTab & vbTab & objService.Name & " could not be restarted"
								Else
									objOutputFile.WriteLine vbTab & vbTab & objService.Name & " is now running."
									WScript.Echo strService & " service started on " & strServer1
								End If
							End If
						Else
							Err.Clear
							On Error GoTo 0
							WScript.Echo strService & " service was not found on " & strServer1
						End If
					Next
				Else
					Err.Clear
					On Error GoTo 0
					WScript.Echo "WMI Connection error to " & strServer1
				End If
            Next
      Else
            objOutputFile.WriteLine strServer1 & " did not respond to PING"
            WScript.Echo ""
            WScript.Echo strServer1 & " could not be pinged."
      End If
      objOutputFile.WriteLine
Wend
objInputFile.Close
Set objInputFile = Nothing
 
WScript.Echo "" & VbCrLf & "Finished."
 
Function Ping(strComputer)
      Dim objShell, boolCode
      Set objShell = CreateObject("WScript.Shell")
      boolCode = objShell.Run("Ping -n 1 -w 300 " & strComputer, 0, True)
      If boolCode = 0 Then
            Ping = True
      Else
            Ping = False
      End If
End Function
'================================
