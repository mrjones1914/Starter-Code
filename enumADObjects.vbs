' enumerate objects in an AD OU
set colItems = GetObject _
	("LDAP://OU=IT,OU=Laptops,OU=Computers,OU=REDGOLD W7,DC=redgold,DC=com")

For Each objItem in colItems
	WScript.Echo objItem.CN
Next
