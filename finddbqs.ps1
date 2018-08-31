$strComputers = Get-Content -Path "C:\mj\computernames.txt"
[bool]$firstOutput = $true
foreach($strComputer in $strComputers)
{
$colFiles = Get-Wmiobject -namespace "root\CIMV2" `
-computername $strComputer `
-Query "Select * from CIM_DataFile `
Where Extension = 'dbq'"
foreach ($objFile in $colFiles)
{
if($objFile.FileName -ne $null)
{
$filepath = $objFile.Drive + $objFile.Path + $objFile.FileName + "." `
+ $objFile.Extension;
$query = "ASSOCIATORS OF {Win32_LogicalFileSecuritySetting='" `
+ $filepath `
+ "'} WHERE AssocClass=Win32_LogicalFileOwner ResultRole=Owner"

$colOwners = Get-Wmiobject -namespace "root\CIMV2" `
-computername $strComputer `
-Query $query
$objOwner = $colOwners[0]
$user = $objOwner.ReferencedDomainName + "\" + $objOwner.AccountName
$output = $strComputer + "," + $filepath + "," + $user + "," + $objFile.FileSize/1KB + "," + $objFile.LastModified
if($firstOutput)
{
Write-output $output | Out-File -Encoding ascii -filepath "C:\mj\queryfiles.csv"
$firstOutput = $false
}
else
{
Write-output $output | Out-File -Encoding ascii -filepath "C:\mj\queryfiles.csv" -append
}
}
}
}
