Dim objDC
Dim strComputer, strDomain

strDomain = "<redgold.com>"

Set fso = CreateObject("Scripting.FileSystemObject")
Set f1 = fso.OpenTextFile("c:\mj\pclist.txt")
Set objDC = getobject("WinNT://" & strDomain )
On Error Resume Next
Do until f1.atEndOfStream
On Error Resume Next
strComputer = f1.readline
objDC.Delete "Computer", strComputer
If Err.Number <0 Then
Err.Clear
Wscript.Echo "NOT FOUND: " & strComputer
Else
On Error GoTo 0
Wscript.Echo "Deleted: " & strComputer
End If
On Error GoTo 0
Loop
