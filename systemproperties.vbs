' Description : This script will display the Computername, model #, Serial #, OS type, IP addresses in an Excel file
' Instructions : Create a text file named servers.txt with the server names 
' which u need to check for these details. Output will be an excel 
' file which will be saved in C: drive with file name as "Computer_Info.xls"


Const Reading = 1

Dim objExcel, objWorksheet, objWorkbook, objRange
Dim objNtpad, ofjfile

Set objExcel = CreateObject("Excel.Application")
objExcel.Visible = True
Set objWorkbook = objExcel.Workbooks.Add()
Set objWorksheet = objWorkbook.Worksheets(1)

Set objNtpad = CreateObject("Scripting.FileSystemObject")
Set objFile = objNtpad.OpenTextFile("C:\scripts\servers.txt", Reading)

On Error Resume Next
Set objexcel=CreateObject("Excel.application")
If(number <> 0) Then
On Error Goto 0
WScript.Echo "Excel application not found"
WScript.Quit
End If

objworksheet.cells(1,1) = "Servername"
objworksheet.cells(1,2) = "Server Model"
objworksheet.cells(1,3) = "Serial Number"
objworksheet.cells(1,4) = "OS Type"
objworksheet.cells(1,5) = "IP Address1"
objworksheet.cells(1,6) = "IP Address2"
objworksheet.cells(1,7) = "IP Address3"

objworksheet.range("A1:G1").font.size= 12
objworksheet.range("A1:G1").font.bold= True

x = 2
strDate= Replace(Date,"/","-")
strTime= Replace(Time,":","-")
strSavefile = "C:\Computer_Info_" & strDate & " " & strTime & ".xls"

flag = 0
Do
strComputer = objfile.ReadLine

Set objWMISvc = GetObject("winmgmts:" _
& "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")

Set colItems = objWMISvc.ExecQuery( "Select * from Win32_ComputerSystem", , 48 )

objworksheet.cells(x,1).value = strComputer

For Each objItem in colItems
objworksheet.cells(x,1).value = ObjItem.Name
objworksheet.cells(x,2).value = ObjItem.Model

Set colItemsCSP = objWMISvc.ExecQuery("SELECT * FROM Win32_ComputerSystemProduct") 
For Each objItemCSP in colItemsCSP 
objworksheet.cells(x,3).value = objItemCSP.IdentifyingNumber

Set colItemsOS = objWMISvc.ExecQuery( "Select * from Win32_OperatingSystem")
For Each objItemOS in colItemsOS
objworksheet.cells(x,4).value = objItemOS.Caption

j = 5
Set colItemsNAC = objWMISvc.ExecQuery( "Select * from Win32_NetworkAdapterConfiguration Where IPEnabled=TRUE")
For Each objItemNAC in colItemsNAC
If Not IsNull(objitemNAC.IPAddress) Then
For i=LBound(objitemNAC.IPAddress) to UBound(objitemNAC.IPAddress)
objWorksheet.cells(x,j).value = objitemNAC.IPAddress(i)

Next
End If
j = j + 1

Next
Next
Next
Next

x = x + 1

Loop Until objfile.AtEndOfStream = True

Set objrange = objWorksheet.Usedrange
objrange.entirecolumn.autofit()

objworkbook.SaveAs strSavefile
WScript.Echo "Excel file has been saved in C:\Computer_Info_" & strDate & " " & strTime & ".xls"

objExcel.ActiveWorkbook.close
objExcel.Application.Quit

Set objExcel = Nothing
Set objWorksheet = Nothing
Set flag = Nothing
Set objWMIsvc= Nothing
Set objrange = Nothing
Set objFile = Nothing
Set objNtpad = Nothing