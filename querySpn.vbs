Option Explicit     
Const DUMP_SPNs = True
Dim oConnection, oCmd, oRecordSet
Dim oGC, oNSP
Dim strGCPath, strClass, strSPN, strADOQuery
Dim vObjClass, vSPNs, vName

ParseCommandLine()

'--- Set up the connection ---
Set oConnection = CreateObject("ADODB.Connection")
Set oCmd = CReateObject("ADODB.Command")
oConnection.Provider = "ADsDSOObject"
oConnection.Open "ADs Provider"
Set oCmd.ActiveConnection = oConnection
oCmd.Properties("Page Size") = 1000

'--- Build the query string ---
strADOQuery = "<" + strGCPath + ">;(servicePrincipalName=" + strSPN + ");" & _
    "dnsHostName,distinguishedName,servicePrincipalName,objectClass," & _
        "samAccountName;subtree"
oCmd.CommandText = strADOQuery

'--- Execute the query for the object in the directory ---
Set oRecordSet = oCmd.Execute
If oRecordSet.EOF and oRecordSet.Bof Then
  Wscript.Echo "No SPNs found!"
Else
 While Not oRecordset.Eof
   Wscript.Echo oRecordset.Fields("distinguishedName")
   vObjClass = oRecordset.Fields("objectClass")
   strClass = vObjClass( UBound(vObjClass) )
   Wscript.Echo "Class: " & strClass
   If UCase(strClass) = "COMPUTER" Then
      Wscript.Echo "Computer DNS: " & oRecordset.Fields("dnsHostName")
   Else
      Wscript.Echo "User Logon: " & oRecordset.Fields("samAccountName")
   End If
   
   If DUMP_SPNs Then
      '--- Display the SPNs on the object --- 
      vSPNs = oRecordset.Fields("servicePrincipalName")
      For Each vName in vSPNs
         Wscript.Echo "-- " + vName
      Next
   End If
   Wscript.Echo
   oRecordset.MoveNext
 Wend
End If

oRecordset.Close
oConnection.Close

Sub ShowUsage()
   Wscript.Echo " USAGE:    " & WScript.ScriptName & _
        " SpnToFind [GC Servername or Forestname]"
   Wscript.Echo
   Wscript.Echo " EXAMPLES: " 
   Wscript.Echo "           " & WScript.ScriptName & _
        " MSSQLSvc/MySQL.company.com:1433"
   Wscript.Echo "           " & WScript.ScriptName & _
        " HOST/Server1 Corp.com"
   Wscript.Quit 0
End Sub

Sub ParseCommandLine()
  If WScript.Arguments.Count <> 1 And WScript.Arguments.Count <> 2 Then
ShowUsage()
  Else
   strSPN = WScript.Arguments(0)
   If WScript.Arguments.Count = 2 Then
      strGCPath = "GC://" & WScript.Arguments(1)
   Else
    '--- Get GC -- 
    Set oNSP = GetObject("GC:")
    For Each oGC in oNSP
      strGCPath = oGC.ADsPath
    Next
   End If
 End If 
End Sub