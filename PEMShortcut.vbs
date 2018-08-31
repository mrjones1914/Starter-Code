Option Explicit 
 
On Error Resume Next 
 
Dim objShell 
Dim objDesktop 
Dim  objLink 
Dim strAppPath 
Dim strWorkDir 
Dim strIconPath 
 
 
 
strWorkDir ="C:\windows" 
strAppPath = "https://10.100.2.24:9449"
strIconPath = "\\redgold.com\NETLOGON\Regi_Shortcut.ico"
 
Set objShell = CreateObject("WScript.Shell") 
objDesktop = objShell.SpecialFolders("AllUsersDesktop") 
Set objLink = objShell.CreateShortcut(objDesktop & "\Personal Email Manager.lnk")
 
 
objLink.Description = ""
objLink.IconLocation = strIconPath  
objLink.TargetPath = strAppPath 
objLink.WindowStyle = 3 
objLink.WorkingDirectory = strWorkDir 
objLink.Save 