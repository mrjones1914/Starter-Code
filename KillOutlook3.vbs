' This script will kill an instance of "Outlook.exe" on the local computer...
' this one works
'-----------------------------------------------------------------------------'

  Const strComputer = "." 
  Dim objWMIService, colProcessList
  Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
  Set colProcessList = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'Outlook.exe'")
  For Each objProcess in colProcessList 
    objProcess.Terminate() 
  Next 