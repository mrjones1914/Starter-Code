<# 
.SYNOPSIS 
    Clone-Group
.DESCRIPTION 
    Clones group Members from Source to Target
.NOTES 
    Have both Source and Target group Distinguished Name at hand
.LINK 
#> 

#Set Source and Target Group Distinguished Name
$sourceGroup = [ADSI]"LDAP://CN=Citrix 6.5 IT Managment Users,OU=Security Groups,DC=redgold,DC=com"
$targetGroup = [ADSI]"LDAP://CN=XenApp IT Managment Users,OU=Security Groups,DC=redgold,DC=com"

"Source Group: $($sourceGroup.samAccountName)"
"Target Group: $($targetGroup.samAccountName)" 

"`nCloning Source Group to TargetGroup`n" 
  
#get Source members
foreach ($member in $sourceGroup.Member)
{
    Try
    {
        "Adding Member: $member"
        $targetGroup.add("LDAP://$($member)")
    }
    Catch
    {
        Write-Host "Error performing add action" -Fore DarkRed
    }

}