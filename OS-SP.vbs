' List Operating System and Service Pack Information

Const Reading = 1

Dim objExcel, objWorksheet, objWorkbook, objRange
Dim objNtpad, ofjfile
'Dim inSvr as String

Set objExcel = CreateObject("Excel.Application")
objExcel.Visible = True
Set objWorkbook = objExcel.Workbooks.Add()
Set objWorksheet = objWorkbook.Worksheets(1)

Set objNtpad = CreateObject("Scripting.FileSystemObject")
Set objFile = objNtpad.OpenTextFile("C:\scripts\servers.txt", Reading) ' You can mention the input file location

' Checking for Excel application
On Error Resume Next
Set objexcel=CreateObject("Excel.application")
If(number <> 0) Then
  On Error Goto 0
  WScript.Echo "Excel application not found"
  WScript.Quit
End If

objworksheet.cells(1,1) = "Servername"
objworksheet.cells(1,2) = "Operating System"
objworksheet.cells(1,3) = "Version: "
objworksheet.cells(1,4) = "Service Pack: "

objworksheet.range("A1:D1").font.size= 12
objworksheet.range("A1:D1").font.bold= True

x = 2

Do
strComputer = objfile.ReadLine

Set objWMIService = GetObject("winmgmts:" _
 & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
 
Set colOSes = objWMIService.ExecQuery("Select * from Win32_OperatingSystem")

objworksheet.cells(x,1).value = strComputer

For Each objOS in colOSes
  objworksheet.cells(x,1).value = objOS.CSName
  objworksheet.cells(x,2).value = objOS.Caption 'Name
  objworksheet.cells(x,3).value = objOS.Version 'Version & build
  objworksheet.cells(x,4).value = objOS.ServicePackMajorVersion & "." & _
   objOS.ServicePackMinorVersion
Next


 x = x + 1

Loop Until objfile.AtEndOfStream = True

Set objrange = objWorksheet.Usedrange
objrange.entirecolumn.autofit()

Set objexcel = Nothing
Set objworksheet = Nothing
Set flag = Nothing
Set objWMIservice= Nothing
Set objrange = Nothing
Set objFile = Nothing
Set objNtpad = Nothing
'Set inSvr = Nothing