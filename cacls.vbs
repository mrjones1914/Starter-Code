' This script will assign Modify/C-Change (write) Permission To Everyone on "C:\Temp" 
' using cacls on NTFS formatted drive

Dim oShell, FoldPerm, Calcds, oFSO

Set oFSO = CreateObject("Scripting.FileSystemObject")
Set oShell = CreateObject("WScript.Shell")

sSysDir = oFSO.GetSpecialFolder(1).Path
If Right(sSysDir,1) <> "\" Then sSysDir = sSysDir & "\"

Calcds = sSysDir & "cacls.exe" 

'Chang The folder Name, User and Access rights in the following line of code  

FoldPerm = """" & Calcds &"""" & """C:\Temp""" & " /E /T /C /G " & """Everyone""" & ":C" 

oShell.Run FoldPerm, 1 ,True

'Reply With Quote 