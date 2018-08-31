<#
GetRemoteLocalAdmins.ps1

Usage: Take a list of computers and enumerate the members
    of the local Administrators group on each one

Added by: MRJ 1/20/1016

#>

function get-localadmin {  
param ($strcomputer)  
  
$admins = Gwmi win32_groupuser –computer $strcomputer   
$admins = $admins |? {$_.groupcomponent –like '*"Administrators"'}  
  
$admins |% {  
$_.partcomponent –match “.+Domain\=(.+)\,Name\=(.+)$” > $nul  
$matches[1].trim('"') + “\” + $matches[2].trim('"')  
}  
}


$Servers = get-content .\servers.txt
foreach ($s in $Servers) {
    write-host $host
    $admins = get-localadmin $s

    foreach ($admin in $admins)
    {
        $str = "$s,$admin"
        $str | Out-File "M:\Engineering\Scripts\Powershell\AdminList.txt" -Append

    }

}
