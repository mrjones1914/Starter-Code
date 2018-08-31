# copy the group members to another group

# using Microsoft Active Directory module:
$Source_Group = "CN=Citrix 6.5 Tier 2 Support,OU=Security Groups,DC=redgold,DC=com"
$Destination_Group = "CN=XenApp Tier 2 Support,OU=Security Groups,DC=redgold,DC=com"
$Target = Get-ADGroupMember $Source_Group
foreach ($Person in $Target) {
	add-ADGroupMember -identity $Destination_Group -members $Person.distinguishedName
}

<#using Quest Active Directory module:
$Source_Group = "CN=SourceGroupName,OU=Groups,DC=domain,DC=com"
$Destination_Group = "CN=DestinationGroupName,OU=Groups,DC=domain,DC=com"
$Target = Get-QADGroupMember $Source_Group
foreach ($Person in $Target) {
add-QADGroupMember -identity $Destination_Group -member $Person.dn
}
#>