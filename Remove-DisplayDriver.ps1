Get-Service -Displayname "*Intel(R) HD Graphics Control Panel Service*" | Stop-Service 
$x = Get-WmiObject Win32_PnPSignedDriver | where {$_.DeviceName -like "*Intel(R) HD Graphics*" -and $_.InfName -like "*oem*"} 
foreach ($InfName in $x) { 
    pnputil -f -d $x.InfName
 
} 