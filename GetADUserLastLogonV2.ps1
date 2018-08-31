Import-Module ActiveDirectory

function Get-ADUserLastLogon([string]$userName)
{
   $dcs = Get-ADDomainController -Filter {Name -like "*"}
   $time = 0
     
   foreach($dc in $dcs)
   { 
     $hostname = $dc.HostName
     $user = Get-ADUser $userName  | Get-AdoObject -properties LastLogonTimeStamp
     if($user.LastLogonTimeStamp -gt $time)

     {
       $time = $user.LastLogonTimeStamp
     
     }
  }
  $dt = [DateTime]::FromFileTime($time)
  Write-Host $username "last logged on at:" $dt #$LastLogon
}

Get-ADUserLastLogon "ccouch"