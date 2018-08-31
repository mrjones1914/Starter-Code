<#
************    UpdateTrapDestination.ps1    ***************
#>

<#
 Added by MRJ
    3.9.2018
#>

<#

	Purpose: add or replace an SNMP trap manager destination

#>

<#
	Revision History
	3.9.2018 - Initial Design

#>
#Set Variables

#To replace a trap manager destination, include only the new address
    #to add an additional destination, include both current AND new addresses 
    # separated by a comma

$Managers = @("10.1.2.34")
$readonlytrap = "BlueBird59"
$rwtrap = "RedRaven94"


#Update permitted Trap Managers
        Write-Host "Updating Permitted Managers"
        $i = 1
        Foreach ($Manager in $Managers){
            reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v $i /t REG_SZ /d $manager /f | Out-Null
            reg add ("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\TrapConfiguration\$rwtrap") /v $i /t REG_SZ /d $manager /f | Out-Null
            reg add ("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\TrapConfiguration\$readonlytrap") /v $i /t REG_SZ /d $manager /f | Out-Null
            $i++
        }
