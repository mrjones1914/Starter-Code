<# 2 - Add the FS groups to the folder ACL.
The possible values for Rights: 
 ListDirectory, ReadData, WriteData 
 CreateFiles, CreateDirectories, AppendData 
 ReadExtendedAttributes, WriteExtendedAttributes, Traverse
 ExecuteFile, DeleteSubdirectoriesAndFiles, ReadAttributes 
 WriteAttributes, Write, Delete 
 ReadPermissions, Read, ReadAndExecute 
 Modify (automatically adds 'Write'), ChangePermissions, TakeOwnership
 Synchronize, FullControl
#>


Get-Acl
Set-Acl
