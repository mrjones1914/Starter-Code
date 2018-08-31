# Read a .CSV file
# Remove the listed users from a specified security group

import-module activedirectory

Import-Csv User.csv | % {
$User = $_.Name
$grp = Read-Host "Enter security group name: "
Get-adprincipalgroupmembership $grp | Select @{N="User";E={$User}} #,@{N="Group";E={$_.Name}}
	Try {
	Remove-ADgroupmember $grp -Member $User -Confirm:$false -EA STOP
	Write-Host "Removed $User from $grp"
	}
	Catch {
	Write-Host "Error in removing $User from $grp"
	}
} | Export-Csv C:\backup.csv