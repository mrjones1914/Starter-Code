cls
#$hostname = Get-Content "\\ServerName\servers.txt
$hostname = "S005633"
foreach($server in $hostname)
{
Write-Host $server -ForegroundColor Black  -BackgroundColor Cyan
get-wmiobject -computer $server win32_logicaldisk -filter "drivetype=3" | ForEach-Object `
{ 
	Write-Host  Device name : $_.deviceid "(" $_.VolumeName ")" -BackgroundColor Black ; write-host Total Space : ($_.size/1GB).tostring("0.00")GB; write-host Free Space : ($_.freespace/1GB).tostring("0.00")GB
}
}

