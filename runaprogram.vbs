'keep it simple:

Dim shell
Set shell = CreateObject("WScript.Shell") 
shell.Run """E:\Program Files\T.L. Ashford & Associates\Barcode400 3.2A\BC400SignOn.exe"

'Run the script as a scheduled task on your server and send the output to a text file with a command like:
' cscript.exe //NoLogo "C:\script.vbs" > "C:\Logfile.txt"
' or
' runas /profile /user:domain\adminuserid "cscript.exe C:\Scripts\script.vbs"