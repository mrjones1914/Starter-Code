Import-Module ActiveDirectory
Get-Content sp.txt | Get-ADComputer -Prop description | select Name,Description | Export-CSV -NoType comps.csv -UseCulture