<#
1. get a directory listing of "Z:\Employee Development and Performance", dump it into a CSV
2. extract whatever is between the parentheses in each folder name, dump it into a new CSV
3. new csv will be used to create new AD security groups for each folder

#>

$CSV = Add-content security.csv "GroupName,GroupType,GroupLocation"
$listing = Import-Csv .\edpdir.csv # directory listing of "Z:\Employee Development and Performance"

ForEach($item in $listing) {

$string = "$item.name"
$regex = [regex]"\((.*)\)" # extract whatever is between the parentheses in each folder name
$string = [regex]::Match($string, $regex).groups[1]

Write-Host "FS $string M"
Write-Host "FS $string RO"

}