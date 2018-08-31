##LAPS Deleted AD Object Password Lookups##


Import-Module ActiveDirectory

$laps = Read-Host 'Enter a LAPS managed computer account to lookup'
$lapscomputer = "*$laps*"

Get-ADObject -Filter {(isdeleted -eq $true) -and (name -ne "Deleted Objects") -and (name -like $lapscomputer)} -includeDeletedObjects -property * | `
Select-Object Name,ms-Mcs-AdmPwd,Modified

Read-Host 'Press Any Key to Close'