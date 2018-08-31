' basicarray.vbs

Option Explicit
On Error Resume Next

Dim arcomputer
Dim Computer
Dim i
i=0
arcomputer = Array ("s1", "s2", "s3")
For Each computer In arcomputer
	WScript.Echo(arComputer(i))
	i=i+1
Next
