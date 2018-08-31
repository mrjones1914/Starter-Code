$wmiQuery = "Select name from win32_service where state = 'running'"

$colItems = Get-WmiObject -Query $wmiQuery

For($i = 1; $i -le $colItems.count; $i++)

{ Write-Progress -Activity "Gathering Services" -status "Found Service $i" `
-percentComplete ($i / $colItems.count*100)}

$colItems | Select name