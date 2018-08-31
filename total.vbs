option explicit
on error resume next

dim total
dim firstvalue
dim secondvalue

firstvalue = 1
secondvalue = 3
total = firstvalue + secondvalue

WScript.Echo " the total of " & firstvalue & " and " & Secondvalue & " is " & (total)
firstvalue = total
WScript.Echo " the total of " & firstvalue & " and " & secondvalue & " is " & (total)
