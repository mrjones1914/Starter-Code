<# $server = gwmi Win32_operatingsystem
$server.reboot()
#>
# Create a new instance of ping
$ping = new-object System.Net.Networkinformation.Ping
#Show message that the Server is still reachable
write-host "YourServerName is Still reachable" -NoNewLine -ForegroundColor "Green"

# This piece waits till the Server is no longer Reachable
do{$result = $ping.send("ServerName");write-host "." -NoNewline -ForegroundColor "Green"}
Until($result.status -ne "Success")
Write-host ""
write-host "ServerName is not reachable" -ForegroundColor "Red"

#This piece waits for the Server to come back online .
do{$result = $ping.send("ServerName");write-host "." -NoNewLine -ForegroundColor "Red"}
until ($result.status -eq "Success")