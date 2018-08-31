' 2D Arrays
'
'==========================================================================

Option Explicit
Dim i ' first element
Dim j ' second element
Dim numLoop ' counts the loops
Dim a (3,3) ' two dimension array with 4 elements each.

numLoop = 0

For i = 0 To 3
    For j = 0 To 3
numLoop = numLoop+1
WScript.Echo "i = " & i & " j = " & j
a(i, j) = "loop " & numLoop
WScript.Echo "Value stored In a(i,j) is: " & a(i,j)
    Next
Next
