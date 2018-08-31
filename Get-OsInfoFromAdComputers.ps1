Function Get-ADComputersTestConnection 
{ 
Param( 
[switch]$showErrors 
) 
([adsisearcher]"objectcategory=computer").findall() | 
ForEach-Object { 
try  
{  
Test-Connection -ComputerName ([adsi]$_.path).cn -BufferSize 16 ` 
-Count 1 -TimeToLive 1 -EA stop } 
Catch [system.exception] 
{ 
if($showErrors) 
{ $error[0].tostring() }  
} 
} #end foreach-object 
} #End function Get-ADComputersTestConnection 
Function Get-OsInfo 
{ 
Param( 
[string]$computer 
) 
Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computer 
} #end function Get-OsInfo 
# *** EntryPoint to Script *** 
Get-ADComputersTestConnection |  
ForEach-Object { 
Get-OsInfo -computer $_.address } | 
Sort-Object -Property osarchitecture | 
Format-Table -Property @{ Label="name"; Expression={$_.csname} },  
@{ Label = "os-bits"; Expression = {$_.osArchitecture} },  
@{ Label = "OsEdition" ; Expression = {$_.caption} } -AutoSize | 
Tee-Object -FilePath c:\reports\osreport.txt