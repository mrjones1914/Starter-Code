# read a list from a txt file and ping the machines
# report the status
# MRJ 1/30/15

$list = get-content .\prtg.txt
foreach ($ip in $list) 
{$result = Get-WmiObject Win32_PingStatus -filter "address='$IP'"
if ($result.statuscode -eq 0)
{
write-host "$IP Server is up" | Out-File .\up.txt
}
else
{
Write-host "$IP Server is down"
}
}