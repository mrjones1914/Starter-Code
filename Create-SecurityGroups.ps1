<# 

Bulk AD security group creation
Reads CSV file and creates security groups based on names in the list

MRJ 10.1.2015

#>

Import-Module ActiveDirectory

$groups = Import-Csv ‘c:\scripts\groups.csv‘
foreach ($group in $groups) {
New-ADGroup -Name $group.name -Path “OU=Security Groups,DC=redgold,DC=com” -Description “Security Group for XenApp Users” -GroupCategory Security -GroupScope Global
}