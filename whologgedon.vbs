Option explicit

' List Last logins on a client
' By Remco Simons [NL] 2011
' http://forums.petri.com/showthread.php?t=55222

' (Note !,
'  also a remote WMI session to the computer and other
'  types of remote logon can be Registered User Logins too! )

Const HKEY_LOCAL_MACHINE = &H80000002
Dim strComputer, oReg, oWMISvc, regEx, dt

strComputer = "D005727"  'for local computer enter "."

Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & _ 
    strComputer & "\root\default:StdRegProv")
Set oWMISvc = GetObject("winmgmts:\root\cimv2")
Set regEx = New RegExp
dt = now

call LastLogons(getLocalBIAS)


Sub LastLogons(lngBias)
   Dim strKeyPath, arrSubKeys, subkey, strValueName
   Dim sUsr, LastLogon, TimeHigh, TimeLow

   On Error Resume Next
   regEx.Pattern = "^S-1-5-21-[0-9]*-[0-9]*-[0-9]*-[0-9]*$"
   regEx.IgnoreCase = TRUE

   strKeyPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
   oReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys

   For Each subkey In arrSubKeys
     If regEx.Test(subkey)=TRUE Then
       sUsr = resolveSID(subkey)

       strValueName = "ProfileLoadTimeHigh"
       oReg.GetDWORDValue HKEY_LOCAL_MACHINE, strKeyPath _
         & "\" & subkey, strValueName,TimeHigh

       strValueName = "ProfileLoadTimeLow"
       oReg.GetDWORDValue HKEY_LOCAL_MACHINE, strKeyPath _
         & "\" & subkey, strValueName,TimeLow

       LastLogon = getDT(TimeHigh, TimeLow, lngBias)

       If sUsr = Empty Then
         strValueName = "ProfileImagePath"
         oReg.GetExpandedStringValue HKEY_LOCAL_MACHINE, strKeyPath _
           & "\" & subkey, strValueName,sUsr
       End If

       ' last 24 hours only,
   rem    If DateDiff("n",LastLogon, dt)/60 =< 24 Then

       ' one particular user only,
   rem    If InStr(1,sUsr,"Igor",1) Then

         MsgBox sUsr & vbNewline _
           & "LastLogon: " & LastLogon, _
           ,"Computer: " & strComputer

   rem    End If
   rem    End If

     End If
   Next
End Sub

Function getLocalBIAS
   ' Obtain local Time Zone bias from machine registry.
   ' (= the time-zone + daylight saving offset)
   ' This bias changes with Daylight Savings Time.
   Dim strKeyPath, strValueName, lngBiasKey

   strKeyPath = "System\CurrentControlSet\Control\TimeZoneInformation"
   strValueName = "ActiveTimeBias"
   oReg.GetDWORDValue HKEY_LOCAL_MACHINE, strKeyPath, strValueName,lngBiasKey
   If (UCase(TypeName(lngBiasKey)) = "LONG") Then
     getLocalBIAS = lngBiasKey
   ElseIf (UCase(TypeName(lngBiasKey)) = "VARIANT()") Then
     getLocalBIAS = -0
     For k = 0 To UBound(lngBiasKey)
       getLocalBIAS = getLocalBIAS + (lngBiasKey(k) * 256^k)
     Next
   End If
End Function

Function getDT(H, L, Bias)
   ' http://forums.petri.com/showpost.php?p=182526&postcount=2
   On Error Resume Next

   Dim HexVal, Highpart, Lowpart, lngDate

   'HexVal = H
   'HexVal = Replace(HexVal, "0x", "")
   'HexVal = Replace(HexVal, "&H", "")
   'Highpart = CLng("&H" & HexVal)
   Highpart = H ' 

   'HexVal = L
   'HexVal = Replace(HexVal, "0x", "")
   'HexVal = Replace(HexVal, "&H", "")
   'Lowpart = CLng("&H" & HexVal)
   Lowpart = L

   '# unite the HighPart and LowPart
   lngDate = Highpart * 2^32 + L

   '# convert the number of 100-Nanosecond intervals to days
   lngDate = ((lngDate*1E-7/60) -Bias)/1440  'days

   '# Add the number of days to the "zero" date
   getDT = CDate( #1/1/1601# + lngDate )
End Function

Function resolveSID(sid)
   Dim strUser, strDomain
   On Error Resume Next
   With oWMISvc
         With .Get("Win32_SID.SID='" & sid & "'")
           strUser = .AccountName
           strDomain = .ReferencedDomainName
         End With
     End With
   If len(strUser) = 0 Then
     resolveSID = Empty
   Else
     resolveSID = strDomain & "\" & strUser
   End If
End function