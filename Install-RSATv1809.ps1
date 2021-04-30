<#
.SYNOPSIS
    Powershell script to install/uninstall RSAT (Remote Server Administration Tools) on Windows 10 v1809 and higher
   
.DESCRIPTION
    RSAT (Remote Server Administration Tools) in Windows 10 v1809 are no longer a downloadable add-on to Windows. Instead its included as a set of  "Features on Demand" directly in Windows.
    The script requires adminitrative rights to run.
    The script will only run on Windows 10 v1809 or higher.
    The script can be run from SCCM and as of such I have added a registry key for you to use as detection method in the application model
    
.EXAMPLES
    .\Install-RSATv1809.ps1 -Uninstall (Removes all RSAT features from the local PC)
    .\Install-RSATv1809.ps1 -All (Install all the RSAT features on the local PC)
    .\Install-RSATv1809.ps1 -Basic (Installs AD, DHCP, DNS, GP Management and Server Manager on the local PC)
    
.NOTES
    Filename: Install-RSATv1809.ps1
    Version: 1.0
    Author: Martin Bengtsson
    Blog: www.imab.dk
    Twitter: @mwbengtsson

.LINKS
    
#> 

[CmdletBinding()]
param(
    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$All,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$Basic,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$ServerManager,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [switch]$Uninstall
)

# Check for administrative rights
if (-NOT([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    
    Write-Warning -Message "The script requires elevation"
    break
    
}

# Variables
$1809Build = "17763"
$Windows = Get-WmiObject -Class Win32_OperatingSystem | Select-Object BuildNumber
# Registrypath - change to fit your need
$RegistryPath = "HKLM:\Software\imab.dk"

# Check if running supported version of Windows 10
if ($Windows.BuildNumber -lt "$1809Build") {
    
    Write-Error -Message "Oops - not running the proper Windows build. Windows 10 v1809 is required as a minimum."
    break

}

# Continuing if running on supported version of Windows 10
else { 
    
    if ($PSBoundParameters["All"]) {
        
        # Query for all RSAT features that's not installed already
        $Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "NotPresent"}

        if ($Install -ne $null) {

            foreach ($Item in $Install) {
           
                try {
                    Write-Host -ForegroundColor Yellow "Adding" $Item.Name "to Windows"
                    Add-WindowsCapability -Online -Name $Item.Name
                    }
            
                catch [System.Exception]
                    {
                    Write-Warning -Message $_.Exception.Message ; break
                    }
            }
            
            # Adding registry key for detection method in SCCM
            if (-NOT(Test-Path -Path $RegistryPath)) {
                New-Item -Path $RegistryPath –Force
                }
            
            New-ItemProperty -Path $RegistryPath -Name "1809RSATInstalled" -Value 1 -PropertyType "String" -Force
            
        }
        
        else {
            Write-Host -ForegroundColor Red "RSAT seems to be installed already"
        }
    }

    if ($PSBoundParameters["Basic"]) {
        
        $Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ActiveDirectory*" -OR $_.Name -like "Rsat.DHCP.Tools*" -OR $_.Name -like "Rsat.Dns.Tools*" -OR $_.Name -like "Rsat.GroupPolicy*" -AND $_.State -eq "NotPresent" }

        if ($Install -ne $null) {
        
            foreach ($Item in $Install) {
           
                try {
                    Write-Host -ForegroundColor Yellow "Adding" $Item.Name "to Windows"
                    Add-WindowsCapability -Online -Name $Item.Name
                    }
            
                catch [System.Exception]
                    {
                    Write-Warning -Message $_.Exception.Message ; break
                    }
            }
            
            # Adding registry key for detection method in SCCM
            if (-NOT(Test-Path -Path $RegistryPath)) {
                New-Item -Path $RegistryPath –Force
                }
            
            New-ItemProperty -Path $RegistryPath -Name "1809RSATInstalled" -Value 1 -PropertyType "String" -Force
        }

        else {
            $Install = (Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ServerManager*"}).Name
            Write-Host -ForegroundColor Red $Install "seems to be installed already"
        }
        

    }

    if ($PSBoundParameters["ServerManager"]) {
        
        $Install = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ServerManager*" -AND $_.State -eq "NotPresent"} 
          
        if ($Install -ne $null) {
            
            try {
                Write-Host -ForegroundColor Yellow "Adding" $Install.Name "to Windows"
                Add-WindowsCapability -Online -Name $Install.Name
                }
            
            catch [System.Exception]
                {
                Write-Warning -Message $_.Exception.Message ; break
                }
            
            if (-NOT(Test-Path -Path $RegistryPath)) {
                New-Item -Path $RegistryPath –Force
                }
            
            New-ItemProperty -Path $RegistryPath -Name "1809RSATInstalled" -Value 1 -PropertyType "String" -Force        
        }
        
        else {
            $Install = (Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat.ServerManager*"}).Name
            Write-Host -ForegroundColor Red $Install "seems to be installed already"
        }
    }

    if ($PSBoundParameters["Uninstall"]) {
        
        # Querying for installed RSAT features first time
        $Installed = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "Installed" -AND $_.Name -notlike "Rsat.ServerManager*" -AND $_.Name -notlike "Rsat.GroupPolicy*" -AND $_.Name -notlike "Rsat.ActiveDirectory*"} 

        if ($Installed -ne $null) {
            
            # Removing first round of RSAT features - some features seems to be locked until others are removed first
            foreach ($Item in $Installed) {
           
                try {
                    Write-Host -ForegroundColor Yellow "Removing" $Item.Name "from Windows"
                    Remove-WindowsCapability -Name $Item.Name -Online
                    }
            
                catch [System.Exception]
                    {
                    Write-Warning -Message $_.Exception.Message ; break
                    }
            }       
                          
        }

        # Querying for installed RSAT features second time
        $Installed = Get-WindowsCapability -Online | Where-Object {$_.Name -like "Rsat*" -AND $_.State -eq "Installed"}
        
        if ($Installed -ne $null) { 
           
            # Removing second round of RSAT features
            foreach ($Item in $Installed) {
           
                try {
                    Write-Host -ForegroundColor Yellow "Removing" $Item.Name "from Windows"
                    Remove-WindowsCapability -Name $Item.Name -Online
                    }
            
                catch [System.Exception]
                    {
                    Write-Warning -Message $_.Exception.Message ; break
                    }
            } 
            
            # Removing registry key used for detection method in SCCM
            Remove-ItemProperty -Path $RegistryPath -Name "1809RSATInstalled" -Force
        }

        else {
            Write-Host -ForegroundColor Red "Nothing to uninstall"
        }
    }

}

