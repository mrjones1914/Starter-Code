'Script deletes Computers from a csv file.
'csv format is strsAMUserName,Whatever

On Error Resume Next 'used in case user not found
Option Explicit

Const ForReading = 1

Dim strL, spl1, strOU, strComputersCN, strCompName
Dim objFSO, objInputFile 

Set objFSO = CreateObject("Scripting.FileSystemObject")

Set objInputFile = objFSO.OpenTextFile(".\Comps.csv", ForReading) 'your csv file

wscript.echo "script started"

'extract from csv file
Do until objInputFile.AtEndOfStream
	strL = objInputFile.ReadLine
	spl1 = Split(strL, ",")
	strCompName = (spl1(0))
	If ComputerExists(strCompName) = True Then
		'WScript.Echo strCompName & " exists."
		DelComputer
	End If			
Loop

Set objFSO = Nothing
Set objInputFile = Nothing

wscript.echo "script finished"


'Computer exist check
Function ComputerExists(strsAMCompName) 

Dim strDNSDomain, strFilter, strQuery
Dim objConnection, objCommand, objRootLDAP, objLDAPComputer, objRecordSet


ComputerExists = False
Set objConnection = CreateObject("ADODB.Connection")
Set objCommand =   CreateObject("ADODB.Command")
Set objRootLDAP = GetObject("LDAP://RootDSE")
objConnection.Provider = "ADsDSOObject"
objConnection.Open "Active Directory Provider"
Set objCommand.ActiveConnection = objConnection
objCommand.Properties("Page Size") = 1000
'objCommand.Properties("Searchscope") = ADS_SCOPE_SUBTREE 

strDNSDomain = objRootLDAP.Get("DefaultNamingContext")
strFilter = "(&(objectCategory=computer)(sAMAccountName=" & strsAMCompName & "))"

strQuery = "<LDAP://" & strDNSDomain & ">;" & strFilter & ";sAMAccountName,adspath,CN;subTree"

objCommand.CommandText = strQuery
'WScript.Echo strFilter
'WScript.Echo strQuery
Set objRecordSet = objCommand.Execute

If objRecordSet.RecordCount = 1 Then

objRecordSet.MoveFirst
    'WScript.Echo "We got here " & strsAMGroupName      
	'WScript.Echo objRecordSet.Fields("sAMAccountname").Value
	'WScript.Echo objRecordSet.Fields("adspath").Value
	If objRecordSet.Fields("sAMAccountname").Value = strsAMCompName Then
		ComputerExists = True
		Set objLDAPComputer = GetObject(objRecordSet.Fields("adspath").Value)
		strOU = objLDAPComputer.Parent
		strComputersCN = objRecordSet.Fields("CN").Value
	End If
Else
	WScript.Echo strsAMCompName & " Computer doesn't exist or Duplicate sAMAccountName"
	UserExists = False
	strComputersCN = ""
	strOU = ""
End If

objRecordSet.Close
Set objConnection = Nothing
Set objCommand = Nothing
Set objRootLDAP = Nothing
Set objLDAPComputer = Nothing
Set objRecordSet = Nothing

end function


Sub DelComputer

Dim objOU

'WScript.Echo strOU
'WScript.Echo strGroupCN
Set objOU = GetObject(strOU)
objOU.Delete "Computer", "cn=" & strComputersCN & ""
WScript.Echo strCompName & " (CN=" & strComputersCN & ") has been deleted."

Set ObjOU = Nothing
strComputersCN = ""

End Sub