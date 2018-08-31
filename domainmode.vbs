Set objDomain = GetObject("LDAP://dc=redgold,dc=com")

If objDomain.nTMixedDomain = 0 Then
    Wscript.Echo "Domain is in native mode."
Else
    Wscript.Echo "Domain is in mixed mode."
End If