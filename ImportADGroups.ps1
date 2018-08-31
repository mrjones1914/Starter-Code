#######################################################################################################
# 
#    Author:         Aaron Saikovski - Aaron.Saikovski@microsoft.com 
#    Version:         1.0 - Built using V1.0 RTM build of powershell 
#    Date:             13th May 2009 
#   Description:     Creates AD Domain global groups 
#                    The script assumes it's run on a domain controller.  
#                    It could also be run remotely and just adjust the script with a DC name 
#    Usage:             ImportADGroups.ps1 ADGroupFile.csv 
#                    Example - ImportSPGroupsV1.1.ps1 "ADGroupFile.csv" 
# 
#######################################################################################################

#Set params 
param (    
    [string] $ADGroupFile = "" 
)

###########################################################################################
#Set the DC, OU domain information - Set depending on your environment 
$objOU = [ADSI]"LDAP://S004426:389/OU=Security Groups - Global,DC=redgold,DC=com" 
###########################################################################################

#Check that we have an AD grouplist 
if ($ADGroupFile -ne "") 
{ 
    #loop over the groups in the .CSV file 
    ipcsv $ADGroupFile | foreach {

            #get the ADGroupname from the .CSV 
            $ADGroupName = $_.ADGroupName; 
            #ensure the site name isnt empty or blank 
            if ($ADGroupName -ne "") 
            { 
                Write-Host -ForegroundColor green "###########################################################################################";
                Write-Host -ForegroundColor green "Adding ADGroup - $ADGroupName"; 
                #Create the AD Group 
                $objGroup = $objOU.Create("group", "CN=" + $ADGroupName) 
                $objGroup.Put("sAMAccountName", $ADGroupName ) 
                $objGroup.SetInfo() 
                Write-Host -ForegroundColor green "###########################################################################################";
                Write-Host;        
            }        
    }   

    Write-Host; 
    Write-Host -ForegroundColor Yellow "**AD Group Processing complete**";    
} 
else 
{ 
    Write-Host -ForegroundColor red "You must specify the AD group file."; 
}