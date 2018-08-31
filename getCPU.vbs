' get CPU type
' see if you can guess what this does
'
Option Explicit
On Error Resume Next
Dim strComputer
dim CPU
Dim wmiRoot
Dim objWMIService
Dim ObjProcessor

strComputer = "."
cpu = "win32_Processor='CPU0'"
wmiRoot = "winmgmts:\\" & strComputer & "\root\cimv2"
Set objWMIService = GetObject(wmiRoot)
Set objProcessor = objWMISerivce.Get(cpu)

If objProcessor.Archetecture = 0 Then
	WScript.Echo "This is an x86 cpu."
ElseIf objProcessor.Architecture = 1 Then
	WScript.Echo "This is a MIPS cpu."
ElseIf objProcessor.Architecture = 2 Then
	WScript.Echo "This is an Alpha cpu."
ElseIf objProcessor.Architecture = 3 Then
	WScript.Echo "This is a PowerPC cpu."
ElseIf objProcessor.Architecture = 6 Then
	WScript.Echo "This is an ia64 cpu."
Else
	WScript.Echo "Cannot determine cpu type."
End If
