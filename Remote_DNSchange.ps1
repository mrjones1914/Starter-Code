#########
### Script to modify primary and secondary DNS on remote machine.
###
### http://poshdepo.codeplex.com/
#########

### Multiple machines;
#$servers = "server1","server2","server3"

### Single machine
$servers = "server1"

foreach($server in $servers)
{
    Write-Host "Connecting to $server..."
    # GE Business
    #$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName s001300.redgold.com -ErrorAction Inquire | Where{$_.IPEnabled -eq "TRUE"}
    #$newDNS = "10.4.2.4","10.4.2.3"
    
    #OR Business
    #$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName sniffer.redgold.com -ErrorAction Inquire | Where{$_.IPEnabled -eq "TRUE"}
    #$newDNS = "10.1.2.10","10.1.2.9"

    # ElwoodPCN
    #$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName s005480.elpcn.redgold.com, S005481.elpcn.redgold.com -ErrorAction Inquire | Where{$_.IPEnabled -eq "TRUE"}
    #$newDNS = "10.200.2.2","10.200.2.3"
   
    #GenevaPCN
    #$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName s004097.gepcn.redgold.com, s004175.gepcn.redgold.com, s004180.gepcn.redgold.com, s004627.gepcn.redgold.com, s005179.gepcn.redgold.com, s005382.gepcn.redgold.com, s005383.gepcn.redgold.com, s005384.gepcn.redgold.com, s005462.gepcn.redgold.com, s005468.gepcn.redgold.com, s005469.gepcn.redgold.com, s005470.gepcn.redgold.com, s005471.gepcn.redgold.com, s005472.gepcn.redgold.com, s005492.gepcn.redgold.com, s005493.gepcn.redgold.com, s005771.gepcn.redgold.com, s005772.gepcn.redgold.com, s005928.gepcn.redgold.com -ErrorAction Inquire | Where{$_.IPEnabled -eq "TRUE"}
    #$newDNS = "10.206.2.2","10.206.2.3"

    #OrestesPCN
    #$nics = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName s003841.orpcn.redgold.com, s003982.orpcn.redgold.com, s005000.orpcn.redgold.com, s005362.orpcn.redgold.com, s005363.orpcn.redgold.com, s005364.orpcn.redgold.com, s005365.orpcn.redgold.com, s005376.orpcn.redgold.com, s005377.orpcn.redgold.com, s005386.orpcn.redgold.com, s005440.orpcn.redgold.com, s005460.orpcn.redgold.com, s005494.orpcn.redgold.com -ErrorAction Inquire | Where{$_.IPEnabled -eq "TRUE"}
    #$newDNS = "10.203.2.2","10.1.2.10"

    foreach($nic in $nics)
    {
        Write-Host "`tExisting DNS Servers " $nic.DNSServerSearchOrder
        $x = $nic.SetDNSServerSearchOrder($newDNS)
        if($x.ReturnValue -eq 0)
        {
            Write-Host "`tSuccessfully Changed DNS Servers on " $server
        }
        else
        {
            Write-Host "`tFailed to Change DNS Servers on " $server
        }
    }
}
