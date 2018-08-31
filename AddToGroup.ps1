import-module activedirectory
$cred = Get-Credential # Prompt for Domain Admin login
$grp = Read-Host "Enter security group name: "
$uid = Read-Host "Enter user ID: "
Add-ADGroupMember -identity $grp -Member $uid -Credential $cred

Write-Host " $uid is now a member of $grp "
# Remove-ADGroupMember -identity "RS IT Service Engineer" -Member mjones -Credential $cred
# Get-ADGRoupMember $grp
