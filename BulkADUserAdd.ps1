# Powershell script to create  bulk user upload with a provided CSV file.
# 
# 
# Added 3.14.218 - MRJ
#
# v1.0 Initial Script

#Import the Active Directory Module
Import-module activedirectory 

#Import the list from the user
$Users = Import-Csv -Path ".\testing.csv"           
foreach ($User in $Users)            
{            
    $Displayname =  $User.Firstname + " " +  $User.Lastname            
    $UserFirstname = $User.Firstname
       #$UserFirstIntial = $UserFirstname.Substring(0,1)
       #$Usermiddlename = $User.Middlename 
    $UserLastname = $User.Lastname            
    $OU = $User.OU
    $SAM = $User.SAM       
    $UPN = $UserFirstname.Substring(0,1) + $User.Lastname + "@" + $User.Maildomain            
    $Description = $User.Description            
    $Password = $User.Password
	
	#Creation of the account with the requested formatting.
    #$UserInstance = get-aduser -identity <objecttouseastemplate> | use with "-Instance" parameter to copy template object
    New-ADUser -Name "$Displayname" -DisplayName "$Displayname" -SamAccountName $SAM -EmailAddress $User.mail  -UserPrincipalName $UPN -GivenName "$UserFirstname" -Surname "$UserLastname" -Description "$Description" -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -Enabled $true -Path "$OU" -ChangePasswordAtLogon $false –PasswordNeverExpires $false -server s007260.redgold.com -WhatIf
    $Displayname
}


# incorporate modifying "extensionAttribute1" for consultants:

foreach ($User in $Users) {
    Set-ADUser -Identity "$User" -Add @{"extensionAttribute1"="Contractor"}
}
