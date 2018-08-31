Dim ComputerName, AdminPassword
ComputerName = "fabrikam23"
AdminPassword = "ThisIsThePassword!"

Dim AdminUser
Set AdminUser = GetObject("WinNT://" & ComputerName & "/Administrator,User")
AdminUser.SetPassword AdminPassword
