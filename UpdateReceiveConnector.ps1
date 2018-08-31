# Grab all our current connectors - should be 1 per hub server
$Connectors = Get-ReceiveConnector | where { $_.Name -eq "Relay" }
 
# set value to current IP listed in first connector found
$ip = $connectors[0].RemoteIpRanges
 
# Open the File of IPs to add
$import = Import-Csv "1-NewSMTPRelayAddress.txt"
$updateConnector = $false
 
# Loop through CSV File
$import | Foreach {
 # Set Vars
 $newip = $_.ip
 
 # Update Documentation (IP, Server, Admin, Application, Date Access Granted)
 $thedate2 = Get-Date -f "yyyy-MM-dd HH:mm"
 $out = $newip + "," + $_.Server + "," + $_.Admin + ","
 $out += $_.Application + "," + $_.fromaddr + "," + $thedate2 + "`n"
 $out | out-file SMTP_Relay_Access.csv -append
 
 # add new ip to the list
 $ip += $newip
 
 # set a var so we know we need to update the connectors
 $updateConnector = $true
}
 
 
if($updateConnector) {
 # add those to all the connectors
 $Connectors | Set-ReceiveConnector -RemoteIPRanges $ip
 Write-host "The Following IPs are in the Connector" $ip
 
 # Log run and clear file
 $newname = $thedate + "_IPsAdded.txt"
 copy-item -path "1-NewSMTPRelayAddress.txt" -destination "Log\$newname"
 "IP,Server,Admin,Application,fromaddr" | out-file 1-NewSMTPRelayAddress.txt
} else {
 write-host "No addresses found in the file"
}
