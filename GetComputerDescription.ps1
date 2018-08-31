Import-Module ActiveDirectory

$computers = Import-Csv C:\mj\sp.csv
foreach ($computer in $computers){
dsquery computer -name $computer.Name | dsget computer -l 
} 