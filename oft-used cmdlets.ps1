#
#

Get-ADComputer -Filter {OperatingSystem -Like "Windows Server*2003*"} -Property * | Format-Table Name,OperatingSystem,OperatingSystemServicePack -Wrap -Auto

Get-MailboxStatistics mjones | fl TotalItemSize

Enter-PSSession –ComputerName S005633 -Credential redgold\mjones2

# 3
Get-Process

# 4
Exit-PSSession