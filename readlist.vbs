' readlist.vbs - read a text file 
' and spit out the list onscreen
' 
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile (".\2003.txt", ForReading)

Const ForReading = 1

Dim arrFileLines()
i=0

Do Until objFile.AtEndOfStream
Redim Preserve arrFileLines(i)
arrFileLines(i) = objFile.ReadLine
i=i+1

Loop
objFile.Close

For Each strLine in arrFileLines
WScript.Echo strLine
Next