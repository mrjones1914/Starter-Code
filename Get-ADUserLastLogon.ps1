<# 
Get-ADUserLastLogon.ps1
Source: https://technet.microsoft.com/en-us/library/dd378867(v=ws.10).aspx

Modified: MRJ 12/1/2015

Usage: Get-ADUserLastLogon -UserName "username"
        You can also uncomment the last line and plug in a user name, 
        then run the script

#>

Import-Module ActiveDirectory

function Get-ADUserLastLogon([string]$userName)
{

  $dcs = Get-ADDomainController -Filter {Name -like "*"}
  $time = 0
  foreach($dc in $dcs)
  { 
    $hostname = $dc.HostName
    $user = Get-ADUser $userName | Get-ADObject -Server $hostname -Properties lastLogon 
    if($user.LastLogon -gt $time) 
    {
      $time = $user.LastLogon
    }
  }

  $dt = [DateTime]::FromFileTime($time)
  Write-Host $username "last logged on at:" $dt 
  
}


# Get-ADUserLastLogon "username"