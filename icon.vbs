'Copy Icon file to System32
Const OverwriteExisting = TRUE

Set objFSO = CreateObject("Scripting.FileSystemObject")
objFSO.CopyFile "\\S004204\Source$\PhoneList\Regi_Shortcut.ico" , "C:\Windows\", OverwriteExisting
