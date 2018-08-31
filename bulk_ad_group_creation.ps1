########################################################### 
# AUTHOR  : Marius / Hican - http://www.hican.nl - @hicannl  
# DATE    : 08-08-2012
# EDIT    : 16-11-2012
# CHANGES : Added functionality for duplicate OU names and
#           changed the input file slightly because of this
# COMMENT : This script does a bulk creation of Groups in
#           Active Directory based on an input csv and the
#           Active Directory Module. 
########################################################### 
Import-Module ActiveDirectory
#Import CSV
$csv = @()
$csv = Import-Csv -Path "C:\Temp\bulk_input.csv"

#Get Domain Base
$searchbase = Get-ADDomain | ForEach {  $_.DistinguishedName }

#Loop through all items in the CSV
ForEach ($item In $csv)
{
  #Check if the OU exists
  $check = [ADSI]::Exists("LDAP://$($item.GroupLocation),$($searchbase)")
  
  If ($check -eq $True)
  {
    Try
    {
      #Check if the Group already exists
      $exists = Get-ADGroup $item.GroupName
      Write-Host "Group $($item.GroupName) alread exists! Group creation skipped!"
    }
    Catch
    {
      #Create the group if it doesn't exist
      $create = New-ADGroup -Name $item.GroupName -GroupScope $item.GroupType -Path ($($item.GroupLocation)+","+$($searchbase))
      Write-Host "Group $($item.GroupName) created!"
    }
  }
  Else
  {
    Write-Host "Target OU can't be found! Group creation skipped!"
  }
}