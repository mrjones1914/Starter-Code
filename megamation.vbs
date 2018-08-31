' Creates a Megamation shortcut on the desktop
' MRJ

Option Explicit 
 
On Error Resume Next 
 
Dim objShell 
Dim objDesktop 
Dim  objLink 
Dim strAppPath 
Dim strWorkDir 
Dim strIconPath 
 
 
 
strWorkDir ="C:\windows" 
strAppPath = "http://ag.megamation.com"
'strIconPath = ".\megamation.png"
 
Set objShell = CreateObject("WScript.Shell") 
objDesktop = objShell.SpecialFolders("AllUsersDesktop") 
Set objLink = objShell.CreateShortcut(objDesktop & "\Megamation Systems.lnk")
 
 
objLink.Description = ""
objLink.IconLocation = strIconPath  
objLink.TargetPath = strAppPath 
objLink.WindowStyle = 3 
objLink.WorkingDirectory = strWorkDir 
objLink.Save 