' Delete all Subfolders and Files in a Folder

Const DeleteReadonly=TRUE
Set objFSO = CreateObject("Scripting.FileSystemObject")
objFSO.DeleteFile("c:\dell\*"), DeleteReadonly
objFSO.DeleteFolder("c:\dell\*"),DeleteReadonly