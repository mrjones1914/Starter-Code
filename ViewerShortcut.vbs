Option Explicit

On Error Resume Next

Dim objShell
Dim objDesktop
Dim objLink
Dim strAppPath
Dim strWorkDir
Dim strIconPath



strWorkDir ="C:\Windows"
strAppPath = "http://viewer.redgold.com:55000"
'if you want to use an icon for the shortcut
'strIconPath = "\\pathtoicon\folder\icon.ico,0"

Set objShell = CreateObject("WScript.Shell")
objDesktop = objShell.SpecialFolders("Desktop")
Set objLink = objShell.CreateShortcut(objDesktop & "\Stratum Viewer.lnk")
'Set objLink = objShell.CreateShortcut(objShell.SpecialFolders("AllUsersDesktop") & "\Stratum Viewer.lnk")

objLink.Description = "Stratum Viewer"
objLink.IconLocation = strIconPath 
objLink.TargetPath = strAppPath
objLink.WindowStyle = 3
objLink.WorkingDirectory = strWorkDir
objLink.Save
