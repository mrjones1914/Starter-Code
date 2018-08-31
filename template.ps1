<#
.SYNOPSIS
Retrieves network adapter information from a computer.
.DESCRIPTION
Uses CIM to retrieve information about physical adapters
only. 
.PARAMETER ComputerName
The name of the computer to query.
.EXAMPLE
.\Get-NetAdapterInfo.ps1 -ComputerName LON-DC1 -Verbose
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [string]$ComputerName
)
