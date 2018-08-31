<# 
Use the Invoke-GPUpdate cmdlet to schedule a group policy refresh
     on a single server, a list of servers, or all servers in an OU

 MRJ 9/2015
EXAMPLE:
To refresh policy on a single server, you could do this -
    Invoke-GPUpdate -Computer computername -force

See https://technet.microsoft.com/en-us/library/hh967455(v=wps.630).aspx for details on the use
of Invoke-GpUpdate.
#>


# run gpupdate against a list
# Get-Content "C:\Scripts\l007247.txt" | ForEach-Object {Invoke-GPUpdate -Computer $_ -RandomDelayInMinutes 0}

# run gpupdate on all computers in a given OU:
Get-ADComputer –Filter * -SearchBase "OU=Xenapp Servers,OU=Servers,OU=Computers and Servers,DC=redgold,DC=com" | `
foreach { Invoke-GPUpdate –Computer $_.name -RandomDelayInMinutes 0}

#
