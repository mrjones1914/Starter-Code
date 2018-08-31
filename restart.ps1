# command must be run as domain admin
get-content c:\scripts\target.txt | ForEach-Object { gwmi win32_operatingsystem -ComputerName $_  | ForEach-Object { $_.reboot()}}