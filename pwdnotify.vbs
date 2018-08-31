' Days before to alert user 
WarnDays = 14 
 
Const ADS_UF_DONT_EXPIRE_PASSWD = &h10000 
 
Set oTranslate = CreateObject("NameTranslate") 
Set oNetwork = CreateObject("WScript.Network") 
oTranslate.Init 3,"" 
oTranslate.Set 3, oNetwork.UserDomain & "\" & oNetwork.UserName 
 
Set objUserLDAP = GetObject _ 
  ("LDAP://"&oTranslate.Get(1)) 
intCurrentValue = objUserLDAP.Get("userAccountControl") 
 
' Check if user account have date to password expires 
If not intCurrentValue and ADS_UF_DONT_EXPIRE_PASSWD Then 
   
    ' Determine when password expires and calculate the days 
    ' Instead of PasswordExpirationDate, you can use the accountExpirationDate property, depending on the case 
    SenhaAlt = DateDiff("d",date,objUserLDAP.PasswordExpirationDate) 
 
    ' If password will expire 
    if (SenhaAlt <= WarnDays) then 
        Msgbox "Attention! Your password will expire in " & vbCrLf & vbCrLf & vbCrLf & "                       " & SenhaAlt & " day(s)" & vbCrLf & vbCrLf & vbCrLf & "Change it through the Intranet " & vbCrLf & "http://lockedout.redgold.com", vbCritical, "ALERT" 
    end if 
 
end i