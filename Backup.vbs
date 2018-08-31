'==========================================================================
'Tom's Cool Backup Script   revised 19 April 2002
'Written by Tom Hingston of http://cheqsoft.com
'
'This script copies all the files that are new or have changed, 
'to the backup folder specified by BackupPath.   
'It also logs the files copied from the last 5 backups to C:\Backuplog.txt
'
'INSTRUCTIONS
'You need to change settings in 2 places below...    Setting 1 is where to 
'backup to;  Setting 2 is what to backup.   There is optional Setting 3 which
'allows you to exclude some sub-folders from within the folders being backed up.
'
'All file/folder paths need to be inside speech marks   "Like this"  
'or otherwise the speech marks need to be empty    ""
'
'  Learn about VBScript at...
'  http://msdn.microsoft.com/scripting/default.htm?/scripting/vbscript/
'==========================================================================


'==========================================================================
'SETTING 1 -  WHERE TO BACKUP TO... 
' Set BackupPath 
'   BackupPath is the Folder that you want to backup to.... 
'   Example1: BackupPath = "H:\Backup"
'   Example2: BackupPath = "\\Tom\C\Quality Documents"

BackupPath = "H:\Backup"        '  <-- Set backup path here

'END OF SETTING 1  
'==========================================================================


If Wscript.Arguments.Count = 0 Then  'not initiated by dropping folder on it


'==========================================================================
'SETTING 2 - FILES AND/OR FOLDERS TO BACKUP...
'
'These are the Files and/or Folders that you want to backup.

Quantity = 10         '<-- This can be increased if MyData(?) increases.
redim MyData(Quantity)

'  These are the Folders that you want to backup... 
'  EXAMPLE:  MyData(1) = "C:\Data"

MyData(1) = "C:\mj\ebooks"      ' <-- Set these
MyData(2) = "C:\Packages"
MyData(3) = ""
MyData(4) = ""
MyData(5) = ""
MyData(6) = ""
MyData(7) = ""
MyData(8) = ""
MyData(9) = ""
MyData(10) = ""

'END OF SETTING 2
'==========================================================================


Else
  redim MyData(1)
  MyData(1) = Wscript.Arguments(0) 'was initiated by dropping folder on it
  Quantity = 1
End If


'==========================================================================
'SETTING 3 - FOLDERS TO EXCLUDE...   (optional)
'
'These are Sub-Folders within the folders being backed up, 
'that you can Exclude from the backup.
'EXAMPLE:    Excl_Data(1) = "C:\Data\Kids files"  

Excl_Quantity = 5      '<-- This can be increased if Excl_Data(?) increases.
redim Excl_Data(Excl_Quantity)

Excl_Data(1) = ""    '<-- Set these if required
Excl_Data(2) = ""
Excl_Data(3) = ""
Excl_Data(4) = ""
Excl_Data(5) = ""

'END OF SETTING 3
'==========================================================================


set fso = CreateObject("Scripting.FileSystemObject")


strScript = WScript.ScriptFullName
strScript = fso.GetFileName( strScript )
strScript = left( strScript, len(strScript) - 4 )

StartMe = msgbox("Welcome to Mike's Cool Backup script." & vbcrlf & vbcrlf & _
   "Backing up to " & BackupPath & " (" & strScript & ")" & vbcrlf & vbcrlf & _
   "Would you like to start your backup now ?" , 33, "Mike's Cool Backup Script " & " - " & strScript )
if StartMe = 2 then  'cancelled
  wscript.quit
End if


count = 0
MyDelay = 1  '(mS) that cause script delays to allow system to still be used (doevents)
dim arrResults   ' array to store results in
redim arrResults(0)


If right(BackupPath, 1) <> "\" then
  BackupPath =   BackupPath & "\"  'inserts the slash as it is required later
End If

call CheckPath

if not fso.folderExists ( BackupPath ) then
  fso.CreateFolder( BackupPath )
end if


