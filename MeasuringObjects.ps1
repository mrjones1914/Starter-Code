# Open this file in the ISE. Highlight one line and press F8 to
# execute just that line.

Get-Service | Measure-Object

Get-Process | Get-Member measure

Get-Process | measure -prop vm -sum -average -Maximum -Minimum
