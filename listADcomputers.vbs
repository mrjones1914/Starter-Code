' Name : computers.vbs
' Description : script to enumerate all computers in your company/AD domain
' Author : dirk adamsky - deludi bv
' Version : 1.00
' Date : 26-02-2010
' Level : intermediate

' Setup ADO objects.
Set adoCommand = CreateObject("ADODB.Command")
Set adoConnection = CreateObject("ADODB.Connection")
adoConnection.Provider = "ADsDSOObject"
adoConnection.Open "Active Directory Provider"
adoCommand.ActiveConnection = adoConnection

' Search entire Active Directory domain.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")
strBase = "<LDAP://" & strDNSDomain & ">"

' Filter on computer objects.
strFilter = "(&(objectCategory=computer))"

' Comma delimited list of attribute values to retrieve.
strAttributes = "name"

' Construct the LDAP syntax query.
strQuery = strBase & ";" & strFilter & ";" & strAttributes & ";subtree"
adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 30
adoCommand.Properties("Cache Results") = False

' Run the query.
Set adoRecordset = adoCommand.Execute

' Enumerate the resulting recordset.
Do Until adoRecordset.EOF
	On Error Resume Next
	Wscript.echo adoRecordset.Fields("name").Value
	'Move to the next record in the recordset.
    adoRecordset.MoveNext
Loop
' Clean up.
adoRecordset.Close
adoConnection.Close

Set adoRecordset = Nothing
Set objRootDSE = Nothing
Set adoConnection = Nothing
Set adoCommand = Nothing