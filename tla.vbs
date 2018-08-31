Option explicit
Dim oShell
set oShell= Wscript.CreateObject("WScript.Shell") 
oShell.Run ""runas /user:tlalabels" "C:\Program Files\T.L. Ashford & Associates\Barcode400 3.2A\BC400SignOn.exe""
WScript.Sleep 100
oShell.Sendkeys "tlalabels~"
Wscript.Quit 