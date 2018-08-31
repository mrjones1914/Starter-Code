<#  FindUser (version 2)
  Find out which computer(s) a user is logged into

Added by: MRJ 10.31.2014
    
.CHANGELOG
Made compatible with native Microsoft ActiveDirectory module
Formerly used Quest Active Roles snapin
Added by: MRJ 2.4.2016

#>

Import-Module ActiveDirectory
$ErrorActionPreference = "SilentlyContinue"

# Retrieve Username to search for, error checks to make sure the username
# is not blank and that it exists in Active Directory

Function Get-Username {
$Global:Username = Read-Host "Enter username you want to search for"
if ($Username -eq $null){
	Write-Host "Username cannot be blank, please re-enter username..."
	Get-Username}
$UserCheck = Get-ADUser -Identity $Username
if ($UserCheck -eq $null){
	Write-Host "Invalid username, please verify this is the logon id for the account"
	Get-Username}
}

get-username

$computers = Get-ADComputer -Properties operatingSystem -Filter * | where {$_.operatingSystem -like "*Server*"}
foreach ($comp in $computers)
	{
	$Computer = $comp.Name
	$ping = new-object System.Net.NetworkInformation.Ping
  	$Reply = $null
  	$Reply = $ping.send($Computer)
  	if($Reply.status -like 'Success'){
		#Get explorer.exe processes
		$proc = gwmi win32_process -computer $Computer -Filter "Name = 'explorer.exe'"
		#Search collection of processes for username
		ForEach ($p in $proc) {
	    	$temp = ($p.GetOwner()).User
	  		if ($temp -eq $Username){
			write-host "$Username is logged on $Computer"
		}}}}