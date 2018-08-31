<# 
Create a simple text file called deploy.txt with a list
of the VMs you want to create
 

#>

# Define Variables
$strNewVMName = Get-content “c:\scripts\deploy.txt”
$strTemplate = “Server_2012_R2_64bit_Basic_Template_OR”
$strDestinationHost = “Datacenter-OR”
$strCustomSpec = “RedGold Server Build 1.0”
$strDatastore = “vBlock DatastoreCluster”
#
#For each loop will increment for every string contained with in deploy.txt
Foreach ($strServer in $strServers)
#
# The command below will create the new VM using the name from deploy.txt using the template defined in $strTemplate
# to the host defined in $strDestinationHost using the thin storage format and the customization template defined in $strCustomSpec.
{
New-VM -Name $strNewVMName -Template $(get-template $strTemplate) -VMHost $(Get-VMHost $strDestinationHost) -Datastore $(Get-Datastore $strDatastore) -DiskStorageFormat Thin -OSCustomizationSpec $(Get-OSCustomizationSpec $strCustomSpec)
}