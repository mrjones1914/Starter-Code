#COMMENT: Bulk add NTFS permission to a list of folders.
# Usage:  .\BulkSet-NTFSPermissions.ps1 -FolderListFile xxxxxx\xxxx.txt -SecIdentity "Domain\Group" -AccessRights "FullControl" -AccessControlType "Allow"
#===========================================================================================

param (
[string]$FolderListFile = $(throw "Please specify the folder list file using -FolderListFile switch."),
[string]$SecIdentity = $(throw "Please specify the security identity (user or group object) using -SecIdentity switch."),
[string]$AccessRights = $(throw "Please specify the Access Rights (i.e. FullControl, Read, ReadAndExecute, Modify, etc..) using -AccessRights switch."),
[string]$AccessControlType = $(throw "Please specify the Access Control Type (Allow or Deny) using -AccessControlType switch.")
)

#These constants are used to set permissions
$inherit = [system.security.accesscontrol.InheritanceFlags]"ContainerInherit, ObjectInherit"
$propagation = [system.security.accesscontrol.PropagationFlags]"None"
$ErrorActionPreference = "continue"
$iTotal = 0 #total number of folders processed


function Check-Access ($PSObjACL, $SecIdentity, $accessType) {
    $bHaveAccess = $false
    Foreach ($objACE in $PSObjACL.ACEs) {
        If ($objACE.IdentityReference.tostring() -ieq $SecIdentity -and $objACE.AccessControlType.tostring() -ieq $AccessControlType -and $objACE.FileSystemRights.tostring() -ieq $accessType) {
            $bHaveAccess = $true
        }
    }
    Return $bHaveAccess
}

$arrFolders = @()
$arrFolders += Get-Content $FolderListFile

#Set directory permissions
Foreach ($Folder in $arrFolders)
{
    Write-Host "Checking $Folder..."
    if (Test-Path $Folder)
    {
        $acl = Get-Acl $Folder -ErrorVariable ErrGetACL
        #Create a custom PSObject to only store the information required
        $strPath = $null
        $arrACEs = $null
        $PSObjACL = New-Object psobject
        $strPath = Convert-Path $acl.pspath
        $arrACEs = $acl | Select-Object -ExpandProperty Access
        $strACL = $arrACEs | Out-String

        Add-Member -InputObject $PSObjACL -MemberType NoteProperty -Name Path -Value $strPath
        Add-Member -InputObject $PSObjACL -MemberType NoteProperty -Name ACEs -Value $arrACEs
        #Add-Member -InputObject $PSObjACL -MemberType NoteProperty -Name strACL -Value $strACL
        #remove object generated from get-acl to save memory

        if (!(Check-Access $PSObjACL $SecIdentity $AccessRIghts))
        {
            Write-Host "Setting ACL for $folder..." -ForegroundColor Yellow
            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($SecIdentity, $AccessRights, $inherit, $propagation, $AccessControlType)
            $acl.AddAccessRule($accessRule)
            Set-Acl -aclobject $acl $Folder
            Remove-Variable acl
            Remove-Variable accessRule
        } else {
            Write-Host "$Folder access is OK. skipping..." -ForegroundColor Green
        }
    } else {
        Write-Host "$Folder does not exist!" -ForegroundColor Red
    }
    $iTotal ++
    Write-Host ""
}

Write-Host "$iTotal folders processed!" -ForegroundColor Green        