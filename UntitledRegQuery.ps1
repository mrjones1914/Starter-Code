$server =  ""
#    $Reg = Get-WmiObject -List -Namespace root\default -ComputerName $server -Credential $cred | Where-Object {$_.Name -eq "TrapConfiguration"}
reg query "HKLM\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration" /s
#    $HKLM = 2147483650
#    $TrapName = ($reg.EnumKey("$HKLM","SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration")).sNames
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration"
        gci -path $key | select property
#    $TrapName
