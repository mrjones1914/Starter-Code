# Get-Content vault.csv | where { $_."Archiving Status" -like "Warning:" } | ConvertTo-Csv | out-file 'M:\Engineering\kerberos.csv'
Get-Content archive.csv | where { $_.Message -like "Warning" } | ConvertTo-Csv | out-file warning.csv
# Import-Csv vault.csv -Delimiter ","
