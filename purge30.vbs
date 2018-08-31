on error resume next

Const MaxAge = 2 'days ' Enter number of days to keep files
Const Recursive = True ' Only does path provided in Parameter1 if FALSE, includes sub directories if TRUE

' Below are defaults for the variables used

Active = True ' Set this to False to test - Active will delete files
Checked = 0 
FoldersChecked = 0
Deleted = 0
FoldersDeleted = 0

' This will capture the command line parameters - uses safe setting if parameter1 is omitted.

set ArgObj = wScript.Arguments
var1 = ArgObj(0)
if len(var1) = 0 then 
Active = TRUE
sSource = "E:"
else
sSource = var1
end if


' Start of main script - calls CheckFolder (for files) and CheckFolders (for directories)

Set oFSO = CreateObject("Scripting.FileSystemObject")
if active then verb = "Deleting """ Else verb = "Old file: """
CheckFolder oFSO.GetFolder(sSource)
CheckFolders oFSO.GetFolder(sSource)

WScript.echo
if Active then verb = " file(s) deleted" Else verb = " file(s) would be deleted"
WScript.Echo Checked & " file(s) checked, " & Deleted & verb
if Active then verb = " folder(s) deleted" Else verb = " folder(s) would be deleted"
wscript.echo FoldersChecked & " folder(s) checked, " & FoldersDeleted & verb


' This sub checks files in each folder, recursively if selected

Sub CheckFolder (oFldr)
For Each oFile In oFldr.Files
Checked = Checked + 1
If DateDiff("D", oFile.DateLastModified, Now()) > MaxAge Then 
Deleted = Deleted + 1
WScript.Echo verb & oFile.Path & """"
If Active Then oFile.Delete
End If
Next
if not Recursive then Exit Sub
For Each oSubfolder In oFldr.Subfolders
CheckFolder(oSubfolder)
Next
End Sub


'This sub checks directories (to delete), recursively if selected

Sub CheckFolders (oFolder)
for each oFldr in oFolder.SubFolders
if oFldr.SubFolders.count <> 0 and recursive then CheckFolders(oFldr)
FoldersChecked = FoldersChecked + 1
If oFldr.SubFolders.count = 0 and oFldr.Files.count = 0 then 
FoldersDeleted = FoldersDeleted + 1
If Active Then 
wscript.echo ("Folder """ & oFldr & """ is empty and will be deleted.")
oFldr.Delete
else
wscript.echo ("Folder """ & oFldr & """ is empty and should be deleted.")
end if
end if
Next
End Sub