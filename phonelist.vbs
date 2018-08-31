' Create a shortcut to the rgi phonelist on the desktop
' I did it

Option Explicit 
 
On Error Resume Next 
 
Dim objShell 
Dim objDesktop 
Dim  objLink 
Dim strAppPath 
Dim strWorkDir 
Dim strIconPath 
 
 
 
strWorkDir ="C:\windows" 
strAppPath = "http://rgi/Lists/Red%20Gold%20Internal%20Employee%20Phone%20List/AllItems.aspx"
strIconPath = "\\redgold.com\NETLOGON\Regi_Shortcut.ico"
 
Set objShell = CreateObject("WScript.Shell") 
objDesktop = objShell.SpecialFolders("AllUsersDesktop") 
Set objLink = objShell.CreateShortcut(objDesktop & "\Employee Phone List.lnk")
 
 
objLink.Description = ""
objLink.IconLocation = strIconPath  
objLink.TargetPath = strAppPath 
objLink.WindowStyle = 3 
objLink.WorkingDirectory = strWorkDir 
objLink.Save 