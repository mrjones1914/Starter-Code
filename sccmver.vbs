'-----------------------------------------------------------------------------------------------------------
' Script: sccmver.vbs
' Author: Jeff Mason aka TNJMAN aka bitdoctor
' Date:   09/18/2013
' Purpose: To check SCCM version on a list of remote computers
'
' Put Directory location that you are searching in "dirloc" variable
' Put file sub-loc in fnm1 variable ("ccm\" in this case)
' Put File name (ccmexec.exe, in this case) in the "fnm1" variable
' Put Report/Log name ("sccm-version-report.txt" in this case) in "rnm1" variable
' Put Report/Log location in "rloc1" variable
' NOTE: If report file does not exist, it will be created initially, then appeneded to
'
' Assumptions: 
' 1) You have (or create) a c:\scripts folder to hold the script and the output
' 2) You have the needed privs to run this against the remote workstation
' 3) You MODIFY the variables to meet your needs & environment
' NOTE: This script can be used/modified to check versions of MS Office, Acrobat Flash, etc.
'       Since it is "comma-separated, you can easily import into Excel or OpenOffice Calc, etc.
'
' To run this script, use either #1 or #2 below
'
' 1) For a single computer, at command prompt: cscript sccmver.vbs remote-computer-name //nologo
'    Example: cscript c:\scripts\sccmver.vbs remotepc1 //nologo
' 2) To run against multiple computers, 
'     a) Create c:\scripts\sccm-report.bat with multiple computer names
'        Example of 'sccm-report.bat'
'         rem -- sccm-report.bat [calling file] --
'         cscript c:\scripts\sccmver.vbs TJONES //nologo
'         cscript c:\scripts\sccmver.vbs PSMITH //nologo
'         cscript c:\scripts\sccmver.vbs DLITTLE //nologo
'         rem -- where TJONES, PSMITH & DLITTLE are examples of remote computer names
'     b) Execute/run the calling bat file; example:
'         c:\scripts\sccm-report.bat
'         
' 3) When the run (#1 or #2 above) has finished, review the report/log:
'    From command prompt, type "notepad c:\scripts\sccm-version-report.txt" to check the resulting versions
'
'-----------------------------------------------------------------------------------------------------------
'
Dim wshShell
Dim strComputer, windir
Dim fso, rptlog, dirloc
Dim targetfile, fvar, fversion, fname, fdtmod
Dim fnm1, floc1, rpt
'
'-------------------------------------
'MODIFY THESE VARIABLES TO YOUR NEEDS
'-------------------------------------
'
floc1 = "ccm\"
fnm1 = "ccmexec.exe"
rnm1 = "sccm-version-report.txt"
rloc1 = "c:\scripts\"
rpt = rloc1 & rnm1

Const ForAppending = 8

strComputer = Wscript.Arguments.Item(0)

' --> for debugging: Wscript.Echo strComputer

Set wshShell = WScript.CreateObject ("WScript.Shell")

windir = wshShell.ExpandEnvironmentStrings ("%WINDIR%")

Set fso = CreateObject ("Scripting.FileSystemObject")

set rptlog = fso.OpenTextFile (rpt, ForAppending, TRUE)

Set objFSO = CreateObject("Scripting.FileSystemObject")

'64 or 32 bit
If objFSO.FolderExists("\\" & strComputer & "\c$\windows\syswow64") Then
    dirloc = "\c$\Windows\syswow64\"
Else
    dirloc = "\c$\Windows\system32\"
End If

targetfile = "\\" & strComputer & dirloc & floc1 & fnm1 & ""

' --> for debugging: msgbox(targetfile)

On Error Resume Next

Set fvar = fso.GetFile (targetfile)
' for debugging: msgbox "Error: " & err.Number
If err.Number = 0 Then
  fversion = fso.GetFileVersion (targetfile)
  fname = fvar.name
  fdtmod = fvar.DateLastModified
Else
  err.Clear
  fversion = "Unknown version"
  fname = "No "& fnm1 & " exists!"
  fdtmod = "Unknown modified date"
End If

On Error Goto 0

' Write a line and close the rpt/log file
rptlog.write strComputer & ", " & fname & ", " & fdtmod & ", " & fversion & VbCrLf
rptlog.close : set rptlog = nothing 