'sets drv for MakeFolderPath
If left(BackupPath , 1) = "\" then 'network
  for ss = 1 to len(BackupPath )
    strCh = mid(BackupPath , ss, 1)
    if strCh = "\" then countslash = countslash + 1
    if countslash = 3 then 
      drv = ss + 3 
    end if
  next 'ss
  if not countslash >= 3 then msgbox "Error in script relative to network path"
else  'local drive letter
  drv = 5
End If

For i = 1 to Quantity 
  If MyData(i) <> "" then

    if fso.DriveExists( MyData(i) ) Then      'it is a drive
      call backup( MyData(i) )

    elseif fso.folderExists(MyData(i)) then   'it is a folder
      call MakeFolderPath( BackupPath & right(MyData(i), len(MyData(i))-3 ) )
      call backup( MyData(i) )

    elseif fso.fileExists(MyData(i)) then     'it is a file
      call FileBackup( MyData(i) )

    else                                      'not a drive or folder or file
      msgbox MyData(i) & vbcrlf & vbcrlf & "This file/folder does not appear to exist" & _
                 vbcrlf & "Please ensure you have typed it correctly or that" & vbcrlf & _
                 "you have not moved, renamed or deleted it.", 48, "File or Folder Error"
    end if

  End If
Next  'i

strlog = "----------------------" & vbnewline & "Backup on " & now() & vbnewline
strlog = strlog & join(arrResults, vbnewline) & vbnewline & "= " & count & " files copied to " & BackupPath & vbnewline & vbnewline
call logresults ( strlog )

ViewLog = msgbox("Backup Completed..." & vbnewline & "There were " & count & " files copied" &_
    vbnewline & "Would you like to view the backup log now ?", vbyesno + 32 + 256, "Mike's Cool Backup Script")
if ViewLog = 6 then  'yes
  Set WshShell = WScript.CreateObject( "WScript.Shell" )
  WshShell.Run ("""C:\Backuplog.txt""")  'open log file
end if

Set WshShell = nothing
set fso = nothing
wscript.quit

'-------------------------------------------------------
'Performes the actual copying if required
Sub Backup( mypath )

 if ExcludeF( mypath ) = False then
  Set fldr = fso.GetFolder( myPath )
  'Set fc = fldr.Files
  For Each f in fldr.Files
    DoEvents
    If not fso.folderExists( BackupPath  & right(myPath, len(myPath)-3 )) then
       call MakeFolderPath( BackupPath & right(myPath, len(myPath)-3 ))
    End if 
   If fso.DriveExists( mypath ) Then 'it is a drive
      backfolder = BackupPath 
   else 'it is a folder
      backfolder =  BackupPath & right(fldr, len(fldr)-3 ) & "\"
   end if


  ext = right(Lcase(f.name), 3)            '----------------------------
                                            ' FILE TYPES NOT TO BACK UP
                                            '----------------------------
   if ext <> "tmp" then  

     backupfile = backfolder & f.name

     If fso.fileExists( backupfile ) then
       if fso.GetFile(f).DateLastModified > fso.GetFile(backupfile).DateLastModified then
         fso.CopyFile f, backfolder, true
         count = count + 1
         ReDim Preserve arrResults(count)
         arrResults(count) = f
       end if
     Else  'does not yet exist in backup
       fso.CopyFile f, backfolder, true
       count = count + 1
       ReDim Preserve arrResults(count)
       arrResults(count) = f
     End if
   end if ' if ext.. that checked for filetype
  DoEvents

  Next  'f1

  For Each Folder In fldr.SubFolders
    Call Backup(Folder)
  Next 'Folder

 End if 'ExcludeF( mypath ) = False
End Sub

'-----------------------------------------------------------------
'performs the actual copying of Files if the path was a file - not folder
Sub FileBackup( myFile )

  set f = fso.GetFile( myFile )
  backupfile = BackupPath & f.name

  If fso.fileExists( backupfile ) then   'already exists in backup
       if fso.GetFile(f).DateLastModified > fso.GetFile(backupfile).DateLastModified then
         fso.CopyFile f, BackupPath , true
         count = count + 1
         ReDim Preserve arrResults(count)
         arrResults(count) = f
       end if
  Else         'does not yet exist in backup
       fso.CopyFile f, BackupPath , true
       count = count + 1
       ReDim Preserve arrResults(count)
       arrResults(count) = f
  End if    'fso.fileExists( backupfile ) then

