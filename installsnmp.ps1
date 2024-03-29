﻿#Powershell Script To Install SNMP Services (SNMP Service, SNMP WMI Provider)

#Variables :)
$pmanagers = "172.17.2.157"
$commstring = @("BlueBird59","RedRaven94")

#Import ServerManger Module
Import-Module ServerManager

#Check If SNMP Services Are Already Installed
$check = Get-WindowsFeature | Where-Object {$_.Name -eq "SNMP-Service"}
If ($check.Installed -ne "True") {
	#Install/Enable SNMP Services
	Add-WindowsFeature SNMP-Service | Out-Null
}

##Verify Windows Servcies Are Enabled
If ($check.Installed -eq "True"){
	#Set SNMP Permitted Manager(s) ** WARNING : This will over write current settings **
	reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v 1 /t REG_SZ /d localhost /f | Out-Null
	#Used as counter for incremting permitted managers
	$i = 2
	Foreach ($manager in $pmanagers){
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\PermittedManagers" /v $i /t REG_SZ /d $manager /f | Out-Null
		$i++
		}
	#Set SNMP Community String(s)- *Read Only*
	Foreach ( $string in $commstring){
		reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v $string /t REG_DWORD /d 4 /f | Out-Null
		}
}
Else {Write-Host "Error: SNMP Services Not Installed"}