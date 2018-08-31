'==========================================
 ' Check for password expiring notification
 '==========================================
 ' First, get the domain policy.
 '==========================================
 Dim oDomain
 Dim oUser
 Dim maxPwdAge
 Dim numDays
 Dim warningDays

warningDays = 14

 Set LoginInfo = CreateObject("ADSystemInfo")  
 Set objUser = GetObject("LDAP://" & LoginInfo.UserName &)  
 strDomainDN = UCase(LoginInfo.DomainDNSName) 
 strUserDN = LoginInfo.UserName

'========================================
 ' Check if password is non-expiring.
 '========================================
 Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000
 intUserAccountControl = objUser.Get("userAccountControl")
 If intUserAccountControl And ADS_UF_DONT_EXPIRE_PASSWD Then
     'WScript.Echo "The password does not expire."
 Else

     Set oDomain = GetObject("LDAP://" & strDomainDN)
     Set maxPwdAge = oDomain.Get("maxPwdAge")

    '========================================
     ' Calculate the number of days that are
     ' held in this value.
     '========================================
     numDays = CCur((maxPwdAge.HighPart * 2 ^ 32) + _
                     maxPwdAge.LowPart) / CCur(-864000000000)
     'WScript.Echo "Maximum Password Age: " & numDays

     '========================================
     ' Determine the last time that the user
     ' changed his or her password.
     '========================================
     Set oUser = GetObject("LDAP://" & strUserDN)

    '========================================
     ' Add the number of days to the last time
     ' the password was set.
     '========================================
     whenPasswordExpires = DateAdd("d", numDays, oUser.PasswordLastChanged)
     fromDate = Date
     daysLeft = DateDiff("d",fromDate,whenPasswordExpires)

     'WScript.Echo "Password Last Changed: " & oUser.PasswordLastChanged

    if (daysLeft < warningDays) and (daysLeft > -1) then
         Sub PasswordExpirationDialog(daysLeft, whenPasswordExpires)
Dim fso, objShell,  HTAFileName, HtaFile
Const TemporaryFolder = 2
Const ForReading = 1

Sub PasswordExpirationDialog(daysLeft, whenPasswordExpires)
Dim fso, objShell,  HTAFileName, HtaFile
Const TemporaryFolder = 2
Const ForReading = 1

Set fso = CreateObject("Scripting.FileSystemObject")
Set objTempFolder = fso.GetSpecialFolder(TemporaryFolder)
HTAFileName = fso.GetSpecialFolder(TemporaryFolder).Path & "c:\windows\temp\PasswordExpirationDialog.hta"
Set HtaFile = fso.CreateTextFile(HTAFileName, True)
With HtaFile
    .writeline("<html><head>")
    .writeline("<title>PASSWORD EXPIRATION WARNING!</title>")
    .writeline("<HTA:APPLICATION ID='PaswordDialog'/></head><script language='VBScript'>")

    .writeline("Sub Window_OnLoad")
    .writeline("window.resizeto 700,400")
    .writeline("End Sub")

    .writeline("</script><body bgcolor='white'>")
    .writeline("<image src='\\domain\netlogon\PwExpChk\Logo2.jpg' width='448' height='170' /><br>")
    .writeline("<h2>")
    .writeline("Password Expires in " & daysLeft & " day(s)" & " at " & whenPasswordExpires)
    .writeline("<br><br>Once logged in, press CTRL-ALT-DEL and")
    .writeline("<br>select the 'Change a password' option<br><br>")

    .writeline("<center><button onclick='Self.Close'>Click_To_Close</button></center>")
    .writeline("</h2></body></html>")
    .Close
End With
Set HtaFile = Nothing

Set objShell = CreateObject("WScript.Shell")
objShell.Run "%windir%\System32\mshta.exe " & Chr(34) & HTAFileName & Chr(34)

WScript.Sleep 500
fso.DeleteFile HTAFileName, True
Set objShell = Nothing

End Sub
     End if

End if

'========================================
 ' Clean up.
 '========================================
 Set oUser = Nothing
 Set maxPwdAge = Nothing
 Set oDomain = Nothing