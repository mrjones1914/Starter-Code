<# RemoteActions.ps1
Take some remote action on a server or group of servers
MRJ - 4.19.2018    
    
#>

$a = get-content c:\scripts\target.txt
$all = new-pssession -ComputerName $a
# $all = new-pssession -ComputerName serv1,serv2,serv3

#run a command on remote target(s)
invoke-command -session $all -ScriptBlock { Restart-Service -Name SNMPTRAP}
