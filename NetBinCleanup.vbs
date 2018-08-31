' NAME: NetBinCleanup.vbs
'
' AUTHOR: Alan dot Kaplan at VA dot Gov 
' DATE  : 8/8/2013, 8/19/2013
'
' COMMENT: Removes files older than X days from network Recycle Bin
' Network Recycle bins are typical where there is folder redirection,
' and can take up huge amounts of space.  This can be run in logon script,
' or logoff script to keep these folder a managable size.
' 8/9/13
' You may pass a number of days to delete as a parameter
' ex: NetBinCleanup 5 
' would retain file five days older or more.
' Update 8-19 to delete recycled folders and to fix syntax error in popup
'==========================================================================

Option Explicit
Const BinSpace = &hA
Dim oShell: Set oShell = CreateObject("Shell.Application")
Dim oRecycler: Set oRecycler = oShell.NameSpace(BinSpace)
Dim wshShell: Set wshShell = WScript.CreateObject("WScript.Shell")
Dim fso:Set fso = CreateObject("Scripting.FileSystemObject")
Dim item, strPath, DeletedDate, iAge, strMsg

' ***** Edits Begin ******
'Number of days to keep a document in network Recycle bin
Dim iKeepDays:iKeepDays = 7

'Verbose tells you what file is deleted, and the file age and real name
'with pop-ups.  Designed for testing only

Const Verbose = False
' ***** Edits End ******

If WScript.Arguments.Count = 1 Then 
	iKeepDays = WScript.Arguments(0)
End If 

For Each item in oRecycler.Items
	strPath = item.path
	If IsNetPath (strPath) Then
		'Delete the Unicode and convert to date
	 	DeletedDate = cDate(StripHigh(oRecycler.GetDetailsOf(item,2)))
	 	iAge = DateDiff("d",DeletedDate,Date())
	 	If iAge > iKeepDays Then 
	 		If Verbose Then 
	 			strMsg = "Deleting " & Item.name & ", " & strPath & VbCrLf & _
	 			"   deleted on " & DeletedDate & ", " & iAge & " days ago"
	 			wshShell.popup strMsg,3,"File Deleted"
			End If

			'Delete File or Folder Item
	 		If fso.FileExists(strPath) Then fso.DeleteFile strPath,True
	 		If fso.FolderExists(strPath) Then fso.DeleteFolder strPath, True
	 	End If 
	End If 
Next

If Verbose Then 
	MsgBox WScript.ScriptName & " done.",vbInformation + vbOKOnly,"Script Complete"
End If 
' ========== Functions and Subs =================

Function IsNetPath(strPath)
	IsNetPath = False
	If left(strPath,2) = "\\" Then IsNetPath = True
End Function 

Function StripHigh(strText)
	'Remove all non alphanumeric characters
	Dim strStripped, strchar, i
	For i = 1 to len(strText)
		strchar = mid(strText,i,1)
		'Escape on ASCII character does nothing.
		'Low Unicode kept and converted to ASCII.  This handles space, tab, etc.
		If isAlphaNum(strChar) And Len(cstr(Escape(strchar)))<4 Then
			strStripped = strStripped & Unescape(strchar)
		End If
	Next
	StripHigh = strStripped
End Function 

Function isAlphaNum(char)
	isAlphaNum = False
	If Asc(char) >= 32 And Asc(char)<= 126 Then isAlphaNum = True 
End Function

