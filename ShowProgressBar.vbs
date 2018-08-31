strComputer = "."

wmiNS = "\root\cimv2"

wmiQuery = "Select name from win32_service where state = 'running'"

Set stdout = WScript.StdOut

stdout.write "Please wait"

strout = wmiQuery & VbCrLf

Set objWMIService = GetObject("winmgmts:\\" & strComputer & wmiNS)

Set colItems = objWMIService.ExecQuery(wmiQuery)

For Each objItem in colItems

stdout.Write "."

strout = strout & objItem.name & VbCrLf

Next

stdout.WriteBlankLines(1)

stdout.write(strOut)