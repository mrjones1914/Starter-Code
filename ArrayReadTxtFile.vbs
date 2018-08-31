' use an array to read a txt file

Option Explicit
On Error Resume Next

Dim objFSO
Dim objTextFile
Dim arrServiceList
Dim strNextLine
Dim i
Dim TxtFile
Const ForReading = 1
TxtFile = "C:\Scripts\ServersAndServices.txt"

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objTextFile = objFSO.OpenTextFile _
	(TxtFile, ForReading)
Do Until objTextFile.AtEndofStream
	boundary = UBound(arrServiceList)
	WScript.Echo "upper boundary = " & boundary
	strNextLine = objTextFile.Readline
	arrServiceList = Split(strNextLine , ",")
	WScript.Echo "Server name: " & arrServiceList(0)
	For i = 1 To UBound(arrServiceList)
		WScript.Echo "Service: " & arrServiceList(i)
	Next
Loop
WScript.Echo("all done")
