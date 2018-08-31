# Open this file in the ISE. Highlight one line and press F8 to
# execute just that line.

Get-Process | sort -Property id -Descending

Get-Service | sort -Property Status
# 0 = Stopped; 1 = Running; thus, stopped processes show 1st

Get-Service | sort -Property Name,Status

Get-eventlog -LogName system -Newest 10 | sort -Property timewritten