End Sub

'------------------------------------------------------------------
'if the folder does not yet exist in the backup path, make it.
Sub MakeFolderPath( myfolder ) 
 For x = drv to len( myFolder )
  MyChr = mid( myFolder , x, 1)
  if mychr = "\" then
    xfolder = left(myfolder, x-1)
    if not fso.folderExists ( xFolder ) then
      fso.CreateFolder( xFolder )
    end if
  end if
 Next  'x
 if not fso.folderExists ( myFolder ) then
  fso.CreateFolder( myFolder )
 end if
End sub

'----------------------------------------------------------------
'function that writes results to the log.txt
Sub LogResults( myText )
  myfile = "C:\Backuplog.txt"

  Set fso = CreateObject("Scripting.FileSystemObject")
  OutFile = "C:\#temp#.txt"
  set textstream = fso.OpenTextFile(myFile,1,true)
  Set OutStream=fso.CreateTextFile(OutFile,True)

  OutStream.WriteLine( mytext )

  Do until textstream.AtEndOfStream  'writes existing text to temp file
   OneLine = textstream.ReadLine
   OutStream.WriteLine(oneline)
   if instr(Oneline, "----------") then 'finds start of each backup log
    logcount = logcount + 1
     if logcount >= 5 then
      exit do
     end if
   end if
  Loop

  textstream.close
  OutStream.Close
  fso.CopyFile OutFile, myfile, true
  fso.DeleteFile OutFile
End Sub

'----------------------------------------------------------------

Function ExcludeF(qF)
'On error resume next
  for q = 1 to Excl_Quantity
    if right(Excl_Data(q), 1) = "\" then 
      Excl_Data(q) = left(Excl_Data(q), len(Excl_Data(q))-1) 'removes last \
    end if

    If lcase(qF) = lcase(Excl_Data(q)) then
      ExcludeF = True
      Exit Function
    End if
  Next 'q

  ExcludeF = False
End Function

'----------------------------------------------------------------

Function Excludefolder(qFolder)
'On error resume next
  for q = 1 to Excl_Quantity
    if right(Excl_Data(q), 1) = "\" then 
      Excl_Data(q) = left(Excl_Data(q), len(Excl_Data(q))-1) 'removes last \
    end if

    If lcase(qFolder) = lcase(Excl_Data(q)) then
      Excludefolder = True
      Exit Function
    End if
  Next 'q

  Excludefolder = False
End Function

'-------------------------------------------------------------------

Sub DoEvents
  'To cause script delays to allow system to still be used (doevents)
  On error resume next
  wscript.sleep 1  'milliseconds
End Sub
'-------------------------------------------------------------------

Sub CheckPath
  'To ensure the backup path is not inside a folder being backed up

  for p = 1 to Quantity
   if not MyData(p) = "" then
    if lcase(left(BackupPath , len(MyData(p)))) = lcase(MyData(p)) then
      msgbox "You cannot back up a folder to a folder inside it" & vbcrlf &_
      "because it will also backup the backup etc." & vbcrlf & vbcrlf &_
      "Please use a different BackupPath." & vbcrlf & vbcrlf &_
      "This backup has been cancelled.", 64, "Error in BackupPath "
      wscript.quit
    end if  'left(BackupPath , len(MyData(p))) = MyData(p)
   end if ' not MyData(p) = ""
  next 'p

End Sub

'-------------------------------------------------------------------
'DISCLAIMER
'The Software Product is provided "as is"; I make no warranty, 
'whether express or implied, of the merchantability of 
'the Software Product or its fitness for any particular purpose.

'In no circumstances will I be liable for any damage, 
'loss of profits, loss of data, goodwill or for any indirect or 
'consequential loss arising out of your use of the Software Product, 
'or inability to use the Software Product, even if I 
'have been advised of the possibility of such loss.

'Use of our software implies your acceptance of this disclaimer.
'-------------------------------------------------------------------




