    '========================================
    ' First, get the domain policy.
    '========================================
    Dim oDomain
    Dim oUser
    Dim maxPwdAge
    Dim numDays
    Dim warningDays

    warningDays = 15
   
    Set LoginInfo = CreateObject("ADSystemInfo")  
    Set objUser = GetObject("LDAP://" & LoginInfo.UserName & "")  
    strDomainDN = UCase(LoginInfo.DomainDNSName) 
    strUserDN = LoginInfo.UserName

    
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
        Msgbox "Password Expires in " & daysLeft & " day(s)" & " at " & whenPasswordExpires & chr(13) & chr(13) & "Once logged in, press CTRL-ALT-DEL and" & chr(13) & "select the 'Change a password' option", 0, "PASSWORD EXPIRATION WARNING!"
    End if

    '========================================
    ' Clean up.
    '========================================
    Set oUser = Nothing
    Set maxPwdAge = Nothing
    Set oDomain = Nothing

