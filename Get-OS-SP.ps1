# Get OS and Service Pack level
Get-ADComputer -Filter "OperatingSystem -like '*Server*'" -properties `
OperatingSystem,OperatingSystemServicePack | Select Name,Op* | format-list | Out-File ServerList.csv