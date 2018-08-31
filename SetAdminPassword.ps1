# Changes the Local Adminsistrator password
# MRJ - 11.20.2014


#You need Quest ActiveRoles Management Shell for this

Add-PSSnapin Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue
Get-QADComputer -SearchRoot "OU=Servers,OU=Computers and Servers,DC=redgold,DC=com" | ForEach-Object {add-content -path .\servers.txt -value $_.Name}


#resetting the passwords

$erroractionpreference = "SilentlyContinue"

$date = Get-Date

foreach ($strComputer in get-content .\servers.txt)
{
# see if the server is reachable
$ping = new-object System.Net.NetworkInformation.Ping

$Reply = $null
$Reply = $ping.send($strComputer)

if($Reply.status -like 'Success')
{

$admin=[adsi]("WinNT://" + $strComputer + "/administrator, user")

$admin.psbase.invoke("SetPassword", "newpassword")

Add-Content -path C:\logs\pswdreset.log -Value "Administrator-password on $strComputer reset $date"

}

}