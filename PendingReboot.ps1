# Get a list of servers requiring a restart
# MRJ 2015

Import-module ActiveDirectory

#$servers = Get-ADComputer -filter * -properties OperatingSystem | Where OperatingSystem -Match 'Server' #| Select-Object DnsHostName
$servers = get-adcomputer -filter * -SearchBase "CN=Computers,DC=redgold,DC=com"
$path = 'HKLM:\system\currentcontrolset\control\session manager'
$name = 'PendingFileRenameOperations'

Invoke-Command -computername $servers.name -ea 0 -ScriptBlock {
    Get-ItemProperty -Path $using:path -Name $using:name} | 
Select-Object pscomputername, @{
    LABEL='RebootRequired'; 
    EXPRESSION={if($_.PendingFileRenameOperations){$true}}}
