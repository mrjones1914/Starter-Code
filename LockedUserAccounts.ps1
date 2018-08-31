# find disabled user accounts
# MRJ - Aug. 2015
<# Updates: 
    6.22.2016 - Added null variable check; message when there are no locked accounts
#>

Import-Module ActiveDirectory
Search-ADAccount -Locked | Select SamAccountName,LockedOut,LastLogonDate | export-csv -path M:\Engineering\Scripts\Powershell\locked.csv

# Build E-mail:

 $Server = "e-mail.redgold.com"
 $Port = "587"
 $To = "mjones@redgold.com"
 $From = "ActiveDirectory@redgold.com"
 $Subject = "Locked User Account Report"
 $Body = (Get-Content -Path M:\Engineering\Scripts\Powershell\locked.csv | Out-String)

 # check for null variable. If not null, send mail
    if (!$Body) {Write-Host "No locked accounts at this time."}
        else {
    Send-MailMessage -to $To -from $From -Subject $Subject -body $body -SmtpServer $Server -port $Port
}