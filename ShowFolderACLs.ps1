$rootfolder = Get-ChildItem -Path C:\Dell
foreach ($userfolder in $rootfolder) {
	$userfolder.FullName
	get-acl $userfolder.FullName  | foreach {write-host "The owner is : " $_.Owner "`nNTFS Security rights : " $_.AccessToString}
	Write-Host "`n"
}