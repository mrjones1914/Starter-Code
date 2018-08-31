# Get a list of installed programs on a server
# MRJ Sept. 2015
#

$address = Read-host -prompt 'Enter target host name '

# Prompt for the host and run the query
write-host "Finding programs installed on $address, please wait..."
Get-WmiObject win32_product -ComputerName $address | Select-Object "Name","Version" | sort-object Name | Out-gridview
# write-host

<# Write the programs list to a file using:
 
 Get-WmiObject win32_product -ComputerName $address | Select-Object "Name","Version" | sort-object Name | export-csv M:\Engineering\Scripts\Powershell\programs.csv

 #>