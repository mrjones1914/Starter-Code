Const ADS_SCOPE_SUBTREE = 2

Set objConnection = CreateObject("ADODB.Connection")
Set objCommand = CreateObject("ADODB.Command")
objConnection.Provider = "ADsDSOObject"
objConnection.Open "Active Directory Provider"

Set objCommand.ActiveConnection = objConnection
objCommand.CommandText = _
    "Select operatingSystem, operatingSystemVersion from " & _
        "'LDAP://DC=redgold,DC=com' where objectClass='computer' ORDER BY operatingSystem"  
objCommand.Properties("Page Size") = 1000
objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 
Set objRecordSet = objCommand.Execute
objRecordSet.MoveFirst

Do Until objRecordSet.EOF
    Wscript.Echo objRecordSet.Fields("operatingSystem").Value, _
        objRecordSet.Fields("operatingSystemVersion").Value
    objRecordSet.MoveNext
Loop