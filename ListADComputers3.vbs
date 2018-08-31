Dim objConnection, objCommand, objFile, strFile, strLDAP, strSelectAttr

'Set Variables
Const ADS_SCOPE_SUBTREE = 200
strFile = "adDetails.csv"
strLDAP = "OU=Servers,OU=Computers and Servers,DC=redgold,DC=com"
strSelectAttr = "cn, operatingSystem, operatingSystemServicePack"

'Create CSV File
Set objFile = CreateObject("Scripting.FileSystemObject")   
Set strWrite = objFile.OpenTextFile(strFile, 2, True)
strWrite.WriteLine("Machine Name,Operating System,Service Pack")

Set objConnection = CreateObject("ADODB.Connection")
Set objCommand =   CreateObject("ADODB.Command")
objConnection.Provider = "ADsDSOObject"
objConnection.Open "Active Directory Provider"

Set objCommand.ActiveConnection = objConnection
objCommand.CommandText = _
    "Select " & strSelectAttr & " from 'LDAP://" & strLDAP & "' " _
        & "Where objectClass='computer'"  
objCommand.Properties("Page Size") = 1000
objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 
Set objRecordSet = objCommand.Execute
objRecordSet.MoveFirst

Do Until objRecordSet.EOF
    strWrite.WriteLine( _
         objRecordSet.Fields("cn").Value & "," _
         & objRecordSet.Fields("operatingSystem").Value & "," _
         & objRecordSet.Fields("operatingSystemServicePack" _
    ).Value)

    objRecordSet.MoveNext
Loop

'close CSV file
strWrite.Close

MsgBox "Complete."

'cleanup
Set objConnection = Nothing
Set objCommand = Nothing
Set objFile = Nothing
Set strFile = Nothing
Set strLDAP = Nothing
Set strSelectAttr = Nothing

WScript.Quit