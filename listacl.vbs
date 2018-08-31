'    ListACL.vbs
'    ACL Modifications by CyberneticWraith, 2005
'    Changed it to display ACL information for folders
'    Uses "cacls.exe"
'    Run with cscript!
'	example: "cscript listACL.vbs "C:\mj""
'
'    IndexScripts()
'
'

' First thing, check the argument list for a directory.
' If they didn't specify one, use the current directory.

option explicit

' Run the function :)
call IndexScripts


sub IndexScripts()

    dim fso
    set fso = createobject("scripting.filesystemobject")

    dim loc
    if WScript.Arguments.Count = 0 then
        loc = fso.GetAbsolutePathName(".")
    else
        loc = WScript.Arguments(0)
    end if

    GetWorkingFolder loc, 0, 1, "|"

    set fso = nothing
    
End Sub


' called recursively to get a folder to work in
function GetWorkingFolder(foldspec, foldcount, _
                                   firsttime, spacer)

    Dim objShell,oExec
    Set objShell = CreateObject("WScript.Shell")
    
    dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")

    dim fold
    set fold = fso.GetFolder(foldspec)
    
    dim foldcol
    set foldcol = fold.SubFolders
    
    'do the first folder stuff
    if firsttime = 1 then
        wscript.echo fold.path
        
        foldcount = foldcol.count
        firsttime = 0
    end if
    
    dim remaincount
    remaincount = foldcol.count
    
    'do the subfolder stuff
    dim sf
    for each sf in foldcol
                
        'execute cacls to display ACL information
        Set oExec = _
          objShell.Exec("cacls " & chr(34) & sf.path & chr(34))
        
        Do While Not oExec.StdOut.AtEndOfStream
             str = oExec.StdOut.ReadAll
             Dim str
             Wscript.StdOut.WriteLine str
        Loop
        
        set oExec = nothing
        
        remaincount = GetWorkingFolder (foldspec +"\"+sf.name, _
                                   remaincount, firsttime, spacer)
    
    next 
    
    'clean up
    set fso = nothing
    
    GetWorkingFolder = foldcount - 1

end function