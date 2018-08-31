Option Explicit
Dim objPrinter
Set objPrinter = CreateObject("WScript.Network") 
objPrinter.SetDefaultPrinter "\\S003878\p003592"
' End of example VBScript 