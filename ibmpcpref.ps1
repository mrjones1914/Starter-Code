<#
Create default IBM iAccess for Windows profile path
MRJ 1.25.2017

Created to resolve the issue with the 
CWBCFG utility not setting the correct path
to session files (.WS) for all users

Used as a logon script for Citrix Golden Server Img

#>
$RegPath = "HKCU:\Software\IBM\Personal Communications\CurrentVersion\Preferences"
$ProfilePath = "H:\Personal settings(do not delete)\AS400"

# Check to see if Reg Path exists
$homedir = Get-ItemProperty -Path $RegPath -name "profile directory"
If ($homedir -ne $ProfilePath) {

New-Item -Path $RegPath -Force | Out-Null
    New-ItemProperty -Path $RegPath -name "Path Type" -PropertyType Dword -Value 3 | Out-Null
    New-ItemProperty -Path $RegPath -name "Profile Directory" -PropertyType string -Value $ProfilePath -Force | Out-Null
    New-ItemProperty -Path $RegPath -name "iNav Default Profile" -PropertyType string -Value ""  | Out-Null

} 
    else
    {
}

