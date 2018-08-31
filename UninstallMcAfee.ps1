<#
    ******* UNINSTALL MCAFEE ********
    ******* MRJ - 5.11.208   ********

>get-wmiobject win32_product -filter "Name LIKE '%McAfee%'"

IdentifyingNumber : {4F574B83-3AE0-419F-8A3B-985C389334B4}
Name              : McAfee Endpoint Security Threat Prevention
Vendor            : McAfee, LLC.
Version           : 10.5.3
Caption           : McAfee Endpoint Security Threat Prevention

IdentifyingNumber : {386A9C46-C31F-42E8-AC39-583A3174945A}
Name              : McAfee Agent
Vendor            : McAfee, Inc.
Version           : 5.05.0004
Caption           : McAfee Agent

IdentifyingNumber : {80B1F696-3C8F-4BBC-BD07-86CF0E37FDD2}
Name              : McAfee Endpoint Security Adaptive Threat Protection
Vendor            : McAfee, LLC.
Version           : 10.5.3
Caption           : McAfee Endpoint Security Adaptive Threat Protection

IdentifyingNumber : {6D20F37F-05CB-401E-83A3-DEB93B29196E}
Name              : McAfee Endpoint Security Platform
Vendor            : McAfee, LLC.
Version           : 10.5.3
Caption           : McAfee Endpoint Security Platform

Possible Uses for this information:

wmic product where identifyingnumber={guid} call uninstall - would have to do this for each {guid}

msiexec /x {guid} /qn /l*v C:\temp\logfile.log - this method requires that the product was installed via MSI

$WMI = get-wmiobject win32_product -filter 'identifyingnumber="{6EA7C472-79C5-4FC3-8EE5-3F364DBD643B}"'
$WMI.Uninstall()
    

 #>


$WMI = gwmi win32_Product -Filter 'identifyingnumber="{6EA7C472-79C5-4FC3-8EE5-3F364DBD643B}"'
$WMI.Uninstall()

