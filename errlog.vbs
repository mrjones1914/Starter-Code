Option Explicit
On Error Resume Next

Dim error1String
Dim objFSO
Dim objFile
Dim strLine
Dim SearchResult

error1String = "error"

Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile("C:\windows\setuplog.txt", 1)
strLine = objFile.ReadLine

Do Until objFile.AtEndofStream
	strLine = objFile.ReadLine
	SearchResult = InStr(strLine, error1String)
	If SearchResult <> 0 Then
		WScript.Echo(strLine)
	End if
Loop
WScript.Echo("all done")
objFile.Close
