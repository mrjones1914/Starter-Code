# Change the local Administrator password - MRJ 11.20.2014
# Uncomment the section you want to use

# on a single computer
#$computerName = "L004943"
#$adminPassword = "NewPassword"
#
#$adminUser = [ADSI] "WinNT://$computerName/Administrator,User"
#$adminUser.SetPassword($adminPassword)

# on a list of computers
$pswd = "NewPassword"
$user = "Administrator"
foreach($_ in (Get-Content .\Servers.txt)){
$newpass = [ADSI]"WinNT://$_/$user,user"
$newpass.SetPassword($pass)
$newpass.SetInfo()
}