$targets = gc "C:\Scripts\names.txt"
$Location = Read-Host "Enter Location ID "


Invoke-Command -ComputerName $targets -ScriptBlock {reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\RFC1156Agent" /v sysLocation /t REG_SZ /d $Location /f | Out-Null}

Invoke-Command -ComputerName $targets -ScriptBlock { Restart-Service -Name SNMP }