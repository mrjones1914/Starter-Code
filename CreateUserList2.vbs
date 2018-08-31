' VBScript program to create a text file listing all users in the
' domain.
'
' ----------------------------------------------------------------------
' Copyright (c) 2002-2010 Richard L. Mueller
' Hilltop Lab web site - http://www.rlmueller.net
' Version 1.0 - November 10, 2002
' Version 1.1 - February 4, 2003
' Version 1.2 - February 19, 2003 - Standardize Hungarian notation.
' Version 1.3 - January 25, 2004 - Modify error trapping.
' Version 1.4 - July 30, 2007 - Escape any "/" characters in DN's.
' Version 1.5 - November 6, 2010 - No need to set objects to Nothing.
' This program enumerates all users in the domain and writes each user's
' LDAP DistinguishedName to a text file, one name per line.
'
' You have a royalty-free right to use, modify, reproduce, and
' distribute this script file in any way you find useful, provided that
' you agree that the copyright owner above has no warranty, obligations,
' or liability for such use.

Option Explicit

Dim strFilePath, objFSO, objFile, adoConnection, adoCommand, objRootDSE
Dim strDNSDomain, strFilter, strQuery, adoRecordset, strDN

Const ForWriting = 2
Const OpenAsASCII = 0
Const CreateIfNotExist = True

' Check for required arguments.
If (Wscript.Arguments.Count &lt; 1) Then
    Wscript.Echo "Arguments &lt;FileName&gt; required. For example:" &amp; vbCrLf _
        &amp; "cscript CreateUserList2.vbs c:\MyFolder\UserList2.txt"
    Wscript.Quit(0)
End If

strFilePath = Wscript.Arguments(0)
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Open the file for write access.
On Error Resume Next
Set objFile = objFSO.OpenTextFile(strFilePath, _
    ForWriting, CreateIfNotExist, OpenAsASCII)
If (Err.Number &lt;&gt; 0) Then
    On Error GoTo 0
    Wscript.Echo "File " &amp; strFilePath &amp; " cannot be opened"
    Wscript.Quit(1)
End If
On Error GoTo 0

' Use ADO to search the domain for all users.
Set adoConnection = CreateObject("ADODB.Connection")
Set adoCommand = CreateObject("ADODB.Command")
adoConnection.Provider = "ADsDSOOBject"
adoConnection.Open "Active Directory Provider"
Set adoCommand.ActiveConnection = adoConnection

' Determine the DNS domain from the RootDSE object.
Set objRootDSE = GetObject("LDAP://RootDSE")
strDNSDomain = objRootDSE.Get("defaultNamingContext")

' Filter on all users.
strFilter = "(&amp;(objectCategory=person)(objectClass=user))"

strQuery = "&lt;LDAP://" &amp; strDNSDomain &amp; "&gt;;" &amp; strFilter _
    &amp; ";distinguishedName;subtree"

adoCommand.CommandText = strQuery
adoCommand.Properties("Page Size") = 100
adoCommand.Properties("Timeout") = 30
adoCommand.Properties("Cache Results") = False

' Enumerate all users. Write each user's Distinguished Name to the file.
Set adoRecordset = adoCommand.Execute
Do Until adoRecordset.EOF
    strDN = adoRecordset.Fields("distinguishedName").Value
    ' Escape any forward slash characters, "/", with the backslash
    ' escape character. All other characters that should be escaped are.
    strDN = Replace(strDN, "/", "\/")
    objFile.WriteLine strDN
    adoRecordset.MoveNext
Loop
adoRecordset.Close

' Clean up.
objFile.Close
adoConnection.Close
