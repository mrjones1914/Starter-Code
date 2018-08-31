# import the powershell active direcory module
Import-Module ActiveDirectory

# get the group members
$servers = Get-ADGroupMember -Identity GroupWithServersInIt # or just list "server1,server2,etc."

<# install SNMP on the servers
foreach ($server in $servers) {
	invoke-command -computername $server.name -ScriptBlock {import-module ServerManager; Add-WindowsFeature SNMP-Services}
} #>

invoke-command -computername $servers -ScriptBlock {import-module ServerManager; Add-WindowsFeature SNMP-Service -IncludeManagementTools }