##############################################################################################
##  Find out which computer(s) a user is logged into
##
##  This script requires the Quest ActiveRoles Management Shell for Active Directory snap-in
##  'cuz I don't know how to make it work without it 
##            -MRJ 10.31.2014
##############################################################################################

Add-PSSnapin Quest.ActiveRoles.ADManagement -ErrorAction SilentlyContinue
$ErrorActionPreference = "SilentlyContinue"

# Retrieve Username to search for, error checks to make sure the username
# is not blank and that it exists in Active Directory

Function Get-Username {
$Global:Username = Read-Host "Enter username you want to search for"
if ($Username -eq $null){
	Write-Host "Username cannot be blank, please re-enter username..."
	Get-Username}
$UserCheck = Get-QADUser -SamAccountName $Username
if ($UserCheck -eq $null){
	Write-Host "Invalid username, please verify this is the logon id for the account"
	Get-Username}
}

get-username

$computers = Get-QADComputer -OSname '*7*' | where {$_.accountisdisabled -eq $false}
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