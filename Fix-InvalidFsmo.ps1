<#
Disclaimer:
This sample script is not supported under any Microsoft standard support program or service. 
The sample script is provided AS IS without warranty of any kind. Microsoft further disclaims 
all implied warranties including, without limitation, any implied warranties of merchantability 
or of fitness for a particular purpose. The entire risk arising out of the use or performance of 
the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, 
or anyone else involved in the creation, production, or delivery of the scripts be liable for any 
damages whatsoever (including, without limitation, damages for loss of business profits, business 
interruption, loss of business information, or other pecuniary loss) arising out of the use of or 
inability to use the sample scripts or documentation, even if Microsoft has been advised of the 
possibility of such damages
#>
<#
.Synopsis
    This script changes an invalid fSMORoleOwner for application partitions
.DESCRIPTION
    This script changes an invalid fSMORoleOwner for an application partition specified in argument.
    This is the PowerShell equivalent of the VBScript provided in this article: http://support.microsoft.com/kb/949257
.EXAMPLE
    .\Fix-InvalidFsmo.ps1 -distinguishedName "DC=DomainDnsZones,DC=contoso,DC=com"
.INPUTS
    -distinguishedName [string]
        Specify the distinguishedName of the naminf context for which to fix the fSMORoleOwner attribute.
.OUTPUTS
    The output is only composed of Write-Host cmdLet. Therefore you cannot redirect into a file.
.NOTES
    Version Tracking
    8/26/2014 07:13AM - Version 1.0 - First public release
#>
Param(
    [Parameter(Mandatory=$true)]
    [String]$distinguishedName
)
#The script should work on PS2, therefore no way to force the input paramter to have another name
#Defined at $distinguishedName for a better visual
$_app_dn = $distinguishedName
#Check the culture, the script should be in French in a French environment
$_cur_culture = (Get-Host).CurrentUICulture.Name
If ( $_cur_culture -like "fr-*" )
{
    $_lang = "fr"
} Else {
    $_lang = "en"
}
#Prepare and adapt the message language
$_msg_string = @{
    "fr" = @{
        "notfound" = "N'EXISTE PAS"
        "current" = "Valeur actuelle de"
        "changed" = "Votre environnement a été mis à jour!"
        "notchanged" = "Votre environnement n'a pas été modifié."
        "changing" = "Remplacement par"
        "valid" = "VALIDE"
        "invalid" = "INVALIDE"
        "failed" = "ECHEC"
        "succeeded" = "REUSSI"
    }
    "en" = @{
        "notfound" = "NOT FOUND"
        "current" = "Current"
        "changed" = "Your environment has been updated!"
        "notchanged" = "Nothing has been changed in your environment."
        "changing" = "Chanching to"
        "valid" = "VALID"
        "invalid" = "INVALID"
        "failed" = "FAILED"
        "succeeded" = "SUCCEEDED"
    }
}
Write-Host "DN: $_app_dn " -NoNewline
#Search for an NC with this DN
$_forest_config = [string] ([ADSI]"LDAP://RootDSE").configurationNamingContext
$_list_nc = New-Object DirectoryServices.DirectorySearcher -Property @{
    Filter = "(nCName=$_app_dn)"
    SearchRoot = "LDAP://CN=Partitions,$_forest_config"
    SearchScope = "OneLevel"
}
$_sel_nc = $_list_nc.FindOne()
#Check if it is found
If ($_sel_nc -eq $null)
{
    Write-Host $_msg_string[$_lang].notfound -ForegroundColor Red
} Else {
    #If found, get the dnsRoot of it and store it for later
    $_sel_dns = $_sel_nc.Properties.dnsroot
    Write-Host $_msg_string[$_lang].valid -ForegroundColor Green
    Write-Host "`t- $($_msg_string[$_lang].current) dnsRoot: $_sel_dns"
    #Get the current fSMORoleOwner
    $_cur_nc =[ADSI]"LDAP://CN=Infrastructure,$_app_dn"
    $_cur_fSMORoleOwner = [string] ($_cur_nc).fSMORoleOwner
    Write-Host "`t- $($_msg_string[$_lang].current) fSMORoleOwner: $_cur_fSMORoleOwner " -NoNewline
    #Check the current fSMORoleOwner is valid
    If ( $_cur_fSMORoleOwner -notlike "*\0ADEL:*" )
    {
        #If valid we don't do anything
        Write-Host $_msg_string[$_lang].valid -ForegroundColor Green
        Write-Host $_msg_string[$_lang].notchanged
    } Else {
        #If not we change it
        Write-Host $_msg_string[$_lang].invalid -ForegroundColor Red
        #Get a DN of an online DC hosting the NC
        $_new_fSMORoleOwner = [string]([ADSI]"LDAP://$_sel_dns/RootDSE").dsServiceName
        Write-Host "`t- $($_msg_string[$_lang].changing) $_new_fSMORoleOwner " -NoNewline
        Try {
            #Try to change it
            $_cur_nc.Put("fSMORoleOwner",$_new_fSMORoleOwner)
            $_cur_nc.SetInfo()
        }
        Catch {
            #If we cannot we show the error
            Write-Host $_msg_string[$_lang].failed -ForegroundColor Red
            Write-Host $_msg_string[$_lang].notchanged
            Return
        }
        Write-Host $_msg_string[$_lang].succeeded -ForegroundColor Green
        Write-Host $_msg_string[$_lang].changed
            
    }
}
