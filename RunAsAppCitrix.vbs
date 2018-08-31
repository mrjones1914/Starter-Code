' publish app.bat with content c:\windows\system32\cscript.exe c:\batch\runasapp.vbs

 RunAsApp.vbs
 Option explicit
 Dim oShell
 set oShell= Wscript.CreateObject("WScript.Shell")

 'Replace the path with the program you wish to run c:\program files...

 oShell.Run "runas /user:domain\username ""C:\Program Files\...."""
 WScript.Sleep 100

 'Replace the string --> yourpassword~ with the

 'password used on your system. Include the tilde "~"

 oShell.Sendkeys "password~"
 Wscript.Quit




'Create a batch file: c:\windows\system32\cscript.exe c:\batch\runasapp.vbs

