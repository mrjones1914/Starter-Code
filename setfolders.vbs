Dim strPackage, strPath
Dim fso, intPos, intLen
strPackage = InputBox("Please enter the package vendor name")
strPath = ".\" & strPackage & "\1-LegacyInstallation"
'strPath = ".\" & strPackage & "\2-RepackagerandSource"
'strPath = ".\" & strPackage & "\3-ProjectFiles"
'strPath = ".\" & strPackage & "\4-MSI"
'strPath = ".\" & strPackage & "\5-Documentation"
intLen = Len(strPath)
Set fso = CreateObject("Scripting.FileSystemObject")
If Left(strPath, 2) = "\\" Then
' UNC path - skip server and share
intPos = InStr(5, strPath, "\")
intPos = InStr(intPos + 1, strPath, "\")
Else
' drive letter - skip C:\ part
intPos = 5
End If
Do
intPos = InStr(intPos + 1, strPath, "\")
If intPos = 0 Then
intPos = intLen + 1
End If
If fso.FolderExists(Left(strPath, intPos - 1)) = False Then
fso.CreateFolder Left(strPath, intPos - 1)
End If
Loop Until intPos = intLen + 1
Set fso = Nothing