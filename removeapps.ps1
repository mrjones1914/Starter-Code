<#
.SYNOPSIS
    Removing Built-in apps from Windows 10 / Windows 8.1 / Windows 8
.DESCRIPTION
    Removing Built-in apps from Windows 10 / Windows 8.1 / Windows 8
.PARAMETER 
    PathtoWim - Path to install.wim
    select - Enable 
.EXAMPLE
    .\removeapps.ps1 -pathtowim c:\10\install.wim
    .\removeapps.ps1 -pathtowim c:\10\install.wim -select $true
    .\removeapps.ps1 -pathtowim c:\10\install.wim -select $true -index 2
.NOTES
    Script name: removeapps.ps1
    Version:     1.2
    Author:      André Picker
    Contact:     @clientmgmt
    DateCreated: 2015-07-22
    LastUpdate:  2016-03-08
    #>

param (
    [string]$pathtowim,
    [bool]$selectapps,
    [string]$index="1"
    )

$Host.UI.RawUI.BackgroundColor = "Black"; Clear-Host
$startdate = (Get-Date).ToString()
$ProgressPreference=’SilentlyContinue’

function CreateTempDirectory {
   $tmpDir = [System.IO.Path]::GetTempPath()
   $tmpDir = [System.IO.Path]::Combine($tmpDir, [System.IO.Path]::GetRandomFileName())
   [System.IO.Directory]::CreateDirectory($tmpDir) | Out-Null
   $tmpDir
   }

try {
    $pathworkfolder = CreateTempDirectory
    Write-Host "Start:" $startdate -ForegroundColor White
    Write-Host "Create temporary directory..." -ForegroundColor Green
    Write-Host "Temporary directory:" $pathworkfolder -ForegroundColor Green
    }

catch [Exception] {
    Write-Host "Error:" $_.Exception.Message -ForegroundColor Red; break
    }

try {
    Write-Host "Mounting Windows-Image..." $pathtowim -ForegroundColor Green
    Write-Host "Please wait..." -ForegroundColor White
    Mount-WindowsImage -Path $pathworkfolder -ImagePath $pathtowim -Index $index | Out-Null
    }

catch [Exception] {
    Write-Host "Mounting Windows-Image failed..." -ForegroundColor Red;
    Write-Host "Error:" $_.Exception.Message -ForegroundColor Red; break
    }

try {
    Write-Host "Remove the following Built-in apps:" -ForegroundColor Green 
    $apps = Get-AppxProvisionedPackage -Path $pathworkfolder | ForEach-Object {

    if($selectapps -eq $true) {
    $call = read-host "Do you really want to delete the following App:" $_.DisplayName "(Y/N)"
    
    if($call -eq "y") {
    Write-Host "Delete:" $_.DisplayName -ForegroundColor Green
    Remove-AppxProvisionedPackage -Path $pathworkfolder -PackageName $_.PackageName
    $call = ""
    }

    else {
    Write-Host "Skipped:" $_.DisplayName -ForegroundColor yellow
    }
    }
    
    else {
    Write-Host "Delete:" $_.DisplayName -ForegroundColor Green
    Remove-AppxProvisionedPackage -Path $pathworkfolder -PackageName $_.PackageName 
    $call = ""
    }
    
    }
    }

catch [Exception] {
    Write-Host "Removing Built-in apps failed..." -ForegroundColor Red;
    Write-Host "Error:" $_.Exception.Message -ForegroundColor Red; break
    }

try {
    Write-Host "Dismount-WindowsImage..." -ForegroundColor Green
    Write-Host "Please wait..." -ForegroundColor White
    Dismount-WindowsImage -Path $pathworkfolder  -Save -CheckIntegrity | Out-Null
    Write-Host "Remove temporary directory..." -ForegroundColor Green
    Remove-Item $pathworkfolder -Recurse -Force | Out-Null
    Write-Host "Complete:" (Get-Date).ToString() -ForegroundColor White
    }

catch [Exception] {
    Write-Host "Error:" $_.Exception.Message -ForegroundColor Red; break
    }