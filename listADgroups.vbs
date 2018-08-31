ServerName="redgold.com"

Set objXL = WScript.CreateObject("Excel.Application")
objXL.Visible = TRUE
objXL.WorkBooks.Add

objLine = 1
objXL.Cells(objLine, 1).Value = "Users"
objXL.Cells(objLine, 2).Value = "Groups"

objLine = objLine + 1
objXL.Cells(objLine, 1).Value = ServerName

Set Domain = GetObject("WinNT://" & ServerName)
For each Object in Domain
    if Object.class = "User" then
      set oUser = GetObject("WinNT://" & ServerName & "/" & Object.Name)
          if oUser.accountdisabled = "False" then
for each oGroup in oUser.Groups
  objLine=objLine+1
  objXL.Cells(objLine,1).Value = Object.Name
  objXL.Cells(objLine,3).Value = oGroup.Name
  next
          end if
    end if
Next

msgbox "Done"

' all I need to know now is how to change this part to grab computers rather than users:

' if Object.class = "User" then
'      set oUser = GetObject("WinNT://" & ServerName & "/" & Object.Name)

' Tried this:
' Do Until objRecordSet.EOF
'    Set objOU = GetObject(objRecordSet.Fields("ADsPath").Value)
'   Wscript.Echo objOU.distinguishedName
'
'    objOU.Filter = Array("Computer")
'    
'    For Each objItem in objOU
'        Wscript.Echo "  " & objItem.CN
''    Next
'
'    Wscript.Echo
'    Wscript.Echo
'    objRecordSet.MoveNext
' Loop
	  