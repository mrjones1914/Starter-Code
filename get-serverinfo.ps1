function Get-ServerInfo {
<#
.SYNOPSIS
Uses WMI to retrieve details from one or more servers.
.DESCRIPTION
Get-ServerInfo retrieves several pieces of information from one
or more remote servers. It relies upon Windows Management
Instrumentation, which must be running and accessible on the
remote machines.
.PARAMETER computername
One or more computer names to query. Accepts pipeline input.
.PARAMETER logfile
Defaults to failed.txt; will contain the names of computers
that have failed. This file is cleared each time you run
Get-ServerInfo.
.EXAMPLE
This example illustrates how to read a file containing one
computer name per line, and then format the results as a table. 

  Get-Content names.txt | Get-ServerInfo | Format-Table
.EXAMPLE
This example shows how to query just one computer.

  Get-ServerInfo -computername SERVER-R2
.EXAMPLE
This example queries all computers in the SERVERS OU of
the AD domain COMPANY.COM. It relies on the ActiveDirectory
module that is included with Win2008R2.

  Import-Module ActiveDirectory
  Get-ADComputer -filter * `
   -searchbase 'ou=servers,dc=company,dc=com' |
  Select -expand Name | Get-ServerInfo
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True)]
        [Alias('name')]
        [string[]]$computername,
        [string]$logfile = 'failed.txt'
    )
    BEGIN {
        Del $logfile -ea SilentlyContinue
    }
    PROCESS {
        foreach ($computer in $computername) {
            $continue = $true
            try {
                $os = Get-WmiObject -class Win32_OperatingSystem `
                 -computer $computer -ea Stop
            } catch {
                $computer | out-file $logfile -append
                $continue = $false
            }
            if ($continue) {
                $bios = Get-WmiObject -class Win32_BIOS `
                 -computername $computer
                $proc = Get-WmiObject -class Win32_Processor `
                 -computername $computer | Select -first 1
                $hash = @{
                    'ComputerName'=$computer;
                    #'BIOSSerial'=$bios.serialnumber;
                    'OSVersion'=$os.caption;
                    'OSBuild'=$os.buildnumber;
                    'SPVersion'=$os.servicepackmajorversion;
                    'OSArch'=$os.osarchitecture;
                    'ProcArch'=$proc.addresswidth
                }
                $obj = New-Object -TypeName PSObject -Property $hash
                Write-Output $obj
            }
        }
    }
}


# Get-Content xaa.txt | Get-ServerInfo | Out-GridView