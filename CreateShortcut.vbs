Option Explicit

On Error Resume Next

Dim objShell
Dim objDesktop
Dim  objLink
Dim strAppPath
Dim strWorkDir
Dim strIconPath



strWorkDir ="C:\Windows"
strAppPath = "http://rgi/Lists/Red%20Gold%20Internal%20Employee%20Phone%20List/AllItems.aspx"
strIconPath = "\\redgold.com\netlogon\Regi_Shortcut.ico,0"

Set objShell = CreateObject("WScript.Shell")
objDesktop = objShell.SpecialFolders("Desktop")
Set objLink = objShell.CreateShortcut(objDesktop & "\RGi Phone List.lnk")
'Set objLink = objShell.CreateShortcut(objShell.SpecialFolders("AllUsersDesktop") & "\RGi Phone List.lnk")

objLink.Description = "Internal Phone List"
objLink.IconLocation = strIconPath 
objLink.TargetPath = strAppPath
objLink.WindowStyle = 3
objLink.WorkingDirectory = strWorkDir
objLink.Save
