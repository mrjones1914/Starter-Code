# Open this file in the ISE. Highlight one line and press F8 to
# execute just that line.

Get-Service | sort -Property status | Select-Object -First 10

Get-Date | Select-Object -Property timeofday

Get-Process |sort pm -Descending | Select-property name,id,pm,vm -First 10

Get-Eventlog -Newest 10 -LogName Security | Select-Object -Property eventid,timewritten

