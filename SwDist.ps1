#Coded by Felipe Binotto
# Thanks, Felipe. -MRJ

Function Menu{

Clear-Host
Write-Host -ForegroundColor Green "SELECT ONE OF THE FOLLOWING OPTIONS"
Write-Host `n`n`n`n
Write-Host -ForegroundColor Cyan "1. Create Package          4. Create Collection"
Write-Host `n
Write-Host -ForegroundColor Cyan "2. Create Program          5. Advertise Package"
Write-Host `n
Write-Host -ForegroundColor Cyan "3. Distribute Package      6. Quit"
Write-Host `n`n
#$choice = Read-Host
$choice = $Host.UI.RawUI.ReadKey()
SWITCH($choice.character){
1 {Clear-Host; CreatePackage}
2 {Clear-Host; CreateProgram}
3 {Clear-Host; DistributePackage}
4 {Clear-Host; CreateCollection}
5 {Clear-Host; CreateAdvertisement}
6 {Clear-Host; Cleanup}
}
}
Function DefineGlobalVariables{
#Define global variables
Clear-Host
Write-Host `n`n
$global:server = Read-Host "Type SCCM server name"
$global:sitecode = (Get-WmiObject SMS_ProviderLocation -Namespace root\sms -ComputerName $server).NamespacePath.split("_")[1]
$global:namespace = "root\sms\site_$sitecode"
$global:siteserver = Get-WmiObject SMS_ProviderLocation -Namespace root\sms -ComputerName $server | Select-Object -ExpandProperty __SERVER
$global:siteName = (Get-WmiObject SMS_Site -Namespace $namespace -ComputerName $server).sitename
}

Function CreatePackage{

#Get Package Details
$name = Read-Host "Package name"
$version = Read-Host "Version"
$language = Read-Host "Language"
$description = Read-Host "Description"
$source = Read-Host "Type source folder in the format \\Server\share"

#Define Package
$pkg = @{
Name = $name;
Version = $version;
Language = $language;
Description = $description;
PackageType = 0;
PkgSourceFlag = 2;
PkgSourcePath = $source;
}
#Create Package
$global:package = Set-WmiInstance -Class SMS_Package -Arguments $pkg -Namespace $namespace -ComputerName $server
Menu
}

Function CreateProgram{

#Get Package Name if CreateProgram is the first choice
if(-not $package){
$packageName = Read-Host "What's the Package Name"
$package = Get-WmiObject -Namespace $namespace -Query "Select * from SMS_Package Where Name='$packagename'" -ComputerName $server
}
#GET OS
#$namespacepath = ((Get-WmiObject SMS_ProviderLocation -Namespace root\sms).namespacepath) + ":SMS_OS_Details"
#$OSDetails = [Wmiclass]$namespacepath
#$OSInstance = $OSDetails.CreateInstance()
#$OSInstance.MaxVersion = "6.10.9999.9999";$OSInstance.MinVersion = "6.10.0000.0"; $OSInstance.Name = "Win NT"; $OSInstance.Platform = "I386"
#Get-WmiObject -Namespace $namespace -Query "Select * from SMS_SupportedPlatforms"
#SupportedOperatingSystems = [array]$OSInstance;
#Get Program Details
$pname = Read-Host "Program Name"
$commandLine = Read-Host "Program's command line"
$diskreq = Read-Host "Disk space required (eg 200 MB)"
$duration = Read-Host "Duration in minutes"

#Define Program
$prg = @{
ProgramName = $pname;
ProgramFlags = $package.ProgramFlags -bor ([Math]::Pow(2,10)) -bor ([Math]::Pow(2,13)) -bor ([Math]::Pow(2,20)) -bor ([Math]::Pow(2,22)) -bor ([Math]::Pow(2,27));

PackageID = $package.PackageID;
CommandLine = $commandLine;
Duration = [int]$duration;
DiskSpaceReq = "$diskreq";
}
#Create Program 
$program = Set-WmiInstance -Class SMS_Program -Arguments $prg -Namespace $namespace -ComputerName $server
Menu
}

Function CreateCollection{
#Get Collection Details
$name = Read-Host "Collection Name"
#Define Collection
$col = @{
Name = $name;
OwnedByThisSite = $true;
}
#Create Collection
$collection = Set-WmiInstance -Class SMS_Collection -Arguments $col -Namespace $namespace -ComputerName $server
$collection
Clear-Host
#Establish relationship between collections
$rel = @{
ParentCollectionID = "COLLROOT";
SubCollectionID = $collection.CollectionID;
}
$relation = Set-WmiInstance -Class SMS_CollectToSubCollect -Arguments $rel -Namespace $namespace -ComputerName $server
Menu
}


Function DistributePackage{

#Get Package Name if CreateProgram is the first choice
if(-not $package){
$packageName = Read-Host "What's the Package Name"
$package = Get-WmiObject -Namespace $namespace -Query "Select * from SMS_Package Where Name='$packagename'"
}
$serverNALPath = '["Display=\\' + $siteserver + '\"]MSWNET:["SMS_SITE=' + $sitecode + '"]\\' + $siteserver + '\'
#Define DP
$dp = @{
PackageID = $package.PackageID;
ServerNALPath = $serverNALPath;
SiteCode = $sitecode;
SiteName = $siteName;
SourceSite = $sitecode;
ResourceType = "Windows NT Server"
}
#Create DP
$distributionpoint = Set-WmiInstance -Class SMS_DistributionPoint -Arguments $dp -Namespace $namespace -ComputerName $server -ErrorAction SilentlyContinue
Menu
}

Function CreateAdvertisement{

$name = Read-Host "Advertisement Name"
if(-not $collection){
$colname = Read-Host "Target collection's name"
$collection = Get-WmiObject -Namespace $namespace -Query "Select * from SMS_Collection where Name='$colname'" -ComputerName $server}
if(-not $package){
$packageName = Read-Host "What's the Package Name"
$package = Get-WmiObject -Namespace $namespace -Query "Select * from SMS_Package Where Name='$packagename'" -ComputerName $server}
if(-not $program){
$programName = Read-Host "What's the Package Name"
$program = Get-WmiObject -Namespace $namespace -Query "Select * from SMS_Program Where Name='$programName'" -ComputerName $server}

$advert =@{
AdvertFlags = $advertisement.AdvertFlags -bor ([Math]::Pow(2,25));
AdvertisementName = $name;
CollectionID = $collection.CollectionID;
PackageID = $package.PackageID;
DeviceFlags = $advertisement.DeviceFlags -bor ([Math]::Pow(2,24));
ProgramName = $program.ProgramName;
RemoteClientFlags = $advertisement.RemoteClientFlags -bor ([Math]::Pow(2,3)) -bor ([Math]::Pow(2,6)) -bor ([Math]::Pow(2,13));
SourceSite = $sitecode;
TimeFlags = $advertisement.TimeFlags;
}
$advertisement = Set-WmiInstance -Class SMS_Advertisement -Arguments $advert -Namespace $namespace -ComputerName $server
Menu
}

Function Cleanup{

Remove-Variable sitecode -Scope global
Remove-Variable namespace -Scope global
Remove-Variable server -Scope global
Remove-Variable sitename -Scope global
Break
}

DefineGlobalVariables
Menu