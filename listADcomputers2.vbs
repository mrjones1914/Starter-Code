On Error Resume Next

Const ADS_SCOPE_SUBTREE = 2

Set objConnection = CreateObject("ADODB.Connection")
Set objCommand =   CreateObject("ADODB.Command")
objConnection.Provider = "ADsDSOObject"
objConnection.Open "Active Directory Provider"
Set objCommand.ActiveConnection = objConnection

objCommand.Properties("Page Size") = 1000
objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 

objCommand.CommandText = _
    "SELECT ADsPath FROM 'LDAP://dc=redgold,dc=com' WHERE " & _
        "objectCategory='organizationalUnit'"  

Set objRecordSet = objCommand.Execute

objRecordSet.MoveFirst

Do Until objRecordSet.EOF
    Set objOU = GetObject(objRecordSet.Fields("ADsPath").Value)
    Wscript.Echo objOU.distinguishedName

    objOU.Filter = Array("Computer")
    
    For Each objItem in objOU
        Wscript.Echo "  " & objItem.CN
    Next

    Wscript.Echo
    Wscript.Echo
    objRecordSet.MoveNext
Loop