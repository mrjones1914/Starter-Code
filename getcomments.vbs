' find all the comments & write them to a file

Option Explicit
On Error Resume Next

Const ForReading = 1
Const ForWriting = 2
Dim commentFile
Dim scriptFile
Dim objScriptFile
Dim ObjFSO
Dim objCurrentLine
Dim objCommentFile
Dim intIsComment

scriptFile = "C:\scripts\SCCM_Health_Check1.3.vbs"
commentFile = "C:\scripts\comments.txt"
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objScriptFile = objFSO.OpenTextFile _ 
	(scriptFile, ForReading)
Set objCommentFile = objFSO.OpenTextFile(commentFile, _
	ForWriting, True)
Do While objScriptFile.AtEndOfStream <> True
	strCurrentLine = objScriptFile.ReadLine
	inIsComment = InAtr(1,strCurrentLine, "'")
	if intIsComment > 0 Then
		objCommentFile.Write strCurrentLine & vbCrLf
	End If
Loop
WScript.Echo("script complete")
objScriptFile.Close
objCommentFile.Close
