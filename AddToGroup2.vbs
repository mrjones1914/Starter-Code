' AddToGroup2.vbs
' VBScript program to add users in a text file to a group.
'
' ----------------------------------------------------------------------
' Copyright (c) 2002-2010 Richard L. Mueller
' Hilltop Lab web site - http://www.rlmueller.net
' Version 1.0 - November 10, 2002
' Version 1.1 - February 19, 2003 - Standardize Hungarian notation.
' Version 1.2 - April 18, 2003 - Remove trailing backslash from
'                                strNetBIOSDomain.
' Version 1.3 - January 25, 2004 - Modify error trapping.
' Version 1.4 - March 18, 2004 - Modify NameTranslate constants.
' Version 1.5 - July 30, 2007 - Escape any "/" characters in group DN.
' Version 1.6 - November 6, 2010 - No need to set objects to Nothing.
'
' This program reads user names (Distinguished Names) from a text file
' and adds the users to a group. The name of the text file and the group
' sAMAccountName are passed to the program as parameters. The program
' uses the LDAP provider to bind to the group and user objects.
'
' You have a royalty-free right to use, modify, reproduce, and
' distribute this script file in any way you find useful, provided that
' you agree that the copyright owner above has no warranty, obligations,
' or liability for such use.

Option Explicit

Dim objFile, objGroup, objFSO, strFile, strGroup, strUserPath, objUser
Dim intCount, objRootDSE, objTrans, strNetBIOSDomain, strGroupPath
Dim strDNSDomain

Const ForReading = 1

' Constants for the NameTranslate object.
Const ADS_NAME_INITTYPE_GC = 3
Const ADS_NAME_TYPE_NT4 = 3
Const ADS_NAME_TYPE_1779 = 1

' Check for required arguments.
If (Wscript.Arguments.Count &lt; 2) Then
    Wscript.Echo "Required Argument Missing" &amp; vbCrLf _
        &amp; "Syntax:  cscript AddToGroup2.vbs UserList.txt GroupName"
    Wscript.Quit(0)
End If

strFile = Wscript.Arguments(0)
strGroup = Wscript.Arguments(1)

' Open the text file of user names.
Set objFSO = CreateObject("Scripting.FileSystemObject")
On Error Resume Next
Set objFile = objFSO.OpenTextFile(strFile, ForReading)
If (Err.Number &lt;&gt; 0) Then
    On Error GoTo 0
    Wscript.Echo "Unable to open file " &amp; strFile
    Wscript.Quit(1)
End If
On Error GoTo 0

' Use the NameTranslate object to get the NetBIOS domain name
' and the Distinguished Name of the group.
Set objRootDSE = GetObject("LDAP://RootDSE")
Set objTrans = CreateObject("NameTranslate")
strDNSDomain = objRootDSE.Get("DefaultNamingContext")
' Initialize NameTranslate by locating the Global Catalog.
objTrans.Init ADS_NAME_INITTYPE_GC, ""
objTrans.Set ADS_NAME_TYPE_1779, strDNSDomain
strNetBIOSDomain = objTrans.Get(ADS_NAME_TYPE_NT4)
' Remove trailing backslash.
strNetBIOSDomain = Left(strNetBIOSDomain, Len(strNetBIOSDomain) - 1)

' Use the Set method to specify the NT format of group name.
On Error Resume Next
objTrans.Set ADS_NAME_TYPE_NT4, strNetBIOSDomain &amp; "\" &amp; strGroup
If (Err.Number &lt;&gt; 0) Then
    On Error GoTo 0
    Wscript.Echo "Unable to find group " &amp; strGroup
    objFile.Close
    Wscript.Quit(1)
End If

' Use Get method to retrieve group Distingished Name.
strGroupPath = objTrans.Get(ADS_NAME_TYPE_1779)

' Escape any forward slash characters, "/", with the backslash
' escape character. All other characters that should be escaped are.
strGroupPath = Replace(strGroupPath, "/", "\/")

' Bind to group object.
Set objGroup = GetObject("LDAP://" &amp; strGroupPath)
If (Err.Number &lt;&gt; 0) Then
    On Error GoTo 0
    Wscript.Echo "Unable to bind to group" &amp; vbCrLf &amp; strGroupPath
    objFile.Close
    Wscript.Quit(1)
End If
On Error GoTo 0

' Read names from the text file, bind to the users, and add them to the
' group. intCount is the number of users added to the group.
intCount = 0
Do Until objFile.AtEndOfStream
    strUserPath = Trim(objFile.ReadLine)
    If (strUserPath &lt;&gt; "") Then
        On Error Resume Next
        Set objUser = GetObject("LDAP://" &amp; strUserPath)
        If (Err.Number &lt;&gt; 0) Then
            On Error GoTo 0
            Wscript.Echo "User " &amp; strUserPath &amp; " not found"
        Else
            objGroup.Add(objUser.AdsPath)
            If (Err.Number &lt;&gt; 0) Then
                On Error GoTo 0
                Wscript.Echo "Error adding user " &amp; objUser.sAMAccountName _
                    &amp; " to group " &amp; strGroup
            Else
                On Error GoTo 0
                intCount = intCount + 1
            End If
        End If
    End If
Loop

Wscript.Echo CStr(intCount) &amp; " members added to group " &amp; strGroup

' Clean up.
objFile.Close
